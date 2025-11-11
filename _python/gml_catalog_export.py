#!/usr/bin/env python3
"""
gml_catalog_export.py

Export a catalog of all GML functions into a folder hierarchy by category_path.
Each category path becomes a single JSON file containing only the functions in
that exact path (no roll-ups of subcategories).

Sources:
  1) GmlSpec.xml (authoritative function list + deprecated status)
  2) explicit_paths.json (function -> docs category path)
  3) Optional docs fetch (heuristic keyword scan) to auto-trigger flags and verify URLs

Per-function schema (keys appear in this exact order):
{
  "function_name": {
    "review_version": str or null,
    "category_path": str or null,
    "url": str or null,
    "peer_reviewed": bool or null,

    "is_deprecated": bool,
    "is_safe": bool or null,
    "is_sandboxed": bool or null,

    "is_file_io": bool or null,
    "is_network_io": bool or null,
    "is_personal_data": bool or null,
    "is_platform_specific": bool or null,

    "is_getter": bool or null,
    "is_setter": bool or null,
    "is_global_effect": bool or null,
    "is_asset_reflection": bool or null,
    "is_os_dialog": bool or null,
    "is_os_directive": bool or null
  }
}

Outputs:
  - Category JSON files under --out-root (default: ./catalog)
  - ./out/log/is_safe.txt
  - ./out/log/not_is_safe.txt
  - ./out/log/is_network_io.txt
  - ./out/log/not_is_network_io.txt

Usage:
  python gml_catalog_export.py /path/to/GmlSpec.xml /path/to/explicit_paths.json \
    --out-root ./catalog \
    --log-dir ./out/log \
    --review-version 2024.8 \
    --fetch-docs \
    --docs-base https://manual.gamemaker.io/monthly/en/ \
    --url-base https://manual.gamemaker.io/monthly/en/ \
    --http-timeout 8
"""

import argparse
import json
import os
import sys
import xml.etree.ElementTree as xml_et
from typing import Dict, List, Optional, Set, Tuple
from urllib.parse import quote

try:
    import requests  # optional, only used when --fetch-docs is provided
except Exception:
    requests = None


# ---------------------------
# Basic IO helpers
# ---------------------------

def read_json_map(path_string: str) -> Dict[str, str]:
    if not path_string or not os.path.isfile(path_string):
        return {}
    with open(path_string, "r", encoding="utf-8") as input_file:
        data_object = json.load(input_file)
        if isinstance(data_object, dict):
            cleaned_map: Dict[str, str] = {}
            for key_name, value_path in data_object.items():
                if key_name and value_path:
                    cleaned_map[str(key_name)] = str(value_path)
            return cleaned_map
    return {}

def write_json(obj_data: object, out_path: str) -> None:
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as output_file:
        json.dump(obj_data, output_file, indent=2, ensure_ascii=True)

def write_lines(lines: List[str], out_path: str) -> None:
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as output_file:
        for line in lines:
            output_file.write(line + "\n")

def normalize_lower(name_text: str) -> str:
    return (name_text or "").strip().lower()

def truthy(text_value: Optional[str]) -> bool:
    if text_value is None:
        return False
    lowered = text_value.strip().lower()
    return lowered in ("1", "true", "yes", "y")


# ---------------------------
# Load from XML
# ---------------------------

def load_xml_functions(xml_path: str) -> Tuple[List[xml_et.Element], Dict[str, xml_et.Element]]:
    if not os.path.isfile(xml_path):
        raise FileNotFoundError("XML file not found: %s" % xml_path)
    root_element = xml_et.parse(xml_path).getroot()
    functions_parent = root_element.find("Functions")
    if functions_parent is None:
        raise ValueError("No <Functions> element in XML.")
    elements_list = functions_parent.findall("Function")
    by_name_map: Dict[str, xml_et.Element] = {}
    for function_element in elements_list:
        function_name = (function_element.get("Name") or "").strip()
        if function_name:
            by_name_map[function_name] = function_element
    return elements_list, by_name_map

def extract_is_deprecated(function_element: xml_et.Element) -> bool:
    for key_name in ("Deprecated", "deprecated", "IsDeprecated", "is_deprecated"):
        if key_name in function_element.attrib and truthy(function_element.get(key_name)):
            return True
    deprecated_child = function_element.find("Deprecated")
    if deprecated_child is not None and truthy((deprecated_child.text or "")):
        return True
    return False


# ---------------------------
# Category path resolver (robust lookups)
# ---------------------------

ALIAS_PAIRS_FOR_NAMES: List[Tuple[str, str]] = [
    ("colour", "color"),
    ("normalised", "normalized"),
    ("randomise", "randomize"),
    ("grey", "gray"),
    ("textcoord", "texcoord"),
]

def build_explicit_maps(explicit_map_raw: Dict[str, str]) -> Tuple[Dict[str, str], Dict[str, str]]:
    exact_map = dict(explicit_map_raw)
    lower_map: Dict[str, str] = {}
    for key_name, value_path in explicit_map_raw.items():
        lower_key = key_name.lower()
        if lower_key not in lower_map:
            lower_map[lower_key] = value_path
    return exact_map, lower_map

def generate_alias_variants(base_name: str) -> List[str]:
    variants: Set[str] = set()
    base_low = base_name.lower()
    variants.add(base_low)
    variants.add(base_low.replace("_", "-"))
    variants.add(base_low.replace("-", "_"))
    changed_flag = True
    while changed_flag:
        changed_flag = False
        next_set: Set[str] = set(variants)
        for left_text, right_text in ALIAS_PAIRS_FOR_NAMES:
            for value_text in variants:
                if left_text in value_text:
                    flipped = value_text.replace(left_text, right_text)
                    if flipped not in next_set:
                        next_set.add(flipped)
                        changed_flag = True
                if right_text in value_text:
                    flipped = value_text.replace(right_text, left_text)
                    if flipped not in next_set:
                        next_set.add(flipped)
                        changed_flag = True
        variants = next_set
    return sorted(list(variants), key=lambda s: (len(s), s))

def resolve_category_path(function_name: str,
                          explicit_exact: Dict[str, str],
                          explicit_lower: Dict[str, str]) -> Optional[str]:
    if function_name in explicit_exact:
        return explicit_exact[function_name]
    lower_key = function_name.lower()
    if lower_key in explicit_exact:
        return explicit_exact[lower_key]
    if lower_key in explicit_lower:
        return explicit_lower[lower_key]
    best_path: Optional[str] = None
    best_depth = -1
    for candidate in generate_alias_variants(function_name):
        if candidate in explicit_exact:
            path_value = explicit_exact[candidate]
        elif candidate in explicit_lower:
            path_value = explicit_lower[candidate]
        else:
            continue
        depth_value = path_value.count("/")
        if depth_value > best_depth:
            best_depth = depth_value
            best_path = path_value
    return best_path


# ---------------------------
# Heuristic flaggers (name based)
# Only set flags when confidence is high; else leave as None
# ---------------------------

NAME_TOKENS_FILE: List[str] = [
    "file_", "ini_", "_file", "zip_", "surface_save", "sprite_save", "load", "save",
]
NAME_TOKENS_NETWORK: List[str] = [
    "http_", "url_", "network_", "socket", "analytics", "push_", "ftp", "smtp", "web_",
    "steam_", "gxc", "matchmaking",
]
NAME_TOKENS_PERSONAL: List[str] = [
    "os_get", "os_", "environment_get_variable", "clipboard_", "browser_",
]
NAME_TOKENS_PLATFORM: List[str] = [
    "xbox", "psn", "switch", "uwp", "win8", "winphone", "ps4", "ps5", "steam_", "gxc", "html5", "browser_",
]
NAME_TOKENS_OS_DIRECTIVE: List[str] = [
    "window_", "display_", "gpu_set_", "draw_set_", "mouse_set", "keyboard_set_",
]
NAME_TOKENS_GLOBAL_EFFECT: List[str] = [
    "gpu_set_", "audio_group_", "texture_global_", "texturegroup_", "physics_world_", "room_", "layer_", "timeline_",
    "random_set_seed", "sequence_", "window_", "display_", "steam_", "achievement_", "os_",
]
ASSET_REFLECTION_TOKENS: List[str] = [
    "asset_", "get_index", "get_name", "get_ids", "find_asset", "script_get_name", "sprite_exists",
]
GETTER_PREFIXES: List[str] = [
    "get_", "is_", "has_", "exists", "count", "length", "find", "check_",
]
SETTER_PREFIXES: List[str] = [
    "set_", "add", "remove", "delete", "clear", "create", "destroy", "assign", "enable", "disable", "replace",
]

def has_any_token(name_lower: str, tokens: List[str]) -> bool:
    for token in tokens:
        if token in name_lower:
            return True
    return False

def infer_is_getter(name_lower: str) -> Optional[bool]:
    for prefix in GETTER_PREFIXES:
        if name_lower.startswith(prefix):
            return True
    if name_lower.startswith("string_") or name_lower.startswith("md5_") or name_lower.startswith("sha1_"):
        return True
    return None

def infer_is_setter(name_lower: str) -> Optional[bool]:
    for prefix in SETTER_PREFIXES:
        if name_lower.startswith(prefix):
            return True
    if name_lower.startswith("draw_set_") or name_lower.startswith("gpu_set_"):
        return True
    return None

def infer_is_global_effect(name_lower: str) -> Optional[bool]:
    if has_any_token(name_lower, NAME_TOKENS_GLOBAL_EFFECT):
        return True
    return None

def infer_is_asset_reflection(name_lower: str) -> Optional[bool]:
    if has_any_token(name_lower, ASSET_REFLECTION_TOKENS):
        return True
    return None

def infer_is_os_dialog(name_lower: str) -> Optional[bool]:
    if name_lower in ("show_message", "show_question"):
        return True
    if "get_open_filename" in name_lower or "get_save_filename" in name_lower or "get_directory" in name_lower:
        return True
    return None

def infer_is_file_io(name_lower: str) -> Optional[bool]:
    if has_any_token(name_lower, NAME_TOKENS_FILE):
        return True
    return None

def infer_is_network_io(name_lower: str) -> Optional[bool]:
    if has_any_token(name_lower, NAME_TOKENS_NETWORK):
        return True
    return None

def infer_is_personal_data(name_lower: str) -> Optional[bool]:
    if has_any_token(name_lower, NAME_TOKENS_PERSONAL):
        return True
    return None

def infer_is_platform_specific(name_lower: str) -> Optional[bool]:
    if has_any_token(name_lower, NAME_TOKENS_PLATFORM):
        return True
    return None

def infer_is_os_directive(name_lower: str) -> Optional[bool]:
    if has_any_token(name_lower, NAME_TOKENS_OS_DIRECTIVE):
        return True
    return None

def derive_is_sandboxed(is_asset_reflection: Optional[bool],
                        is_global_effect: Optional[bool]) -> Optional[bool]:
    if is_asset_reflection is True:
        return False
    if is_global_effect is True:
        return False
    return None

def derive_is_safe(is_file_io: Optional[bool],
                   is_network_io: Optional[bool],
                   is_personal_data: Optional[bool],
                   is_os_dialog: Optional[bool]) -> Optional[bool]:
    if is_file_io is True or is_network_io is True or is_personal_data is True or is_os_dialog is True:
        return False
    return None


# ---------------------------
# Optional docs fetch (keyword sniffing)
# ---------------------------

KEYWORDS_FILE: List[str] = ["file", "save", "load", "folder", "directory", "path", "disk"]
KEYWORDS_NETWORK: List[str] = ["http", "url", "network", "socket", "online", "cloud", "web"]
KEYWORDS_PERSONAL: List[str] = ["clipboard", "environment variable", "username", "system", "os"]
KEYWORDS_OS_DIRECTIVE: List[str] = ["window", "gpu state", "display", "mouse cursor", "system dialog"]
KEYWORDS_ASSET_REFLECTION: List[str] = ["asset", "by name", "by id", "resource tree", "index", "ids"]

def docs_url_candidates(docs_base: str, category_path: str, function_name: str) -> List[str]:
    if not category_path:
        return []
    base_prefix = docs_base.rstrip("/") + "/GameMaker_Language/GML_Reference/"
    segments = [seg.strip().replace(" ", "_") for seg in category_path.split("/") if seg.strip()]
    dir_path = base_prefix + "/".join(segments) + "/"

    candidates: List[str] = []

    def add_candidate(stem_value: str) -> None:
        candidates.append(dir_path + stem_value + ".htm")

    name_lower = function_name.strip()
    add_candidate(name_lower)
    if "color" in name_lower:
        add_candidate(name_lower.replace("color", "colour"))
    if "colour" in name_lower:
        add_candidate(name_lower.replace("colour", "color"))
    if "textcoord" in name_lower:
        add_candidate(name_lower.replace("textcoord", "texcoord"))
    if "texcoord" in name_lower:
        add_candidate(name_lower.replace("texcoord", "textcoord"))
    if "_" in name_lower:
        add_candidate(name_lower.replace("_", "-"))
    if "-" in name_lower:
        add_candidate(name_lower.replace("-", "_"))

    unique_list: List[str] = []
    for url_value in candidates:
        if url_value not in unique_list:
            unique_list.append(url_value)
    return unique_list

def fetch_page_text(page_url: str, http_timeout: int) -> Optional[str]:
    if requests is None:
        return None
    try:
        response = requests.get(page_url, timeout=http_timeout)
        if response.status_code == 200 and response.text:
            return response.text
    except Exception:
        return None
    return None

def sniff_keywords_from_docs(docs_text: str) -> Dict[str, bool]:
    text_lower = docs_text.lower()
    inferred_flags: Dict[str, bool] = {}
    if any(word in text_lower for word in KEYWORDS_FILE):
        inferred_flags["is_file_io"] = True
    if any(word in text_lower for word in KEYWORDS_NETWORK):
        inferred_flags["is_network_io"] = True
    if any(word in text_lower for word in KEYWORDS_PERSONAL):
        inferred_flags["is_personal_data"] = True
    if any(word in text_lower for word in KEYWORDS_OS_DIRECTIVE):
        inferred_flags["is_os_directive"] = True
    if any(word in text_lower for word in KEYWORDS_ASSET_REFLECTION):
        inferred_flags["is_asset_reflection"] = True
    if "returns" in text_lower and "set" not in text_lower:
        inferred_flags["is_getter"] = True
    if "sets" in text_lower or "change" in text_lower:
        inferred_flags["is_setter"] = True
    return inferred_flags


# ---------------------------
# URL builder (anchor fallback)
# ---------------------------

def build_anchor_url(url_base: str, category_path: Optional[str], function_name: str) -> Optional[str]:
    if not category_path:
        return None
    segments = [seg.strip().replace(" ", "_") for seg in category_path.split("/") if seg.strip()]
    anchor_path = "GameMaker_Language/GML_Reference/" + "/".join(segments) + "/" + function_name + ".htm"
    anchor_encoded = quote(anchor_path, safe="")
    return url_base.rstrip("/") + "/#t=" + anchor_encoded


# ---------------------------
# File path helpers
# ---------------------------

def category_file_path(out_root: str, category_path: Optional[str]) -> str:
    if not category_path:
        return os.path.join(out_root, "_Uncategorized.json")
    segments = [seg for seg in category_path.split("/") if seg]
    if not segments:
        return os.path.join(out_root, "_Uncategorized.json")
    dir_parts = segments[:-1]
    file_name = segments[-1] + ".json"
    dir_path = os.path.join(out_root, *dir_parts) if dir_parts else out_root
    return os.path.join(dir_path, file_name)


# ---------------------------
# Build catalog grouped by category path
# ---------------------------

def build_catalog(xml_path: str,
                  explicit_paths_path: str,
                  out_root: str,
                  log_dir: str,
                  review_version: Optional[str],
                  fetch_docs: bool,
                  docs_base: str,
                  url_base: str,
                  http_timeout: int) -> None:
    elements_list, by_name_map = load_xml_functions(xml_path)
    explicit_raw = read_json_map(explicit_paths_path)
    explicit_exact, explicit_lower = build_explicit_maps(explicit_raw)

    all_names: List[str] = []
    for function_element in elements_list:
        function_name = (function_element.get("Name") or "").strip()
        if function_name:
            all_names.append(function_name)

    # Accumulators
    per_file_functions: Dict[str, Dict[str, dict]] = {}
    log_is_safe_yes: List[str] = []
    log_is_safe_no: List[str] = []
    log_is_network_yes: List[str] = []
    log_is_network_no: List[str] = []

    count_verified_urls = 0

    for function_name in all_names:
        element = by_name_map[function_name]
        name_lower = function_name.lower()

        is_deprecated_flag = extract_is_deprecated(element)
        category_path_value = resolve_category_path(function_name, explicit_exact, explicit_lower)

        verified_url: Optional[str] = None
        inferred_apply_map: Dict[str, bool] = {}
        if fetch_docs and category_path_value:
            for candidate_url in docs_url_candidates(docs_base, category_path_value, function_name):
                page_text = fetch_page_text(candidate_url, http_timeout)
                if page_text:
                    verified_url = candidate_url
                    inferred_apply_map = sniff_keywords_from_docs(page_text)
                    count_verified_urls += 1
                    break

        # Construct record in the requested key order
        record: Dict[str, object] = {
            "review_version": str(review_version) if review_version else None,
            "category_path": category_path_value if category_path_value else None,
            "url": verified_url if verified_url else build_anchor_url(url_base, category_path_value, function_name),
            "peer_reviewed": None,

            "is_deprecated": bool(is_deprecated_flag),
            "is_safe": None,
            "is_sandboxed": None,

            "is_file_io": None,
            "is_network_io": None,
            "is_personal_data": None,
            "is_platform_specific": None,

            "is_getter": None,
            "is_setter": None,
            "is_global_effect": None,
            "is_asset_reflection": None,
            "is_os_dialog": None,
            "is_os_directive": None
        }

        # Name-based confident hints
        hint_file = infer_is_file_io(name_lower)
        hint_net = infer_is_network_io(name_lower)
        hint_personal = infer_is_personal_data(name_lower)
        hint_platform = infer_is_platform_specific(name_lower)
        hint_os_directive = infer_is_os_directive(name_lower)
        hint_getter = infer_is_getter(name_lower)
        hint_setter = infer_is_setter(name_lower)
        hint_global = infer_is_global_effect(name_lower)
        hint_asset = infer_is_asset_reflection(name_lower)
        hint_os_dialog = infer_is_os_dialog(name_lower)

        if hint_file is True:
            record["is_file_io"] = True
        if hint_net is True:
            record["is_network_io"] = True
        if hint_personal is True:
            record["is_personal_data"] = True
        if hint_platform is True:
            record["is_platform_specific"] = True
        if hint_os_directive is True:
            record["is_os_directive"] = True
        if hint_getter is True:
            record["is_getter"] = True
        if hint_setter is True:
            record["is_setter"] = True
        if hint_global is True:
            record["is_global_effect"] = True
        if hint_asset is True:
            record["is_asset_reflection"] = True
        if hint_os_dialog is True:
            record["is_os_dialog"] = True

        # Apply any docs-inferred flags (only None -> True)
        if inferred_apply_map:
            for key_name, flag_value in inferred_apply_map.items():
                if key_name in record and record[key_name] is None and flag_value is True:
                    record[key_name] = True

        # Derived gates
        derived_sandboxed = derive_is_sandboxed(record["is_asset_reflection"], record["is_global_effect"])
        if derived_sandboxed is not None:
            record["is_sandboxed"] = derived_sandboxed

        derived_safe = derive_is_safe(record["is_file_io"],
                                      record["is_network_io"],
                                      record["is_personal_data"],
                                      record["is_os_dialog"])
        if derived_safe is not None:
            record["is_safe"] = derived_safe

        # Logging for quick lists
        if record["is_safe"] is True:
            log_is_safe_yes.append('"%s"' % function_name)
        elif record["is_safe"] is False:
            log_is_safe_no.append('"%s"' % function_name)

        if record["is_network_io"] is True:
            log_is_network_yes.append('"%s"' % function_name)
        elif record["is_network_io"] is False:
            log_is_network_no.append('"%s"' % function_name)

        # Place into category file content
        out_path = category_file_path(out_root, category_path_value)
        bucket = per_file_functions.setdefault(out_path, {})
        bucket[function_name] = record

    # Write category files (functions sorted by name for stable diffs)
    total_files_written = 0
    total_functions_written = 0
    for file_path, func_map in sorted(per_file_functions.items(), key=lambda kv: kv[0].lower()):
        os.makedirs(os.path.dirname(file_path) or ".", exist_ok=True)
        ordered_funcs = dict(sorted(func_map.items(), key=lambda kv: kv[0].lower()))
        write_json(ordered_funcs, file_path)
        total_files_written += 1
        total_functions_written += len(ordered_funcs)

    # Write logs
    os.makedirs(log_dir, exist_ok=True)
    write_lines(log_is_safe_yes, os.path.join(log_dir, "is_safe.txt"))
    write_lines(log_is_safe_no, os.path.join(log_dir, "not_is_safe.txt"))
    write_lines(log_is_network_yes, os.path.join(log_dir, "is_network_io.txt"))
    write_lines(log_is_network_no, os.path.join(log_dir, "not_is_network_io.txt"))

    # Summary
    print("Export complete:")
    print("  Functions processed:", len(all_names))
    print("  Category files written:", total_files_written)
    print("  Total functions written:", total_functions_written)
    print("  Verified doc URLs:", count_verified_urls)
    print("  Catalog root:", out_root)
    print("  Logs:", log_dir)


# ---------------------------
# Entry point
# ---------------------------

def main(argv_list: List[str]) -> int:
    parser_object = argparse.ArgumentParser(description="Export GML catalog grouped by category_path.")
    parser_object.add_argument("xmlfile", help="Path to GmlSpec.xml")
    parser_object.add_argument("explicit_paths", help="Path to explicit_paths.json")
    parser_object.add_argument("--out-root", default="./catalog", help="Output root directory for category JSON files")
    parser_object.add_argument("--log-dir", default="./out/log", help="Output directory for log text files")
    parser_object.add_argument("--review-version", default=None, help="Version tag to stamp into entries (e.g., 2024.8)")
    parser_object.add_argument("--fetch-docs", action="store_true", help="Fetch manual pages to sniff keywords and verify URLs")
    parser_object.add_argument("--docs-base", default="https://manual.gamemaker.io/monthly/en/",
                               help="Docs base URL used for fetching (must end with a slash)")
    parser_object.add_argument("--url-base", default="https://manual.gamemaker.io/monthly/en/",
                               help="Base URL used to construct anchor URLs saved in the JSON (must end with a slash)")
    parser_object.add_argument("--http-timeout", type=int, default=6, help="HTTP timeout seconds for docs fetch")
    args = parser_object.parse_args(argv_list)

    build_catalog(
        xml_path=args.xmlfile,
        explicit_paths_path=args.explicit_paths,
        out_root=args.out_root,
        log_dir=args.log_dir,
        review_version=args.review_version,
        fetch_docs=bool(args.fetch_docs),
        docs_base=args.docs_base,
        url_base=args.url_base,
        http_timeout=int(args.http_timeout),
    )
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

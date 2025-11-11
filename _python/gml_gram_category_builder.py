#!/usr/bin/env python3
# gml_gram_category_builder.py
# Build category rules for GML using token n-grams and the XML spec.
# Outputs a rules JSON with:
#   - "prefixes": { "ds_": "Data Structures", ... }
#   - "sub_prefixes": { "ds_grid_": {"category":"Data Structures","subcategory":"DS Grid"}, ... }
#   - optional "explicit_names": { "ds_grid_create": {"category":"Data Structures","subcategory":"DS Grid"}, ... }
#
# Extras:
#   - Reads gram logs (1/2/3-grams) to promote strong prefixes and sub-prefixes.
#   - Auto-tunes thresholds until a target coverage is reached.
#   - Writes a log of all function names NOT covered by rules (no prefix or sub_prefix match):
#       --out-uncovered ./out/grams/uncovered_functions.txt
#     These are the ones you may want to hand-assign.
#
# Usage examples:
#   python gml_gram_category_builder.py GmlSpec.xml --out-rules ./category_rules.json --grams-dir ./out/grams --use-grams
#   python gml_gram_category_builder.py GmlSpec.xml --out-rules ./category_rules.json --grams-dir ./out/grams --use-grams --emit-explicit --target-coverage 0.90

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as xml_et
from collections import Counter
from typing import Dict, List, Tuple, Set


KNOWN_CATEGORIES = [
    "Variable Functions",
    "Array Functions",
    "Asset Management",
    "General Game Control",
    "Movement And Collisions",
    "Drawing",
    "Cameras And Display",
    "Game Input",
    "Data Structures",
    "Strings",
    "Maths And Numbers",
    "Flex Panels",
    "Time Sources",
    "Physics",
    "In-App Purchases",
    "Asynchronous Functions",
    "Networking",
    "Web And HTML5",
    "File Handling",
    "Buffers",
    "Xbox Live",
    "GX.games Functions",
    "OS And Compiler",
    "Debugging",
    "Garbage Collection",
    "Steam",
    "Live Wallpapers"
]

PRIMARY_PREFIX_TO_CATEGORY = {
    "variable": "Variable Functions",
    "array": "Array Functions",
    "asset": "Asset Management",
    "tag": "Asset Management",
    "texturegroup": "Asset Management",
    "sprite": "Asset Management",
    "font": "Asset Management",
    "tileset": "Asset Management",
    "tilemap": "Asset Management",
    "sequence": "Asset Management",
    "timeline": "Asset Management",
    "move": "Movement And Collisions",
    "motion": "Movement And Collisions",
    "collision": "Movement And Collisions",
    "place": "Movement And Collisions",
    "path": "Movement And Collisions",
    "mp": "Movement And Collisions",
    "draw": "Drawing",
    "shader": "Drawing",
    "gpu": "Drawing",
    "matrix": "Drawing",
    "surface": "Drawing",
    "camera": "Cameras And Display",
    "view": "Cameras And Display",
    "display": "Cameras And Display",
    "keyboard": "Game Input",
    "mouse": "Game Input",
    "device": "Game Input",
    "gamepad": "Game Input",
    "ds": "Data Structures",
    "struct": "Data Structures",
    "string": "Strings",
    "time": "Time Sources",
    "time_source": "Time Sources",
    "physics": "Physics",
    "http": "Networking",
    "url": "Networking",
    "network": "Networking",
    "socket": "Networking",
    "browser": "Web And HTML5",
    "file": "File Handling",
    "ini": "File Handling",
    "zip": "File Handling",
    "xbox": "Xbox Live",
    "gxc": "GX.games Functions",
    "gx": "GX.games Functions",
    "steam": "Steam",
    "os": "OS And Compiler",
    "dbg": "Debugging",
    "gc": "Garbage Collection",
    "wallpaper": "Live Wallpapers",
    "ms": "In-App Purchases",
    "iap": "In-App Purchases"
}


def read_xml_root(xml_path: str) -> xml_et.Element:
    if not os.path.isfile(xml_path):
        raise FileNotFoundError("XML file not found: %s" % xml_path)
    tree_object = xml_et.parse(xml_path)
    return tree_object.getroot()


def get_all_function_names(root_element: xml_et.Element) -> List[str]:
    functions_parent = root_element.find("Functions")
    if functions_parent is None:
        raise ValueError("No <Functions> element found in XML.")
    names_list: List[str] = []
    for function_element in functions_parent.findall("Function"):
        function_name = (function_element.get("Name") or "").strip()
        if function_name:
            names_list.append(function_name)
    return names_list


def to_title(text_value: str) -> str:
    parts_list = [p for p in text_value.split("_") if p]
    titled_list = [p.capitalize() for p in parts_list]
    return " ".join(titled_list)


def categorize_fallback(function_name: str) -> Tuple[str, str]:
    name_lower = function_name.lower()
    if name_lower.startswith("variable_") or function_name in ("method", "nameof", "typeof"):
        return "Variable Functions", ""
    if name_lower.startswith("array_"):
        return "Array Functions", ""
    if name_lower.startswith("time_source_"):
        return "Time Sources", ""
    if name_lower.startswith("physics_"):
        return "Physics", ""
    if name_lower.startswith("buffer_"):
        return "Buffers", ""
    if name_lower.startswith("ds_") or name_lower.startswith("struct_"):
        return "Data Structures", ""
    if name_lower.startswith("string_") or function_name in ("chr", "ord", "ansi_char", "real", "string"):
        return "Strings", ""
    if name_lower.startswith("draw_") or name_lower.startswith("shader_") or name_lower.startswith("gpu_") or name_lower.startswith("matrix_") or name_lower.startswith("surface_"):
        return "Drawing", ""
    if name_lower.startswith("camera_") or name_lower.startswith("view_") or name_lower.startswith("display_"):
        return "Cameras And Display", ""
    if name_lower.startswith("keyboard_") or name_lower.startswith("mouse_") or name_lower.startswith("device_") or name_lower.startswith("gamepad_"):
        return "Game Input", ""
    if name_lower.startswith("asset_") or name_lower.startswith("tag_") or name_lower.startswith("texturegroup_") or name_lower.startswith("sprite_") or name_lower.startswith("font_") or name_lower.startswith("tileset_") or name_lower.startswith("tilemap_") or name_lower.startswith("sequence_") or name_lower.startswith("timeline_"):
        return "Asset Management", ""
    if "async" in name_lower or name_lower.endswith("_async"):
        return "Asynchronous Functions", ""
    if name_lower.startswith("http_") or name_lower.startswith("url_") or name_lower.startswith("network_") or "socket" in name_lower:
        return "Networking", ""
    if name_lower.startswith("browser_"):
        return "Web And HTML5", ""
    if name_lower.startswith("file_") or name_lower.startswith("ini_") or name_lower.startswith("zip_") or "get_open_filename" in name_lower or "get_save_filename" in name_lower:
        return "File Handling", ""
    if "xbox" in name_lower:
        return "Xbox Live", ""
    if name_lower.startswith("gxc_") or name_lower.startswith("gx"):
        return "GX.games Functions", ""
    if name_lower.startswith("steam_"):
        return "Steam", ""
    if name_lower.startswith("os_") or "environment_get_variable" in name_lower:
        return "OS And Compiler", ""
    if name_lower.startswith("dbg_") or name_lower.startswith("show_debug"):
        return "Debugging", ""
    if name_lower.startswith("gc_"):
        return "Garbage Collection", ""
    if name_lower.startswith("wallpaper_"):
        return "Live Wallpapers", ""
    if (name_lower.startswith("move_") or name_lower.startswith("motion_") or name_lower.startswith("collision_") or
        name_lower.startswith("place_") or name_lower.startswith("path_") or name_lower.startswith("mp_")):
        return "Movement And Collisions", ""
    if name_lower.startswith("ms_iap") or name_lower.startswith("iap_"):
        return "In-App Purchases", ""
    return "General Game Control", ""


def parse_gram_file(path_value: str) -> List[Tuple[str, int]]:
    pairs_list: List[Tuple[str, int]] = []
    if not path_value or not os.path.isfile(path_value):
        return pairs_list
    with open(path_value, "r", encoding="utf-8") as file_object:
        for raw_line in file_object:
            line_value = raw_line.strip()
            if not line_value:
                continue
            try:
                left_part, count_part = line_value.split("||")
                token_text = left_part.strip().strip('"')
                count_value = int(count_part.strip())
                pairs_list.append((token_text, count_value))
            except Exception:
                continue
    return pairs_list


def load_grams(grams_dir: str) -> Tuple[List[Tuple[str, int]], List[Tuple[str, int]], List[Tuple[str, int]]]:
    one_list = parse_gram_file(os.path.join(grams_dir, "tokens_1gram.txt"))
    two_list = parse_gram_file(os.path.join(grams_dir, "tokens_2gram.txt"))
    three_list = parse_gram_file(os.path.join(grams_dir, "tokens_3gram.txt"))
    return one_list, two_list, three_list


def suggest_category_for_primary(primary_token: str) -> str:
    return PRIMARY_PREFIX_TO_CATEGORY.get(primary_token, "")


def to_title_from_key(token_key: str) -> str:
    parts_list = [p for p in token_key.split("_") if p]
    titled_list = [p.capitalize() for p in parts_list]
    return " ".join(titled_list)


def suggest_subcategory_for_pair(pair_key: str, category_name: str) -> str:
    if not pair_key:
        return ""
    if category_name == "Data Structures":
        second_token = pair_key.split("_", 1)[1] if "_" in pair_key else ""
        if second_token:
            return "DS " + second_token.capitalize()
    return to_title_from_key(pair_key)


def build_base_rules(function_names: List[str],
                     min_single: int,
                     min_pair: int,
                     stopword_set: Set[str]) -> Tuple[Dict[str, str], Dict[str, Dict[str, str]]]:
    single_counter: Counter = Counter()
    pair_counter: Counter = Counter()
    for name_value in function_names:
        tokens_list = [t for t in name_value.lower().split("_") if t]
        if not tokens_list:
            continue
        first_token = tokens_list[0]
        if first_token not in stopword_set:
            single_counter[first_token] += 1
        if len(tokens_list) >= 2:
            pair_key = tokens_list[0] + "_" + tokens_list[1]
            if tokens_list[0] not in stopword_set and tokens_list[1] not in stopword_set:
                pair_counter[pair_key] += 1

    prefixes_map: Dict[str, str] = {}
    sub_prefixes_map: Dict[str, Dict[str, str]] = {}

    for token_text, count_value in single_counter.most_common():
        if count_value < min_single:
            continue
        category_name_value = suggest_category_for_primary(token_text)
        if category_name_value:
            prefixes_map[token_text + "_"] = category_name_value

    for pair_key, count_value in pair_counter.most_common():
        if count_value < min_pair:
            continue
        primary_token = pair_key.split("_", 1)[0]
        category_name_value = suggest_category_for_primary(primary_token)
        if not category_name_value:
            continue
        subcategory_name_value = suggest_subcategory_for_pair(pair_key, category_name_value)
        sub_prefixes_map[pair_key + "_"] = {"category": category_name_value, "subcategory": subcategory_name_value}

    return prefixes_map, sub_prefixes_map


def apply_grams_to_rules(two_grams: List[Tuple[str, int]],
                         three_grams: List[Tuple[str, int]],
                         function_names: List[str],
                         prefixes_map: Dict[str, str],
                         sub_prefixes_map: Dict[str, Dict[str, str]],
                         min_pair: int,
                         min_triple: int) -> None:
    for pair_key, count_value in two_grams:
        if count_value < min_pair:
            continue
        if "_" not in pair_key:
            continue
        primary_token = pair_key.split("_", 1)[0]
        category_name_value = suggest_category_for_primary(primary_token)
        if not category_name_value:
            continue
        if pair_key + "_" not in sub_prefixes_map:
            subcategory_name_value = suggest_subcategory_for_pair(pair_key, category_name_value)
            sub_prefixes_map[pair_key + "_" ] = {"category": category_name_value, "subcategory": subcategory_name_value}

    for triple_key, count_value in three_grams:
        if count_value < min_triple:
            continue
        if "_" not in triple_key:
            continue
        primary_token = triple_key.split("_", 1)[0]
        category_name_value = suggest_category_for_primary(primary_token)
        if not category_name_value:
            continue
        first_two = "_".join(triple_key.split("_")[:2])
        if first_two + "_" not in sub_prefixes_map:
            subcategory_name_value = suggest_subcategory_for_pair(first_two, category_name_value)
            sub_prefixes_map[first_two + "_"] = {"category": category_name_value, "subcategory": subcategory_name_value}


def compute_coverage(function_names: List[str],
                     prefixes_map: Dict[str, str],
                     sub_prefixes_map: Dict[str, Dict[str, str]]) -> float:
    covered_count = 0
    for name_value in function_names:
        name_lower = name_value.lower()
        matched_flag = False
        for subprefix_key in sorted(sub_prefixes_map.keys(), key=lambda s: len(s), reverse=True):
            if name_lower.startswith(subprefix_key):
                matched_flag = True
                break
        if not matched_flag:
            for prefix_key in prefixes_map.keys():
                if name_lower.startswith(prefix_key):
                    matched_flag = True
                    break
        if matched_flag:
            covered_count += 1
    if not function_names:
        return 0.0
    return covered_count / float(len(function_names))


def compute_uncovered(function_names: List[str],
                      prefixes_map: Dict[str, str],
                      sub_prefixes_map: Dict[str, Dict[str, str]]) -> List[str]:
    uncovered_list: List[str] = []
    for name_value in function_names:
        name_lower = name_value.lower()
        matched_flag = False
        for subprefix_key in sorted(sub_prefixes_map.keys(), key=lambda s: len(s), reverse=True):
            if name_lower.startswith(subprefix_key):
                matched_flag = True
                break
        if not matched_flag:
            for prefix_key in prefixes_map.keys():
                if name_lower.startswith(prefix_key):
                    matched_flag = True
                    break
        if not matched_flag:
            uncovered_list.append(name_value)
    uncovered_list.sort(key=lambda s: s.lower())
    return uncovered_list


def emit_explicit_map(function_names: List[str],
                      prefixes_map: Dict[str, str],
                      sub_prefixes_map: Dict[str, Dict[str, str]]) -> Dict[str, Dict[str, str]]:
    explicit_map: Dict[str, Dict[str, str]] = {}
    for name_value in function_names:
        name_lower = name_value.lower()
        category_name_value = ""
        subcategory_name_value = ""
        for subprefix_key in sorted(sub_prefixes_map.keys(), key=lambda s: len(s), reverse=True):
            if name_lower.startswith(subprefix_key):
                entry_value = sub_prefixes_map[subprefix_key]
                category_name_value = entry_value.get("category") or ""
                subcategory_name_value = entry_value.get("subcategory") or ""
                break
        if not category_name_value:
            for prefix_key, category_value in prefixes_map.items():
                if name_lower.startswith(prefix_key):
                    category_name_value = category_value
                    break
        if not category_name_value:
            category_name_value, subcategory_name_value = categorize_fallback(name_value)
        if subcategory_name_value:
            explicit_map[name_value] = {"category": category_name_value, "subcategory": subcategory_name_value}
        else:
            explicit_map[name_value] = {"category": category_name_value}
    return explicit_map


def write_rules_json(rules_data: Dict, out_path: str) -> None:
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as output_file:
        json.dump(rules_data, output_file, indent=2, ensure_ascii=True)


def write_uncovered_log(uncovered_list: List[str], out_path: str) -> None:
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as output_file:
        for name_value in uncovered_list:
            output_file.write("\"%s\"\n" % name_value)


def main(argv_list: List[str]) -> int:
    parser_object = argparse.ArgumentParser(description="Build category rules JSON from GmlSpec.xml using token n-grams.")
    parser_object.add_argument("xmlfile", help="Path to GmlSpec.xml")
    parser_object.add_argument("--out-rules", dest="out_rules", default="category_rules.json", help="Output rules JSON path")
    parser_object.add_argument("--grams-dir", dest="grams_dir", default="./out/grams", help="Directory containing tokens_1gram.txt, tokens_2gram.txt, tokens_3gram.txt")
    parser_object.add_argument("--use-grams", dest="use_grams", action="store_true", help="Use gram files to promote sub-prefixes")
    parser_object.add_argument("--emit-explicit", dest="emit_explicit", action="store_true", help="Also emit an exhaustive explicit_names mapping")
    parser_object.add_argument("--target-coverage", dest="target_coverage", type=float, default=0.90, help="Desired rule coverage of functions (0.0 to 1.0)")
    parser_object.add_argument("--min-single", dest="min_single", type=int, default=10, help="Minimum count for single-token prefixes")
    parser_object.add_argument("--min-pair", dest="min_pair", type=int, default=10, help="Minimum count for two-token sub-prefixes")
    parser_object.add_argument("--min-triple", dest="min_triple", type=int, default=8, help="Minimum count for three-token guidance")
    parser_object.add_argument("--stopwords", dest="stopwords", default="get,set,is,has,have,does,with,without,from,to,of,in,on,for", help="Comma-separated stopwords for token analysis")
    parser_object.add_argument("--out-uncovered", dest="out_uncovered", default="./out/grams/uncovered_functions.txt", help="Path to write names not covered by any rule (prefix or sub_prefix)")
    args_object = parser_object.parse_args(argv_list)

    stopwords_list = [s.strip().lower() for s in args_object.stopwords.split(",") if s.strip()]
    stopword_set = set(stopwords_list)

    root_element = read_xml_root(args_object.xmlfile)
    function_names = get_all_function_names(root_element)

    prefixes_map, sub_prefixes_map = build_base_rules(function_names, args_object.min_single, args_object.min_pair, stopword_set)

    if args_object.use_grams:
        one_grams, two_grams, three_grams = load_grams(args_object.grams_dir)
        apply_grams_to_rules(two_grams, three_grams, function_names, prefixes_map, sub_prefixes_map, args_object.min_pair, args_object.min_triple)

        current_coverage = compute_coverage(function_names, prefixes_map, sub_prefixes_map)
        pair_floor = max(2, args_object.min_pair // 2)
        triple_floor = max(2, args_object.min_triple // 2)
        step_pair = max(1, args_object.min_pair // 5)
        step_triple = max(1, args_object.min_triple // 5)

        pair_cut = args_object.min_pair
        triple_cut = args_object.min_triple

        while current_coverage < args_object.target_coverage and (pair_cut > pair_floor or triple_cut > triple_floor):
            if pair_cut > pair_floor:
                pair_cut -= step_pair
            if triple_cut > triple_floor:
                triple_cut -= step_triple
            apply_grams_to_rules(two_grams, three_grams, function_names, prefixes_map, sub_prefixes_map, pair_cut, triple_cut)
            current_coverage = compute_coverage(function_names, prefixes_map, sub_prefixes_map)

    rules_data: Dict = {
        "prefixes": dict(sorted(prefixes_map.items(), key=lambda item_pair: item_pair[0].lower())),
        "sub_prefixes": dict(sorted(sub_prefixes_map.items(), key=lambda item_pair: item_pair[0].lower()))
    }

    if args_object.emit_explicit:
        explicit_map = emit_explicit_map(function_names, prefixes_map, sub_prefixes_map)
        rules_data["explicit_names"] = dict(sorted(explicit_map.items(), key=lambda item_pair: item_pair[0].lower()))

    write_rules_json(rules_data, args_object.out_rules)

    uncovered_list = compute_uncovered(function_names, prefixes_map, sub_prefixes_map)
    write_uncovered_log(uncovered_list, args_object.out_uncovered)

    coverage_ratio = compute_coverage(function_names, prefixes_map, sub_prefixes_map)
    print("Category rules written to:", args_object.out_rules)
    print("Prefixes:", len(prefixes_map))
    print("Sub-prefixes:", len(sub_prefixes_map))
    print("Explicit:", len(rules_data.get("explicit_names", {})) if "explicit_names" in rules_data else 0)
    print("Coverage:", "{:.1f}%".format(coverage_ratio * 100.0))
    print("Uncovered:", len(uncovered_list), "->", args_object.out_uncovered)
    print("Used grams:", bool(args_object.use_grams))
    print("Grams dir:", args_object.grams_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

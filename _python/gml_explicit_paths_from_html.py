#!/usr/bin/env python3
# gml_explicit_paths_from_html.py
# Build explicit function -> category path mapping from:
#   1) GmlSpec.xml (authoritative function names + deprecated flags)
#   2) Saved manual HTML/text with <a href=".../GML_Reference/.../<func>.htm"> links.
#   3) Optional last-resort merge file (default: ./data/explicit_paths.json)
#
# Guarantees:
#   - Exact name match is preferred.
#   - Alias swaps are applied as substring variants to cover color/colour, etc.
#   - If both variants exist in XML, both are mapped to the same path.
#   - Missing list EXCLUDES functions marked deprecated in XML.
#   - Merge file only fills functions that remain unmapped; never overwrites.
#
# Usage:
#   python gml_explicit_paths_from_html.py ./data/GmlSpec.xml ./data/GmlFuncHtml.txt --out-json ./out/explicit_paths.json --log-missing ./out/log/missing_in_html.txt --log-collisions ./out/log/collisions.txt  --merge-paths ./data/explicit_paths.json --debug

import argparse
import json
import os
import sys
import xml.etree.ElementTree as xml_et
from html.parser import HTMLParser
from urllib.parse import unquote
from typing import Dict, List, Set, Tuple

# -----------------------
# XML helpers
# -----------------------

def _truthy(text_value: str) -> bool:
    if text_value is None:
        return False
    lowered = text_value.strip().lower()
    return lowered in ("1", "true", "yes", "y", "deprecated")

def load_function_sets(xml_path: str) -> Tuple[Set[str], Dict[str, str], Set[str]]:
    if not os.path.isfile(xml_path):
        raise FileNotFoundError("XML file not found: %s" % xml_path)
    root_element = xml_et.parse(xml_path).getroot()
    functions_parent = root_element.find("Functions")
    if functions_parent is None:
        raise ValueError("No <Functions> element found in XML.")

    all_original_names: Set[str] = set()
    lower_to_original: Dict[str, str] = {}
    deprecated_lower_names: Set[str] = set()

    for function_element in functions_parent.findall("Function"):
        function_name = (function_element.get("Name") or "").strip()
        if not function_name:
            continue
        all_original_names.add(function_name)
        lower_to_original[function_name.lower()] = function_name

        is_deprecated_flag = False
        for attribute_key in ("Deprecated", "deprecated", "IsDeprecated", "is_deprecated"):
            if attribute_key in function_element.attrib:
                if _truthy(function_element.get(attribute_key)):
                    is_deprecated_flag = True
                    break
        if not is_deprecated_flag:
            deprecated_child = function_element.find("Deprecated")
            if deprecated_child is not None:
                if _truthy(deprecated_child.text or ""):
                    is_deprecated_flag = True

        if is_deprecated_flag:
            deprecated_lower_names.add(function_name.lower())

    return all_original_names, lower_to_original, deprecated_lower_names

# -----------------------
# Normalization and aliasing
# -----------------------

def normalize_name(name_text: str) -> str:
    return (name_text or "").strip().lower().replace("-", "_")

ALIAS_PAIRS = [
    ("colour", "color"),
    ("normalised", "normalized"),
    ("randomise", "randomize"),
    ("grey", "gray"),
    ("textcoord", "texcoord"),
]

def expand_alias_variants(base_candidate: str) -> Set[str]:
    seed_variants: Set[str] = set()
    seed_variants.add(base_candidate)
    seed_variants.add(base_candidate.replace("_", "-"))
    seed_variants.add(base_candidate.replace("-", "_"))

    changed_flag = True
    while changed_flag:
        changed_flag = False
        next_variants: Set[str] = set(seed_variants)
        for left_text, right_text in ALIAS_PAIRS:
            for value_text in seed_variants:
                if left_text in value_text:
                    flipped_text = value_text.replace(left_text, right_text)
                    if flipped_text not in next_variants:
                        next_variants.add(flipped_text)
                        changed_flag = True
                if right_text in value_text:
                    flipped_text = value_text.replace(right_text, left_text)
                    if flipped_text not in next_variants:
                        next_variants.add(flipped_text)
                        changed_flag = True
        seed_variants = next_variants
    return seed_variants

def humanize_segment(segment_text: str) -> str:
    clean_text = unquote(segment_text.strip().strip("/"))
    clean_text = clean_text.replace("-", " ")
    parts_list = [p for p in clean_text.split("_") if p]
    return " ".join([p.capitalize() for p in parts_list])

def path_from_href(href_value: str) -> str:
    if not href_value:
        return ""
    href_clean = unquote(href_value)
    href_lower = href_clean.lower()
    marker_text = "gml_reference/"
    index_position = href_lower.find(marker_text)
    if index_position == -1:
        return ""
    tail_text = href_clean[index_position + len(marker_text):]
    for separator_char in ("?", "#"):
        separator_index = tail_text.find(separator_char)
        if separator_index != -1:
            tail_text = tail_text[:separator_index]
    segment_list = [s for s in tail_text.split("/") if s]
    if not segment_list:
        return ""
    segment_list = segment_list[:-1]
    if not segment_list:
        return ""
    return "/".join(humanize_segment(s) for s in segment_list)

def filename_stem_from_href(href_value: str) -> str:
    if not href_value:
        return ""
    href_clean = unquote(href_value)
    last_segment = href_clean.split("/")[-1]
    for separator_char in ("?", "#"):
        separator_index = last_segment.find(separator_char)
        if separator_index != -1:
            last_segment = last_segment[:separator_index]
    if "." in last_segment:
        last_segment = last_segment.rsplit(".", 1)[0]
    return normalize_name(last_segment)

# -----------------------
# HTML parsing
# -----------------------

class ManualHtmlParser(HTMLParser):
    def __init__(self, lower_to_original: Dict[str, str], debug_flag: bool = False):
        super().__init__(convert_charrefs=True)
        self.debug_flag = debug_flag
        self.lower_to_original = lower_to_original

        self.anchor_active: bool = False
        self.anchor_text_parts: List[str] = []
        self.anchor_href_value: str = ""

        self.path_map: Dict[str, str] = {}
        self.collision_map: Dict[str, List[str]] = {}

        self.anchors_seen_count = 0
        self.anchors_matched_count = 0

    def handle_starttag(self, tag_name: str, attribute_list: List[Tuple[str, str]]) -> None:
        if tag_name == "a":
            self.anchor_active = True
            self.anchor_text_parts = []
            self.anchor_href_value = ""
            for attribute_key, attribute_value in attribute_list:
                if attribute_key == "href":
                    self.anchor_href_value = attribute_value or ""

    def handle_data(self, data_text: str) -> None:
        if self.anchor_active and data_text:
            self.anchor_text_parts.append(data_text)

    def handle_endtag(self, tag_name: str) -> None:
        if tag_name == "a":
            self._finalize_anchor()
            self.anchor_active = False
            self.anchor_text_parts = []
            self.anchor_href_value = ""

    def _finalize_anchor(self) -> None:
        self.anchors_seen_count += 1
        label_text = "".join(self.anchor_text_parts).strip()
        href_value = self.anchor_href_value

        candidate_set: Set[str] = set()
        if label_text:
            candidate_set.add(normalize_name(label_text))
        href_stem = filename_stem_from_href(href_value)
        if href_stem:
            candidate_set.add(href_stem)

        expanded_candidate_set: Set[str] = set()
        for candidate_value in candidate_set:
            expanded_candidate_set.add(candidate_value)
            expanded_candidate_set.update(expand_alias_variants(candidate_value))

        matched_original_names: Set[str] = set()
        for candidate_value in expanded_candidate_set:
            original_name = self.lower_to_original.get(candidate_value)
            if original_name:
                matched_original_names.add(original_name)

        if not matched_original_names:
            return

        self.anchors_matched_count += 1
        derived_path = path_from_href(href_value)
        if not derived_path:
            return

        for original_name in matched_original_names:
            previous_path = self.path_map.get(original_name)
            if previous_path is None:
                self.path_map[original_name] = derived_path
            else:
                previous_depth = previous_path.count("/") + (1 if previous_path else 0)
                current_depth = derived_path.count("/") + (1 if derived_path else 0)
                if current_depth > previous_depth:
                    self._record_collision(original_name, previous_path, derived_path)
                    self.path_map[original_name] = derived_path
                elif current_depth < previous_depth:
                    self._record_collision(original_name, derived_path, previous_path)
                else:
                    if derived_path != previous_path:
                        self._record_collision(original_name, derived_path, previous_path)

    def _record_collision(self, function_name: str, first_path: str, second_path: str) -> None:
        entries_list = self.collision_map.setdefault(function_name, [])
        pair_text = first_path + " || " + second_path
        if pair_text not in entries_list:
            entries_list.append(pair_text)

    def debug_summary(self) -> str:
        return "anchors_seen=%d anchors_matched=%d" % (self.anchors_seen_count, self.anchors_matched_count)

# -----------------------
# Merge support
# -----------------------

def load_merge_map(merge_path: str) -> Dict[str, str]:
    if not merge_path or not os.path.isfile(merge_path):
        return {}
    with open(merge_path, "r", encoding="utf-8") as input_file:
        try:
            data_map = json.load(input_file)
            if isinstance(data_map, dict):
                cleaned_map: Dict[str, str] = {}
                for key_name, value_path in data_map.items():
                    key_str = str(key_name).strip()
                    value_str = str(value_path).strip()
                    if key_str and value_str:
                        cleaned_map[key_str] = value_str
                return cleaned_map
        except Exception:
            return {}
    return {}

def apply_merge_last_resort(path_map: Dict[str, str],
                            lower_to_original: Dict[str, str],
                            merge_map: Dict[str, str]) -> Tuple[int, int, int]:
    added_count = 0
    skipped_preexist_count = 0
    skipped_unknown_count = 0
    for merge_key, merge_path in merge_map.items():
        lower_key = merge_key.lower()
        original_name = lower_to_original.get(lower_key)
        if not original_name:
            skipped_unknown_count += 1
            continue
        if original_name in path_map:
            skipped_preexist_count += 1
            continue
        path_map[original_name] = merge_path
        added_count += 1
    return added_count, skipped_preexist_count, skipped_unknown_count

# -----------------------
# IO helpers
# -----------------------

def write_json_map(path_map: Dict[str, str], out_json_path: str) -> None:
    os.makedirs(os.path.dirname(out_json_path) or ".", exist_ok=True)
    ordered_map = dict(sorted(path_map.items(), key=lambda item_pair: item_pair[0].lower()))
    with open(out_json_path, "w", encoding="utf-8") as out_file:
        json.dump(ordered_map, out_file, indent=2, ensure_ascii=True)

def write_lines(lines_list: List[str], out_path: str) -> None:
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as out_file:
        for line_text in lines_list:
            out_file.write(line_text + "\n")

# -----------------------
# Main
# -----------------------

def main(argument_list: List[str]) -> int:
    parser_object = argparse.ArgumentParser(
        description="Extract explicit function->category paths from manual HTML using GmlSpec.xml"
    )
    parser_object.add_argument("xmlfile", help="Path to GmlSpec.xml")
    parser_object.add_argument("htmlfile", help="Path to saved manual HTML (as text)")
    parser_object.add_argument("--out-json", dest="out_json", default="./out/explicit_paths.json")
    parser_object.add_argument("--log-missing", dest="log_missing", default="./out/log/missing_in_html.txt")
    parser_object.add_argument("--log-collisions", dest="log_collisions", default="./out/log/collisions.txt")
    parser_object.add_argument("--merge-paths", dest="merge_paths", default="./data/explicit_paths.json",
                               help="Optional last-resort explicit map to merge after parsing (no overwrite).")
    parser_object.add_argument("--no-merge", dest="no_merge", action="store_true",
                               help="Disable last-resort merge even if the file exists.")
    parser_object.add_argument("--debug", action="store_true", help="Print basic debug counters and probes")
    parsed_args = parser_object.parse_args(argument_list)

    all_function_names, lower_to_original, deprecated_lower_names = load_function_sets(parsed_args.xmlfile)

    with open(parsed_args.htmlfile, "r", encoding="utf-8", errors="ignore") as html_file:
        html_text = html_file.read()

    html_parser = ManualHtmlParser(lower_to_original, debug_flag=parsed_args.debug)
    html_parser.feed(html_text)

    # Last-resort merge step
    merged_added = 0
    merged_preexist = 0
    merged_unknown = 0
    if not parsed_args.no_merge:
        merge_map = load_merge_map(parsed_args.merge_paths)
        if merge_map:
            merged_added, merged_preexist, merged_unknown = apply_merge_last_resort(
                html_parser.path_map, lower_to_original, merge_map
            )

    write_json_map(html_parser.path_map, parsed_args.out_json)

    # Only include NOT-deprecated names in the missing list (unless they already have a path).
    missing_names = sorted(
        [
            name_value
            for name_value in all_function_names
            if (name_value not in html_parser.path_map and name_value.lower() not in deprecated_lower_names)
        ],
        key=lambda s: s.lower(),
    )
    write_lines(['"%s"' % name_value for name_value in missing_names], parsed_args.log_missing)

    collision_lines: List[str] = []
    for function_name, pair_list in sorted(html_parser.collision_map.items(), key=lambda pair_item: pair_item[0].lower()):
        for pair_text in pair_list:
            collision_lines.append('"%s" || %s' % (function_name, pair_text))
    write_lines(collision_lines, parsed_args.log_collisions)

    print("Explicit paths written:", parsed_args.out_json)
    print("Mapped functions:", len(html_parser.path_map))
    print("Missing (non-deprecated only):", len(missing_names), "->", parsed_args.log_missing)
    print("Collisions:", len(collision_lines), "->", parsed_args.log_collisions)
    if not parsed_args.no_merge:
        print("Merge file:", parsed_args.merge_paths)
        print("  Added:", merged_added, "Skipped preexist:", merged_preexist, "Skipped unknown:", merged_unknown)
    if parsed_args.debug:
        print("Debug:", html_parser.debug_summary())
        for probe_name in (
            "draw_set_color", "draw_set_colour",
            "make_color_rgb", "make_colour_rgb",
            "gpu_get_colorwriteenable", "gpu_get_colourwriteenable",
            "color_get_red", "colour_get_red",
            "window_set_color", "window_set_colour"
        ):
            if probe_name in html_parser.path_map:
                print(probe_name + " -> " + html_parser.path_map[probe_name])
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

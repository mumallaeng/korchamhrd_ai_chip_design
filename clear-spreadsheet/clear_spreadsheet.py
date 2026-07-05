#!/usr/bin/env python3
"""Flatten theme-driven spreadsheet styling into explicit cell styling.

The tool targets .xlsx files that look correct in Excel but pick up hidden
table/theme styling when opened in Google Sheets. Instead of round-tripping the
workbook through Excel libraries, it edits the OOXML package directly so the
existing cell content and layout stay as untouched as possible.
"""

from __future__ import annotations

import argparse
import colorsys
import posixpath
import tempfile
import zipfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable
from xml.etree import ElementTree as ET


NAMESPACES = {
    "main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "pkgrel": "http://schemas.openxmlformats.org/package/2006/relationships",
    "docrel": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "ct": "http://schemas.openxmlformats.org/package/2006/content-types",
    "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
    "mc": "http://schemas.openxmlformats.org/markup-compatibility/2006",
    "x14ac": "http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac",
}

# Excel theme colors are exposed in a stable index order inside clrScheme.
THEME_COLOR_ORDER = (
    "lt1",
    "dk1",
    "lt2",
    "dk2",
    "accent1",
    "accent2",
    "accent3",
    "accent4",
    "accent5",
    "accent6",
    "hlink",
    "folHlink",
)

# Register namespaces once so ElementTree writes readable OOXML back out.
for prefix, uri in (
    ("", NAMESPACES["main"]),
    ("r", NAMESPACES["docrel"]),
    ("a", NAMESPACES["a"]),
    ("mc", NAMESPACES["mc"]),
    ("x14ac", NAMESPACES["x14ac"]),
):
    ET.register_namespace(prefix, uri)


def qname(namespace: str, tag: str) -> str:
    """Build a fully qualified XML tag name for ElementTree lookups."""
    return f"{{{NAMESPACES[namespace]}}}{tag}"


def xml_bytes(root: ET.Element) -> bytes:
    """Serialize an XML tree with the declaration preserved."""
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def resolve_target(source_part: str, target: str) -> str:
    """Resolve OOXML relationship targets relative to the current part."""
    if target.startswith("/"):
        return target.lstrip("/")
    return posixpath.normpath(posixpath.join(posixpath.dirname(source_part), target))


def argb_to_rgb(argb: str) -> str:
    """Drop the alpha channel when converting ARGB to RGB for colorsys math."""
    if len(argb) == 8:
        return argb[2:]
    if len(argb) == 6:
        return argb
    raise ValueError(f"Unsupported color value: {argb}")


def apply_tint(argb: str, tint: float) -> str:
    """Apply Excel's tint/lightness adjustment to a theme color."""
    if tint == 0:
        return argb.upper()

    rgb = argb_to_rgb(argb)
    red = int(rgb[0:2], 16) / 255.0
    green = int(rgb[2:4], 16) / 255.0
    blue = int(rgb[4:6], 16) / 255.0

    hue, lightness, saturation = colorsys.rgb_to_hls(red, green, blue)
    if tint < 0:
        lightness *= 1.0 + tint
    else:
        lightness = lightness * (1.0 - tint) + tint
    lightness = max(0.0, min(1.0, lightness))

    red, green, blue = colorsys.hls_to_rgb(hue, lightness, saturation)
    return "FF{:02X}{:02X}{:02X}".format(
        round(red * 255),
        round(green * 255),
        round(blue * 255),
    )


def extract_theme_colors(theme_bytes: bytes) -> dict[int, str]:
    """Read workbook theme colors and map them to Excel's theme indices."""
    root = ET.fromstring(theme_bytes)
    color_scheme = root.find(".//a:clrScheme", NAMESPACES)
    if color_scheme is None:
        return {}

    colors: dict[int, str] = {}
    for index, key in enumerate(THEME_COLOR_ORDER):
        node = color_scheme.find(f"a:{key}", NAMESPACES)
        if node is None or len(node) == 0:
            continue
        color_node = node[0]
        rgb = color_node.attrib.get("val") or color_node.attrib.get("lastClr")
        if rgb:
            colors[index] = ("FF" + rgb).upper()
    return colors


def count_theme_references(root: ET.Element) -> int:
    """Count any remaining XML nodes that still depend on theme colors."""
    return sum(1 for element in root.iter() if "theme" in element.attrib)


def materialize_theme_colors(styles_root: ET.Element, theme_colors: dict[int, str]) -> tuple[int, int]:
    """Replace theme color references in styles.xml with explicit RGB values.

    Keep the broader theme/style scaffolding intact so Excel can still round-
    trip the workbook without repairing unrelated parts such as drawings.
    """
    converted = 0
    stripped_font_schemes = 0

    for element in styles_root.iter():
        theme_value = element.attrib.get("theme")
        if theme_value is None:
            continue

        theme_index = int(theme_value)
        rgb = theme_colors.get(theme_index)
        if rgb is None:
            raise ValueError(f"Unsupported theme color index: {theme_index}")

        tint_value = element.attrib.get("tint")
        tint = float(tint_value) if tint_value else 0.0
        rgb = apply_tint(rgb, tint)

        element.attrib.pop("theme", None)
        element.attrib.pop("tint", None)
        element.attrib["rgb"] = rgb
        converted += 1

    return converted, stripped_font_schemes


def remove_google_extensions(ext_list: ET.Element | None) -> int:
    """Drop Google Sheets round-trip metadata extensions from an extLst node."""
    if ext_list is None:
        return 0

    removed = 0
    for ext in list(ext_list):
        uri = ext.attrib.get("uri", "")
        if "GoogleSheetsCustomDataVersion" in uri:
            ext_list.remove(ext)
            removed += 1
    return removed


def remove_empty_ext_list(parent: ET.Element, tag_name: str) -> int:
    """Remove an extLst wrapper entirely if all supported child extensions were removed."""
    ext_list = parent.find(f"main:{tag_name}", NAMESPACES)
    if ext_list is None:
        return 0

    removed = remove_google_extensions(ext_list)
    if len(ext_list) == 0:
        parent.remove(ext_list)
    return removed


@dataclass
class CleanSummary:
    """High-level cleanup counts that are useful for CLI output and tests."""
    output_path: Path
    removed_parts: list[str] = field(default_factory=list)
    converted_theme_references: int = 0
    stripped_font_schemes: int = 0
    removed_table_parts: int = 0
    removed_table_relationships: int = 0
    removed_google_extensions: int = 0


def build_output_path(input_path: Path, suffix: str) -> Path:
    """Create the default output name beside the source workbook."""
    return input_path.with_name(f"{input_path.stem}.{suffix}{input_path.suffix}")


def ensure_xlsx(input_path: Path) -> None:
    """Fail early for formats this XML-based cleaner does not support."""
    if input_path.suffix.lower() != ".xlsx":
        raise ValueError("Only .xlsx files are supported.")


def clean_workbook(input_path: Path, output_path: Path, overwrite: bool = False) -> CleanSummary:
    """Clean a workbook by removing theme/table artifacts while keeping cell fills.

    The implementation works directly on the zipped OOXML package:
    1. Load workbook/style/sheet XML parts.
    2. Convert theme color references to concrete RGB values.
    3. Remove table definitions, table relationships, and Google metadata.
    4. Rebuild the .xlsx atomically through a temporary file.
    """
    ensure_xlsx(input_path)

    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    if input_path.resolve() != output_path.resolve() and output_path.exists() and not overwrite:
        raise FileExistsError(f"Refusing to overwrite existing file: {output_path}")

    workbook_path = "xl/workbook.xml"
    workbook_rels_path = "xl/_rels/workbook.xml.rels"
    styles_path = "xl/styles.xml"
    content_types_path = "[Content_Types].xml"

    with zipfile.ZipFile(input_path) as zin:
        names = {info.filename for info in zin.infolist()}
        required = {workbook_path, workbook_rels_path, styles_path, content_types_path}
        missing = sorted(required - names)
        if missing:
            raise ValueError(f"Unsupported workbook structure, missing: {', '.join(missing)}")

        workbook_root = ET.fromstring(zin.read(workbook_path))
        workbook_rels_root = ET.fromstring(zin.read(workbook_rels_path))
        styles_root = ET.fromstring(zin.read(styles_path))
        content_types_root = ET.fromstring(zin.read(content_types_path))

        theme_part: str | None = None
        metadata_part: str | None = None
        worksheet_parts: list[str] = []
        removed_parts: set[str] = set()
        removed_table_relationships = 0
        removed_table_parts = 0

        # First pass: discover workbook-level parts that need to be preserved,
        # rewritten, or removed entirely from the package.
        for relationship in list(workbook_rels_root):
            rel_type = relationship.attrib.get("Type", "")
            target = resolve_target(workbook_path, relationship.attrib["Target"])
            if rel_type.endswith("/worksheet"):
                worksheet_parts.append(target)
            elif rel_type.endswith("/theme"):
                theme_part = target
            elif "workbookmetadata" in rel_type.lower():
                metadata_part = target
                removed_parts.add(target)
                workbook_rels_root.remove(relationship)

        theme_reference_count = count_theme_references(styles_root)
        if theme_reference_count and theme_part is None:
            raise ValueError("Workbook uses theme colors but does not expose a theme part.")

        theme_colors = extract_theme_colors(zin.read(theme_part)) if theme_part else {}
        converted_theme_references, stripped_font_schemes = materialize_theme_colors(styles_root, theme_colors)

        remaining_theme_references = count_theme_references(styles_root)
        if remaining_theme_references:
            raise ValueError(
                f"Workbook still contains {remaining_theme_references} unresolved theme references."
            )

        removed_google_extensions = remove_empty_ext_list(workbook_root, "extLst")

        worksheet_updates: dict[str, bytes] = {}
        relationship_updates: dict[str, bytes | None] = {}

        # Second pass: rewrite each worksheet and drop only the table-related
        # relationship entries, leaving drawings and other attachments intact.
        for worksheet_part in worksheet_parts:
            worksheet_root = ET.fromstring(zin.read(worksheet_part))

            table_parts = worksheet_root.find("main:tableParts", NAMESPACES)
            if table_parts is not None:
                removed_table_parts += len(list(table_parts))
                worksheet_root.remove(table_parts)

            removed_google_extensions += remove_empty_ext_list(worksheet_root, "extLst")
            worksheet_updates[worksheet_part] = xml_bytes(worksheet_root)

            sheet_name = posixpath.basename(worksheet_part)
            rels_part = posixpath.join(posixpath.dirname(worksheet_part), "_rels", f"{sheet_name}.rels")
            if rels_part not in names:
                continue

            rels_root = ET.fromstring(zin.read(rels_part))
            changed = False
            for relationship in list(rels_root):
                rel_type = relationship.attrib.get("Type", "")
                if rel_type.endswith("/table"):
                    removed_parts.add(resolve_target(worksheet_part, relationship.attrib["Target"]))
                    rels_root.remove(relationship)
                    removed_table_relationships += 1
                    changed = True

            if changed:
                relationship_updates[rels_part] = xml_bytes(rels_root) if len(rels_root) else None

        override_tag = qname("ct", "Override")
        for override in list(content_types_root):
            if override.tag != override_tag:
                continue
            part_name = override.attrib.get("PartName", "").lstrip("/")
            content_type = override.attrib.get("ContentType", "")
            if part_name in removed_parts:
                content_types_root.remove(override)
                continue
            if content_type == "application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml":
                content_types_root.remove(override)
                continue
            if content_type == "application/binary" and metadata_part and part_name == metadata_part:
                content_types_root.remove(override)

        modified_parts: dict[str, bytes | None] = {
            workbook_path: xml_bytes(workbook_root),
            workbook_rels_path: xml_bytes(workbook_rels_root),
            styles_path: xml_bytes(styles_root),
            content_types_path: xml_bytes(content_types_root),
        }
        modified_parts.update(worksheet_updates)
        modified_parts.update(relationship_updates)

        with tempfile.NamedTemporaryFile(
            prefix=f"{output_path.name}.",
            suffix=".tmp",
            dir=output_path.parent,
            delete=False,
        ) as handle:
            temp_output_path = Path(handle.name)

        try:
            # Write a new archive first, then replace the destination in one
            # step so partially written files are never left behind.
            with zipfile.ZipFile(temp_output_path, "w", compression=zipfile.ZIP_DEFLATED) as zout:
                for info in zin.infolist():
                    part_name = info.filename
                    if part_name in removed_parts:
                        continue
                    if part_name in relationship_updates and relationship_updates[part_name] is None:
                        continue
                    data = modified_parts.get(part_name)
                    if data is None:
                        data = zin.read(part_name)
                    zout.writestr(part_name, data)

            temp_output_path.replace(output_path)
        except Exception:
            temp_output_path.unlink(missing_ok=True)
            raise

    return CleanSummary(
        output_path=output_path,
        removed_parts=sorted(removed_parts),
        converted_theme_references=converted_theme_references,
        stripped_font_schemes=stripped_font_schemes,
        removed_table_parts=removed_table_parts,
        removed_table_relationships=removed_table_relationships,
        removed_google_extensions=removed_google_extensions,
    )


def parse_args(argv: Iterable[str] | None = None) -> argparse.Namespace:
    """Parse CLI arguments for the standalone script entrypoint."""
    parser = argparse.ArgumentParser(
        description=(
            "Remove workbook theme/table styling that can override explicit cell colors "
            "when an .xlsx file is opened in Google Sheets."
        )
    )
    parser.add_argument("input", type=Path, help="Path to the source .xlsx file")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Path for the cleaned file. Defaults to <name>.cleaned.xlsx",
    )
    parser.add_argument(
        "--suffix",
        default="cleaned",
        help="Suffix to use for the default output filename. Default: cleaned",
    )
    parser.add_argument(
        "--in-place",
        action="store_true",
        help="Replace the original file in place instead of writing a new file",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Allow overwriting an existing output file",
    )
    return parser.parse_args(argv)


def main(argv: Iterable[str] | None = None) -> int:
    """Run the CLI and print a short cleanup summary."""
    try:
        args = parse_args(argv)
        input_path = args.input.expanduser().resolve()

        if args.in_place and args.output:
            raise ValueError("--in-place and --output cannot be used together.")

        output_path = (
            input_path
            if args.in_place
            else (
                args.output.expanduser().resolve()
                if args.output
                else build_output_path(input_path, args.suffix)
            )
        )

        summary = clean_workbook(
            input_path=input_path,
            output_path=output_path,
            overwrite=args.overwrite or args.in_place,
        )
    except (FileExistsError, FileNotFoundError, ValueError) as exc:
        raise SystemExit(str(exc)) from exc

    print("Done.")
    print(f"Output file: {summary.output_path}")
    print(
        "Removed theme/table artifacts: "
        f"{len(summary.removed_parts)} parts, "
        f"{summary.removed_table_relationships} table links, "
        f"{summary.converted_theme_references} theme color refs"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

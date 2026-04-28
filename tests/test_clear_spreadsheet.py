from __future__ import annotations

import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from clear_spreadsheet import clean_workbook


THEME_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Sheets">
  <a:themeElements>
    <a:clrScheme name="Sheets">
      <a:dk1><a:srgbClr val="000000"/></a:dk1>
      <a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="000000"/></a:dk2>
      <a:lt2><a:srgbClr val="FFFFFF"/></a:lt2>
      <a:accent1><a:srgbClr val="4285F4"/></a:accent1>
      <a:accent2><a:srgbClr val="EA4335"/></a:accent2>
      <a:accent3><a:srgbClr val="FBBC04"/></a:accent3>
      <a:accent4><a:srgbClr val="34A853"/></a:accent4>
      <a:accent5><a:srgbClr val="FF6D01"/></a:accent5>
      <a:accent6><a:srgbClr val="46BDC6"/></a:accent6>
      <a:hlink><a:srgbClr val="1155CC"/></a:hlink>
      <a:folHlink><a:srgbClr val="1155CC"/></a:folHlink>
    </a:clrScheme>
  </a:themeElements>
</a:theme>
"""

WORKBOOK_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
          xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
          xmlns:gs="http://customooxmlschemas.google.com/">
  <sheets>
    <sheet name="WBS" sheetId="1" state="visible" r:id="rId4"/>
  </sheets>
  <extLst>
    <ext uri="GoogleSheetsCustomDataVersion2">
      <gs:sheetsCustomData r:id="rId5"/>
    </ext>
  </extLst>
</workbook>
"""

WORKBOOK_RELS_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId5" Type="http://customschemas.google.com/relationships/workbookmetadata" Target="metadata"/>
</Relationships>
"""

STYLES_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1">
    <font>
      <name val="Arial"/>
      <color theme="1"/>
      <scheme val="minor"/>
    </font>
  </fonts>
  <fills count="2">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="solid"><fgColor theme="0"/><bgColor theme="0"/></patternFill></fill>
  </fills>
  <borders count="1"><border/></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="1" borderId="0" applyFill="1"/></cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
  <dxfs count="1"><dxf/></dxfs>
  <tableStyles count="1" defaultTableStyle="TableStyleMedium9">
    <tableStyle name="WBS-style" pivot="0" count="2"/>
  </tableStyles>
</styleSheet>
"""

SHEET_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
           xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheetData>
    <row r="1">
      <c r="A1" s="0" t="inlineStr"><is><t>hello</t></is></c>
    </row>
  </sheetData>
  <tableParts count="1">
    <tablePart r:id="rId2"/>
  </tableParts>
</worksheet>
"""

SHEET_RELS_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing" Target="../drawings/drawing1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/table" Target="../tables/table1.xml"/>
</Relationships>
"""

TABLE_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<table xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
       ref="A1:A1" displayName="Table_1" name="Table_1" id="1">
  <tableColumns count="1"><tableColumn id="1" name="Column1"/></tableColumns>
  <tableStyleInfo name="WBS-style" showRowStripes="1" showColumnStripes="0"/>
</table>
"""

CONTENT_TYPES_XML = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
  <Override PartName="/xl/tables/table1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml"/>
  <Override PartName="/xl/metadata" ContentType="application/binary"/>
</Types>
"""


class CleanWorkbookTests(unittest.TestCase):
    def create_fixture(self, path: Path) -> None:
        with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as workbook:
            workbook.writestr("[Content_Types].xml", CONTENT_TYPES_XML)
            workbook.writestr("xl/workbook.xml", WORKBOOK_XML)
            workbook.writestr("xl/_rels/workbook.xml.rels", WORKBOOK_RELS_XML)
            workbook.writestr("xl/styles.xml", STYLES_XML)
            workbook.writestr("xl/theme/theme1.xml", THEME_XML)
            workbook.writestr("xl/worksheets/sheet1.xml", SHEET_XML)
            workbook.writestr("xl/worksheets/_rels/sheet1.xml.rels", SHEET_RELS_XML)
            workbook.writestr("xl/tables/table1.xml", TABLE_XML)
            workbook.writestr("xl/sharedStrings.xml", "")
            workbook.writestr("xl/drawings/drawing1.xml", "<drawing/>")
            workbook.writestr("xl/metadata", b"google-metadata")

    def test_clean_workbook_removes_theme_tables_and_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            source = tmp_path / "input.xlsx"
            output = tmp_path / "output.cleaned.xlsx"
            self.create_fixture(source)

            summary = clean_workbook(source, output)

            self.assertEqual(summary.removed_table_parts, 1)
            self.assertEqual(summary.removed_table_relationships, 1)
            self.assertGreaterEqual(summary.converted_theme_references, 3)

            with zipfile.ZipFile(output) as workbook:
                names = set(workbook.namelist())
                self.assertNotIn("xl/theme/theme1.xml", names)
                self.assertNotIn("xl/tables/table1.xml", names)
                self.assertNotIn("xl/metadata", names)

                styles = workbook.read("xl/styles.xml").decode("utf-8")
                self.assertNotIn('theme="', styles)
                self.assertIn('rgb="FFFFFFFF"', styles)
                self.assertIn("<tableStyles count=\"0\" />", styles)

                sheet = workbook.read("xl/worksheets/sheet1.xml").decode("utf-8")
                self.assertNotIn("tableParts", sheet)

                workbook_rels = workbook.read("xl/_rels/workbook.xml.rels").decode("utf-8")
                self.assertNotIn("theme/theme1.xml", workbook_rels)
                self.assertNotIn("metadata", workbook_rels)

                sheet_rels = workbook.read("xl/worksheets/_rels/sheet1.xml.rels").decode("utf-8")
                self.assertNotIn("/table", sheet_rels)
                self.assertIn("/drawing", sheet_rels)

    def test_clean_workbook_can_replace_file_in_place(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            source = Path(tmp_dir) / "input.xlsx"
            self.create_fixture(source)

            summary = clean_workbook(source, source, overwrite=True)

            self.assertEqual(summary.output_path, source)
            with zipfile.ZipFile(source) as workbook:
                self.assertNotIn("xl/theme/theme1.xml", workbook.namelist())


if __name__ == "__main__":
    unittest.main()

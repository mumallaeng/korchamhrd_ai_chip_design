from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from clear_spreadsheet_gui import supported_xlsx_paths, unique_paths


class GuiHelperTests(unittest.TestCase):
    def test_unique_paths_preserves_first_seen_order(self) -> None:
        paths = [
            Path("./alpha.xlsx"),
            Path("./beta.xlsx"),
            Path("./alpha.xlsx"),
        ]
        deduped = unique_paths(paths)
        self.assertEqual([path.name for path in deduped], ["alpha.xlsx", "beta.xlsx"])

    def test_supported_xlsx_paths_filters_other_extensions(self) -> None:
        accepted, rejected = supported_xlsx_paths(
            [
                Path("one.xlsx"),
                Path("two.xls"),
                Path("three.pdf"),
                Path("four.XLSX"),
            ]
        )
        self.assertEqual([path.name for path in accepted], ["one.xlsx", "four.XLSX"])
        self.assertEqual([path.name for path in rejected], ["two.xls", "three.pdf"])


if __name__ == "__main__":
    unittest.main()

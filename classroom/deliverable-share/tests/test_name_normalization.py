import runpy
import unittest
import unicodedata
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
MODULE = runpy.run_path(str(PROJECT_ROOT / "classroom_deliverable_share.py"))
normalize_zip_member_path = MODULE["normalize_zip_member_path"]
nfc = MODULE["nfc"]


class NameNormalizationTests(unittest.TestCase):
    def test_normalize_zip_member_path_returns_nfc_parts(self) -> None:
        decomposed = unicodedata.normalize("NFD", "김연우/김연우_20260506_일지.pdf")
        normalized = normalize_zip_member_path(decomposed)
        self.assertEqual(normalized.parts[0], nfc("김연우"))
        self.assertEqual(normalized.parts[1], nfc("김연우_20260506_일지.pdf"))

    def test_normalize_zip_member_path_rejects_parent_escape(self) -> None:
        with self.assertRaises(RuntimeError):
            normalize_zip_member_path("../escape.txt")


if __name__ == "__main__":
    unittest.main()

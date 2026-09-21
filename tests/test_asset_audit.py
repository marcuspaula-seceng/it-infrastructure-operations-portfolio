"""Unit tests for the asset audit reconciliation tool."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

# Make the project's src directory importable without packaging.
SRC = (
    Path(__file__).resolve().parents[1]
    / "projects"
    / "02-asset-management-audit"
    / "src"
)
sys.path.insert(0, str(SRC))

import asset_audit  # noqa: E402


class ReconcileTests(unittest.TestCase):
    def test_all_matched(self) -> None:
        result = asset_audit.reconcile(["A1", "A2"], ["A1", "A2"])
        self.assertEqual(result.matched, ["A1", "A2"])
        self.assertEqual(result.missing, [])
        self.assertEqual(result.unexpected, [])
        self.assertEqual(result.duplicate, [])

    def test_missing_and_unexpected(self) -> None:
        result = asset_audit.reconcile(["A1", "A2", "A3"], ["A1", "X9"])
        self.assertEqual(result.matched, ["A1"])
        self.assertEqual(result.missing, ["A2", "A3"])
        self.assertEqual(result.unexpected, ["X9"])

    def test_duplicate_detection(self) -> None:
        result = asset_audit.reconcile(["A1", "A2"], ["A1", "A1", "A2"])
        self.assertEqual(result.duplicate, ["A1"])
        self.assertEqual(result.matched, ["A1", "A2"])

    def test_summary_counts(self) -> None:
        result = asset_audit.reconcile(["A1", "A2", "A3"], ["A1", "A1", "X9"])
        self.assertEqual(
            result.as_summary(),
            {"matched": 1, "missing": 2, "unexpected": 1, "duplicate": 1},
        )

    def test_empty_inputs(self) -> None:
        result = asset_audit.reconcile([], [])
        self.assertEqual(
            result.as_summary(),
            {"matched": 0, "missing": 0, "unexpected": 0, "duplicate": 0},
        )


class NormaliseTests(unittest.TestCase):
    def test_trim_and_uppercase(self) -> None:
        self.assertEqual(asset_audit._normalise("  a1 "), "A1")

    def test_case_insensitive_match(self) -> None:
        result = asset_audit.reconcile(
            [asset_audit._normalise("a1")],
            [asset_audit._normalise(" A1 ")],
        )
        self.assertEqual(result.matched, ["A1"])
        self.assertEqual(result.missing, [])


class CsvReadingTests(unittest.TestCase):
    def _write(self, name: str, content: str) -> Path:
        import tempfile

        directory = Path(tempfile.mkdtemp())
        path = directory / name
        path.write_text(content, encoding="utf-8")
        return path

    def test_reads_tags_and_ignores_blanks(self) -> None:
        path = self._write(
            "expected.csv",
            "asset_tag,device_type\nSAMPLE-0001,laptop\n,\nSAMPLE-0002,monitor\n",
        )
        self.assertEqual(
            asset_audit.read_asset_tags(path), ["SAMPLE-0001", "SAMPLE-0002"]
        )

    def test_missing_column_raises(self) -> None:
        path = self._write("bad.csv", "id,device_type\n1,laptop\n")
        with self.assertRaises(ValueError):
            asset_audit.read_asset_tags(path)

    def test_missing_file_raises(self) -> None:
        with self.assertRaises(FileNotFoundError):
            asset_audit.read_asset_tags(Path("does-not-exist.csv"))

    def test_example_files_reconcile_as_expected(self) -> None:
        base = SRC.parent / "examples"
        expected = asset_audit.read_asset_tags(base / "expected-assets.csv")
        scanned = asset_audit.read_asset_tags(base / "scanned-assets.csv")
        result = asset_audit.reconcile(expected, scanned)
        summary = result.as_summary()
        self.assertEqual(summary["matched"], 9)
        self.assertEqual(summary["missing"], 1)
        self.assertEqual(summary["unexpected"], 1)
        self.assertEqual(summary["duplicate"], 1)


if __name__ == "__main__":
    unittest.main()

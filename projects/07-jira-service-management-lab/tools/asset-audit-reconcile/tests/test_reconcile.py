"""Unit tests for the Assets audit reconciliation lab tool."""

from __future__ import annotations

import csv
import io
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from datetime import date, datetime
from pathlib import Path

# Make the tool importable without packaging.
TOOL_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_DIR))

import reconcile  # noqa: E402

SAMPLE = TOOL_DIR / "sample-data"


def _obj(name: str, status: str = "In use", location: str = "Dublin Office",
         assigned_to: str = "") -> reconcile.RegisterObject:
    return reconcile.RegisterObject(name, status, location, assigned_to)


def _scan(tag: str, location: str = "Dublin Office",
          at: str = "2026-11-12T10:00") -> reconcile.Scan:
    return reconcile.Scan(tag, location, datetime.fromisoformat(at), "Liam Byrne")


def _by_tag(lines):
    return {line.asset_tag: line for line in lines}


class ClassificationTests(unittest.TestCase):
    def test_found(self) -> None:
        lines = reconcile.reconcile([_obj("LT-0001")], [_scan("LT-0001")])
        self.assertEqual(lines[0].result, reconcile.FOUND)
        self.assertEqual(lines[0].note, "")

    def test_found_wrong_location(self) -> None:
        lines = reconcile.reconcile(
            [_obj("LT-0001", location="Dublin Office")],
            [_scan("LT-0001", location="IT Storage Room")],
        )
        self.assertEqual(lines[0].result, reconcile.WRONG_LOCATION)
        self.assertEqual(lines[0].scanned_location, "IT Storage Room")

    def test_missing(self) -> None:
        lines = reconcile.reconcile([_obj("LT-0007")], [])
        self.assertEqual(lines[0].result, reconcile.MISSING)
        self.assertEqual(lines[0].scan_count, 0)

    def test_unexpected(self) -> None:
        lines = reconcile.reconcile([], [_scan("LT-0099")])
        self.assertEqual(lines[0].result, reconcile.UNEXPECTED)
        self.assertEqual(lines[0].note, "Not in register")

    def test_retired_not_scanned_is_not_missing(self) -> None:
        lines = reconcile.reconcile([_obj("LT-0008", status="Retired")], [])
        self.assertEqual(lines[0].result, reconcile.RETIRED)

    def test_retired_but_scanned_is_flagged(self) -> None:
        lines = reconcile.reconcile(
            [_obj("LT-0008", status=" retired ")], [_scan("LT-0008")]
        )
        self.assertEqual(lines[0].result, reconcile.RETIRED)
        self.assertIn("disposal record", lines[0].note)

    def test_no_register_location_counts_as_found(self) -> None:
        lines = reconcile.reconcile([_obj("LT-0001", location="")], [_scan("LT-0001")])
        self.assertEqual(lines[0].result, reconcile.FOUND)
        self.assertIn("No location in register", lines[0].note)

    def test_empty_inputs(self) -> None:
        self.assertEqual(reconcile.reconcile([], []), [])
        self.assertEqual(
            reconcile.summarise([]),
            {category: 0 for category in reconcile.CATEGORIES} | {"Duplicate scans": 0},
        )


class DuplicateTests(unittest.TestCase):
    def test_duplicate_reported_once_with_note(self) -> None:
        lines = reconcile.reconcile(
            [_obj("LT-0002")],
            [_scan("LT-0002", at="2026-11-12T09:41"), _scan("LT-0002", at="2026-11-12T09:43")],
        )
        self.assertEqual(len(lines), 1)
        self.assertEqual(lines[0].result, reconcile.FOUND)
        self.assertEqual(lines[0].scan_count, 2)
        self.assertIn("Duplicate scan (2 times", lines[0].note)

    def test_duplicate_uses_latest_scan_location(self) -> None:
        lines = reconcile.reconcile(
            [_obj("LT-0001", location="Dublin Office")],
            [
                _scan("LT-0001", location="Dublin Office", at="2026-11-12T11:00"),
                _scan("LT-0001", location="IT Storage Room", at="2026-11-12T09:00"),
            ],
        )
        self.assertEqual(lines[0].result, reconcile.FOUND)
        self.assertIn("Dublin Office, IT Storage Room", lines[0].note)

    def test_duplicate_unexpected_tag(self) -> None:
        lines = reconcile.reconcile([], [_scan("LT-0099"), _scan("LT-0099")])
        self.assertEqual(len(lines), 1)
        self.assertEqual(lines[0].result, reconcile.UNEXPECTED)
        self.assertIn("Duplicate scan", lines[0].note)


class NormaliseTests(unittest.TestCase):
    def test_trim_collapse_and_uppercase(self) -> None:
        self.assertEqual(reconcile._normalise("  lt-0001 "), "LT-0001")
        self.assertEqual(reconcile._normalise(" it  storage room"), "IT STORAGE ROOM")

    def test_case_and_whitespace_insensitive_from_csv(self) -> None:
        directory = Path(tempfile.mkdtemp())
        scan_path = directory / "scan.csv"
        assets_path = directory / "assets.csv"
        scan_path.write_text(
            "asset_tag,scanned_location,scanned_at,scanned_by\n"
            " lt-0004 ,  dublin   office ,2026-11-12T09:47,Liam Byrne\n",
            encoding="utf-8",
        )
        assets_path.write_text(
            "Name,Status,Location,Assigned to\nLT-0004,In use,Dublin Office,Liam Byrne\n",
            encoding="utf-8",
        )
        lines = reconcile.reconcile(
            reconcile.read_register(assets_path), reconcile.read_scans(scan_path)
        )
        self.assertEqual(len(lines), 1)
        self.assertEqual(lines[0].asset_tag, "LT-0004")
        self.assertEqual(lines[0].result, reconcile.FOUND)


class CsvReadingTests(unittest.TestCase):
    def _write(self, name: str, content: str) -> Path:
        path = Path(tempfile.mkdtemp()) / name
        path.write_text(content, encoding="utf-8")
        return path

    def test_missing_column_raises(self) -> None:
        path = self._write("scan.csv", "asset_tag,scanned_location\nLT-0001,Dublin Office\n")
        with self.assertRaises(ValueError):
            reconcile.read_scans(path)

    def test_missing_file_raises(self) -> None:
        with self.assertRaises(FileNotFoundError):
            reconcile.read_scans(Path("does-not-exist.csv"))

    def test_bad_scan_date_raises(self) -> None:
        path = self._write(
            "scan.csv",
            "asset_tag,scanned_location,scanned_at,scanned_by\nLT-0001,Dublin Office,12/11/2026,Liam Byrne\n",
        )
        with self.assertRaises(ValueError):
            reconcile.read_scans(path)

    def test_duplicate_register_name_raises(self) -> None:
        path = self._write(
            "assets.csv",
            "Name,Status,Location,Assigned to\nLT-0001,In use,Dublin Office,\nlt-0001,In use,Dublin Office,\n",
        )
        with self.assertRaises(ValueError):
            reconcile.read_register(path)

    def test_blank_tags_ignored(self) -> None:
        path = self._write(
            "scan.csv",
            "asset_tag,scanned_location,scanned_at,scanned_by\n,Dublin Office,,\n",
        )
        self.assertEqual(reconcile.read_scans(path), [])


class SampleDataTests(unittest.TestCase):
    """The bundled sample data reproduces the 12 Nov 2026 lab audit."""

    def setUp(self) -> None:
        self.lines = reconcile.reconcile(
            reconcile.read_register(SAMPLE / "assets-export.csv"),
            reconcile.read_scans(SAMPLE / "scan.csv"),
        )

    def test_summary(self) -> None:
        self.assertEqual(
            reconcile.summarise(self.lines),
            {
                reconcile.FOUND: 4,
                reconcile.WRONG_LOCATION: 2,
                reconcile.MISSING: 1,
                reconcile.UNEXPECTED: 1,
                reconcile.RETIRED: 1,
                "Duplicate scans": 1,
            },
        )

    def test_individual_results(self) -> None:
        by_tag = _by_tag(self.lines)
        self.assertEqual(by_tag["LT-0001"].result, reconcile.WRONG_LOCATION)
        self.assertEqual(by_tag["LT-0006"].result, reconcile.WRONG_LOCATION)
        self.assertEqual(by_tag["LT-0007"].result, reconcile.MISSING)
        self.assertEqual(by_tag["LT-0008"].result, reconcile.RETIRED)
        self.assertEqual(by_tag["LT-0099"].result, reconcile.UNEXPECTED)
        self.assertEqual(by_tag["LT-0005"].scan_count, 2)
        # Scanned as " lt-0004 " in the sample file.
        self.assertEqual(by_tag["LT-0004"].result, reconcile.FOUND)


class OutputTests(unittest.TestCase):
    def test_main_writes_report_and_assets_import(self) -> None:
        directory = Path(tempfile.mkdtemp())
        report_path = directory / "report.csv"
        import_path = directory / "assets-import.csv"
        with redirect_stdout(io.StringIO()) as stdout:
            exit_code = reconcile.main([
                "--scan", str(SAMPLE / "scan.csv"),
                "--assets", str(SAMPLE / "assets-export.csv"),
                "--report", str(report_path),
                "--audit-date", "2026-11-12",
                "--import-csv", str(import_path),
            ])
        self.assertEqual(exit_code, 0)
        self.assertIn("Found - wrong location : 2", stdout.getvalue())

        with report_path.open(newline="", encoding="utf-8") as handle:
            report = list(csv.DictReader(handle))
        self.assertEqual(len(report), 9)

        with import_path.open(newline="", encoding="utf-8") as handle:
            rows = list(csv.DictReader(handle))
        self.assertEqual(list(rows[0]), list(reconcile.IMPORT_COLUMNS))
        names = [row["Name"] for row in rows]
        # Retired and Unexpected tags have nothing to update in Assets.
        self.assertEqual(names, [f"LT-000{n}" for n in range(1, 8)])
        self.assertTrue(all(row["Last audit date"] == "2026-11-12" for row in rows))
        self.assertEqual(
            {row["Name"]: row["Audit result"] for row in rows}["LT-0007"],
            reconcile.MISSING,
        )

    def test_assets_import_date_format(self) -> None:
        path = Path(tempfile.mkdtemp()) / "import.csv"
        lines = reconcile.reconcile([_obj("LT-0001")], [_scan("LT-0001")])
        written = reconcile.write_assets_import(lines, date(2026, 11, 12), path)
        self.assertEqual(written, 1)
        self.assertIn("LT-0001,2026-11-12,Found", path.read_text(encoding="utf-8"))

    def test_missing_input_returns_error_code(self) -> None:
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            exit_code = reconcile.main(["--scan", "nope.csv", "--assets", "nope.csv"])
        self.assertEqual(exit_code, 2)


if __name__ == "__main__":
    unittest.main()

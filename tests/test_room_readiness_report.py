"""Unit tests for the meeting room readiness reporting tool."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

SRC = (
    Path(__file__).resolve().parents[1]
    / "projects"
    / "05-meeting-room-readiness"
    / "src"
)
sys.path.insert(0, str(SRC))

import room_readiness_report as rrr  # noqa: E402


class BuildReportTests(unittest.TestCase):
    def test_counts_and_rate(self) -> None:
        report = rrr.build_report(["pass", "pass", "warning", "fail"])
        self.assertEqual(report.total, 4)
        self.assertEqual(report.passed, 2)
        self.assertEqual(report.warning, 1)
        self.assertEqual(report.failed, 1)
        self.assertEqual(report.readiness_rate, 50.0)

    def test_empty_results_rate_is_zero(self) -> None:
        report = rrr.build_report([])
        self.assertEqual(report.total, 0)
        self.assertEqual(report.readiness_rate, 0.0)

    def test_rate_rounding(self) -> None:
        report = rrr.build_report(["pass"] * 14 + ["warning"] * 3 + ["fail"] * 2)
        self.assertEqual(report.total, 19)
        self.assertEqual(report.readiness_rate, 73.7)


class ReadResultsTests(unittest.TestCase):
    def _write(self, content: str) -> Path:
        directory = Path(tempfile.mkdtemp())
        path = directory / "rooms.csv"
        path.write_text(content, encoding="utf-8")
        return path

    def test_reads_and_normalises(self) -> None:
        path = self._write(
            "room,result\nRoom-01,PASS\nRoom-02,Warning\nRoom-03,fail\n"
        )
        self.assertEqual(rrr.read_results(path), ["pass", "warning", "fail"])

    def test_invalid_result_raises(self) -> None:
        path = self._write("room,result\nRoom-01,unknown\n")
        with self.assertRaises(ValueError):
            rrr.read_results(path)

    def test_missing_column_raises(self) -> None:
        path = self._write("room,status\nRoom-01,pass\n")
        with self.assertRaises(ValueError):
            rrr.read_results(path)

    def test_missing_file_raises(self) -> None:
        with self.assertRaises(FileNotFoundError):
            rrr.read_results(Path("does-not-exist.csv"))

    def test_example_file_totals(self) -> None:
        example = SRC.parent / "examples" / "synthetic-room-results.csv"
        report = rrr.build_report(rrr.read_results(example))
        self.assertEqual(report.total, 19)
        self.assertEqual(report.passed, 14)
        self.assertEqual(report.warning, 3)
        self.assertEqual(report.failed, 2)
        self.assertEqual(report.readiness_rate, 73.7)


if __name__ == "__main__":
    unittest.main()

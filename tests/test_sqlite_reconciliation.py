"""Regression tests for the entirely synthetic Project 06 SQLite exercise."""

import importlib.util
import json
from pathlib import Path
import sqlite3
import subprocess
import sys
import unittest

PROJECT = Path(__file__).resolve().parents[1] / "projects" / "06-itam-itsm-sqlite-research"
SCRIPT = PROJECT / "src" / "reconcile_demo.py"
SPEC = importlib.util.spec_from_file_location("reconcile_demo", SCRIPT)
demo = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(demo)


class SqliteReconciliationTests(unittest.TestCase):
    def setUp(self):
        self.connection = sqlite3.connect(":memory:")
        self.addCleanup(self.connection.close)
        demo.initialise(self.connection)

    def test_seeded_categories_and_counts(self):
        report = demo.reconcile(self.connection, "DEMO-AUDIT-001")
        self.assertEqual(report["summary"],
                         {"matched": 2, "missing": 1, "unexpected": 1, "duplicate": 1})
        self.assertEqual(report["findings"], [
            {"category": "duplicate", "asset_id": "DEMO-ASSET-002", "scan_count": 2},
            {"category": "matched", "asset_id": "DEMO-ASSET-001", "scan_count": 1},
            {"category": "matched", "asset_id": "DEMO-ASSET-002", "scan_count": 2},
            {"category": "missing", "asset_id": "DEMO-ASSET-003", "scan_count": 0},
            {"category": "unexpected", "asset_id": "DEMO-ASSET-999", "scan_count": 1},
        ])

    def test_audits_are_isolated(self):
        report = demo.reconcile(self.connection, "DEMO-AUDIT-002")
        self.assertEqual(report["summary"],
                         {"matched": 1, "missing": 2, "unexpected": 0, "duplicate": 0})

    def test_unknown_audit_is_empty_scan_set(self):
        report = demo.reconcile(self.connection, "DEMO-AUDIT-UNKNOWN")
        self.assertEqual(report["summary"],
                         {"matched": 0, "missing": 3, "unexpected": 0, "duplicate": 0})

    def test_empty_database(self):
        self.connection.execute("DELETE FROM audit_scans")
        self.connection.execute("DELETE FROM expected_assets")
        self.assertEqual(demo.reconcile(self.connection, "DEMO-AUDIT-001")["findings"], [])

    def test_duplicate_unexpected_asset_has_both_flags(self):
        self.connection.execute(
            "INSERT INTO audit_scans (audit_id, asset_id) VALUES (?, ?)",
            ("DEMO-AUDIT-001", "DEMO-ASSET-999"))
        report = demo.reconcile(self.connection, "DEMO-AUDIT-001")
        flags = [r["category"] for r in report["findings"] if r["asset_id"] == "DEMO-ASSET-999"]
        self.assertEqual(flags, ["duplicate", "unexpected"])

    def test_expected_asset_ids_are_unique(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.connection.execute(
                "INSERT INTO expected_assets VALUES ('DEMO-ASSET-001', 'laptop')")

    def test_blank_asset_id_is_refused(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.connection.execute("INSERT INTO expected_assets VALUES (' ', 'laptop')")

    def test_audit_parameter_is_not_sql(self):
        report = demo.reconcile(self.connection, "' OR 1=1 --")
        self.assertEqual(report["summary"]["matched"], 0)
        self.assertEqual(self.connection.execute("SELECT COUNT(*) FROM audit_scans").fetchone()[0], 5)

    def test_blank_audit_refused(self):
        with self.assertRaises(ValueError):
            demo.reconcile(self.connection, " ")

    def test_initialise_does_not_replace_existing_schema(self):
        with self.assertRaises(sqlite3.OperationalError):
            demo.initialise(self.connection)
        self.assertEqual(self.connection.execute("SELECT COUNT(*) FROM audit_scans").fetchone()[0], 5)

    def test_cli_is_repeatable(self):
        command = [sys.executable, str(SCRIPT)]
        first = subprocess.run(command, check=True, capture_output=True, text=True)
        second = subprocess.run(command, check=True, capture_output=True, text=True)
        self.assertEqual(first.stdout, second.stdout)
        self.assertEqual(json.loads(first.stdout)["summary"]["matched"], 2)

    def test_cli_refuses_blank_audit(self):
        result = subprocess.run([sys.executable, str(SCRIPT), "--audit-id", " "],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("must not be blank", result.stderr)


if __name__ == "__main__":
    unittest.main()

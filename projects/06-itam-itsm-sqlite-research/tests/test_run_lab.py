"""Executor and lifecycle tests (standard library, no network).

These tests are deliberately kept out of the pinned run_lab.py inputs so that
adding them does not change the verified lab revision.
"""
import hashlib
import json
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

LAB = Path(__file__).resolve().parents[1]
RUN_LAB = LAB / "run_lab.py"
sys.path.insert(0, str(LAB))
from run_lab import INPUT_HASHES  # noqa: E402

CSV_NAMES = [Path(name).stem + ".csv" for name in INPUT_HASHES if name.startswith("queries/")]


def tree_digest(folder):
    digest = {}
    for path in sorted(folder.rglob("*")):
        if path.is_file():
            digest[str(path.relative_to(folder))] = hashlib.sha256(path.read_bytes()).hexdigest()
    return digest


class ExecutorTests(unittest.TestCase):
    def setUp(self):
        self.parent = Path(tempfile.mkdtemp(prefix="project06-test-"))

    def tearDown(self):
        shutil.rmtree(self.parent, ignore_errors=True)

    def run_lab(self, source_dir):
        return subprocess.run(
            [sys.executable, str(RUN_LAB), "--source-dir", str(source_dir),
             "--output-parent", str(self.parent)],
            capture_output=True, text=True, timeout=120,
        )

    def run_dirs(self):
        return sorted(self.parent.glob("project06-run-*"))

    def copy_inputs(self):
        source = self.parent / "source"
        for name in INPUT_HASHES:
            target = source / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes((LAB / name).read_bytes())
        return source

    def test_local_run_produces_complete_evidence(self):
        result = self.run_lab(LAB)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        (run,) = self.run_dirs()
        for name in ["test-output.txt", "run-results.json", "project06-demo.sqlite"] + CSV_NAMES:
            self.assertTrue((run / name).is_file(), name)
        self.assertEqual(len(CSV_NAMES), 5)
        evidence = json.loads((run / "run-results.json").read_text(encoding="utf-8"))
        self.assertEqual(evidence["test_count"], 8)
        self.assertEqual(evidence["test_exit_code"], 0)
        self.assertEqual(evidence["integrity_check"], [["ok"]])
        self.assertEqual(evidence["foreign_key_check"], [])
        self.assertIs(evidence["db_browser_gui_tested"], False)
        db = sqlite3.connect(str(run / "project06-demo.sqlite"))
        try:
            self.assertEqual(db.execute("PRAGMA integrity_check").fetchall(), [("ok",)])
            self.assertEqual(db.execute("SELECT COUNT(*) FROM assets").fetchone(), (4,))
        finally:
            db.close()

    def test_repeat_run_preserves_previous_results(self):
        self.assertEqual(self.run_lab(LAB).returncode, 0)
        (first,) = self.run_dirs()
        before = tree_digest(first)
        self.assertEqual(self.run_lab(LAB).returncode, 0)
        runs = self.run_dirs()
        self.assertEqual(len(runs), 2)
        self.assertEqual(tree_digest(first), before)

    def test_tampered_input_aborts_before_tests(self):
        source = self.copy_inputs()
        with (source / "seed.sql").open("a", encoding="utf-8") as handle:
            handle.write("-- tampered\n")
        result = self.run_lab(source)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Input hash mismatch: seed.sql", result.stderr)
        self.assertEqual(list(self.parent.rglob("project06-demo.sqlite")), [])
        self.assertEqual(list(self.parent.rglob("run-results.json")), [])

    def test_crlf_checkout_is_rejected_with_hint(self):
        source = self.copy_inputs()
        schema = source / "schema.sql"
        schema.write_bytes(schema.read_bytes().replace(b"\n", b"\r\n"))
        result = self.run_lab(source)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Input hash mismatch: schema.sql", result.stderr)
        self.assertIn("CRLF", result.stderr)


class LifecycleTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        for name in ("schema.sql", "seed.sql"):
            self.db.executescript((LAB / name).read_text(encoding="utf-8"))

    def tearDown(self):
        self.db.close()

    def test_return_then_reassign_keeps_custody_history(self):
        self.db.execute("UPDATE assignments SET returned_at='2026-03-01 09:00:00' WHERE assignment_id=1")
        self.db.execute("INSERT INTO assignments VALUES (4,'DEMO-ASSET-001','DEMO-PERSON-004','2026-03-02 09:00:00',NULL)")
        history = self.db.execute(
            "SELECT synthetic_person_id, returned_at IS NULL FROM assignments "
            "WHERE asset_id='DEMO-ASSET-001' ORDER BY assigned_at").fetchall()
        self.assertEqual(history, [("DEMO-PERSON-001", 0), ("DEMO-PERSON-004", 1)])

    def test_return_before_assignment_is_rejected(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("UPDATE assignments SET returned_at='2025-12-31 09:00:00' WHERE assignment_id=1")

    def test_records_for_unknown_assets_or_types_are_rejected(self):
        statements = [
            "INSERT INTO incidents VALUES (90,'DEMO-ASSET-404','vpn',2,'2026-02-01 09:00:00',NULL)",
            "INSERT INTO service_requests VALUES (90,'return','DEMO-ASSET-404','2026-02-05 00:00:00',NULL,NULL)",
            "INSERT INTO service_requests VALUES (91,'transfer','DEMO-ASSET-001','2026-02-05 00:00:00',NULL,NULL)",
            "INSERT INTO assets VALUES ('DEMO-ASSET-005','tablet','DEMO-SITE-A','stock')",
        ]
        for sql in statements:
            with self.subTest(sql=sql), self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(sql)


if __name__ == "__main__":
    unittest.main(verbosity=2)

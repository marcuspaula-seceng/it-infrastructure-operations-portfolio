"""Standard-library tests; fresh in-memory SQLite database per test."""
import sqlite3
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class LabTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        for name in ('schema.sql', 'seed.sql'):
            self.db.executescript((ROOT / name).read_text())

    def tearDown(self):
        self.db.close()

    def query(self, name):
        return self.db.execute((ROOT / 'queries' / name).read_text()).fetchall()

    def test_integrity(self):
        self.assertEqual(self.db.execute('PRAGMA integrity_check').fetchall(), [('ok',)])
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])
        self.assertEqual(self.db.execute('PRAGMA foreign_keys').fetchone(), (1,))
        for table, count in [('assets',4),('assignments',3),('audit_scans',4),('incidents',5),('service_requests',4),('preparation_checks',4)]:
            self.assertEqual(self.db.execute(f'SELECT COUNT(*) FROM {table}').fetchone(), (count,))

    def test_inventory(self):
        self.assertEqual(self.query('01_inventory.sql'), [('duplicate','DEMO-ASSET-001',2),('missing','DEMO-ASSET-003',0),('unexpected','DEMO-ASSET-999',1)])
        self.db.execute("INSERT INTO audit_scans VALUES (5,'OTHER-AUDIT','DEMO-ASSET-003','2026-02-01 00:00:00')")
        self.assertIn(('missing','DEMO-ASSET-003',0), self.query('01_inventory.sql'))

    def test_returns(self):
        rows = self.query('02_overdue_returns.sql')
        self.assertEqual([(r[0],r[-1]) for r in rows], [(1,'overdue'),(2,'approved_exception')])
        self.db.execute("UPDATE service_requests SET completed_at='2026-02-11 00:00:00' WHERE request_id=1")
        self.assertEqual(len(self.query('02_overdue_returns.sql')),2)
        self.db.execute("UPDATE service_requests SET due_at='2026-02-10 00:00:00' WHERE request_id=1")
        self.assertEqual(len(self.query('02_overdue_returns.sql')),1)

    def test_recurrence(self):
        self.assertEqual(self.query('03_recurring_incidents.sql'), [('DEMO-ASSET-001','vpn',2)])
        self.db.execute("INSERT INTO incidents VALUES (6,'DEMO-ASSET-001','vpn',2,'2026-03-01 00:00:00',NULL)")
        self.assertEqual(self.query('03_recurring_incidents.sql'), [('DEMO-ASSET-001','vpn',2)])

    def test_resolution(self):
        self.assertEqual(self.query('04_resolution.sql'), [(3,1,2.3333)])
        self.db.execute("UPDATE incidents SET resolved_at='2026-03-02 00:00:00' WHERE incident_id=3")
        self.assertEqual(self.query('04_resolution.sql'), [(3,1,2.3333)])
        self.db.execute('UPDATE incidents SET resolved_at=NULL')
        self.assertEqual(self.query('04_resolution.sql'), [(0,4,None)])

    def test_preparation(self):
        self.assertEqual(self.query('05_preparation_comparison.sql'), [
            ('DEMO-STANDARD-LAPTOP','reimage','after',2,25.0,100.0,2.4),
            ('DEMO-STANDARD-LAPTOP','reimage','before',2,45.0,50.0,1.33)])

    def test_rejected_invalid_records(self):
        statements = [
            "INSERT INTO assignments VALUES (99,'UNKNOWN','DEMO-PERSON-099','2026-01-01 00:00:00',NULL)",
            "INSERT INTO assignments VALUES (99,'DEMO-ASSET-001','DEMO-PERSON-099','2026-01-01 00:00:00',NULL)",
            "UPDATE incidents SET resolved_at='2025-01-01 00:00:00' WHERE incident_id=1",
            "UPDATE incidents SET priority=0 WHERE incident_id=1",
            "UPDATE preparation_checks SET duration_minutes=0 WHERE check_id=1",
            "UPDATE preparation_checks SET outcome='unknown' WHERE check_id=1",
            "UPDATE service_requests SET approved_exception_until='2025-01-01 00:00:00' WHERE request_id=1",
        ]
        for sql in statements:
            with self.subTest(sql=sql), self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(sql)

    def test_seed_is_not_silently_duplicated(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.executescript((ROOT / 'seed.sql').read_text())
        self.db.rollback()
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM assets').fetchone(), (4,))

if __name__ == '__main__':
    unittest.main(verbosity=2)

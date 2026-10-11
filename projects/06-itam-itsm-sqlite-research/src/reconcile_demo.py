"""Run the synthetic SQLite reconciliation exercise in memory, with no file writes."""

from __future__ import annotations

import argparse
import json
import sqlite3
from pathlib import Path

SQL_DIR = Path(__file__).resolve().parents[1] / "sql"
CATEGORIES = ("matched", "missing", "unexpected", "duplicate")


def initialise(connection: sqlite3.Connection, *, seed: bool = True) -> None:
    """Initialise an empty connection; refuse an existing schema rather than erase it."""
    connection.executescript((SQL_DIR / "schema.sql").read_text(encoding="utf-8"))
    if seed:
        connection.executescript((SQL_DIR / "seed.sql").read_text(encoding="utf-8"))


def reconcile(connection: sqlite3.Connection, audit_id: str) -> dict:
    """Report one audit against the fixture's single expected-inventory snapshot.

    Unknown audits represent an empty scan set: every expected asset is missing.
    A missing asset is an investigation lead, not proof of loss.
    """
    if not isinstance(audit_id, str) or not audit_id.strip():
        raise ValueError("audit_id must be a non-blank string")
    rows = connection.execute(
        (SQL_DIR / "reconcile.sql").read_text(encoding="utf-8"),
        {"audit_id": audit_id},
    ).fetchall()
    findings = [
        {"category": category, "asset_id": asset_id, "scan_count": count}
        for category, asset_id, count in rows
    ]
    return {
        "audit_id": audit_id,
        "summary": {
            category: sum(row["category"] == category for row in findings)
            for category in CATEGORIES
        },
        "findings": findings,
    }


def main(argv=None) -> int:
    """Print deterministic JSON generated from a fresh, in-memory database."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit-id", default="DEMO-AUDIT-001")
    args = parser.parse_args(argv)
    if not args.audit_id.strip():
        parser.error("--audit-id must not be blank")
    connection = sqlite3.connect(":memory:")
    try:
        initialise(connection)
        print(json.dumps(reconcile(connection, args.audit_id), indent=2))
    finally:
        connection.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

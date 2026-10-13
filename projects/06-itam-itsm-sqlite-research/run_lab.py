"""Run the synthetic lab in a new directory using Python's standard library.

The default download is pinned to the published lab commit and verified by SHA-256.
This script records the environment where it actually runs; it does not exercise
the DB Browser GUI or automatically upload any local evidence.
"""
import argparse
import csv
import hashlib
import json
import platform
import re
import sqlite3
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import urlopen

SOURCE_REVISION = "0f8be5fd9b931770b176c1730729827c57c856ad"
SOURCE_URL = (
    "https://raw.githubusercontent.com/marcuspaula-seceng/"
    "it-infrastructure-operations-portfolio/" + SOURCE_REVISION
    + "/projects/06-itam-itsm-sqlite-research/"
)
INPUT_HASHES = {
    "schema.sql": "4f1f3633089d9641a97656e3cd11ae70605d7862f75417342178093fd20b7d86",
    "seed.sql": "09ed93ca3cf1c791dace84d13934e6e403fa06feda5303c8424c6e1cac391414",
    "queries/01_inventory.sql": "db3554b57eb1ce53762999958638508f1a0cdc71fc327c1a6193e1c67c05c27a",
    "queries/02_overdue_returns.sql": "6d14f24059dc07c3b3ea525a8eb8a610f2b7c73f8e6d77b9986bf4d11ee076d4",
    "queries/03_recurring_incidents.sql": "b11fad875809ffe098d88fcc2bc0e12dd0896fe9759a32e01651ece17481987f",
    "queries/04_resolution.sql": "7815d8a9aa2526241db3546e7816d42bc5653a7487dd0dcaa1c3e003ca2ee7fa",
    "queries/05_preparation_comparison.sql": "519a961c99fa62c01a7b0780be56c0984f4e9abe070289fbb9cdde333922a019",
    "tests/test_lab.py": "8788f3e88874c975fc6f0d9ca4269163a5f80eb13ddda541cdca8c2927198281",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, help="Read pinned inputs locally instead of downloading")
    parser.add_argument("--output-parent", type=Path, default=Path.home(), help="Existing directory for a new isolated run folder")
    args = parser.parse_args()
    root = Path(tempfile.mkdtemp(prefix="project06-run-", dir=args.output_parent))
    print("Run directory: " + str(root), flush=True)
    for name, expected_hash in INPUT_HASHES.items():
        if args.source_dir:
            content = (args.source_dir / name).read_bytes()
        else:
            with urlopen(SOURCE_URL + name, timeout=30) as response:
                content = response.read()
        if hashlib.sha256(content).hexdigest() != expected_hash:
            raise ValueError("Input hash mismatch: " + name)
        target = root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)

    kernel = platform.release()
    evidence = {
        "executed_at_utc": datetime.now(timezone.utc).isoformat(),
        "environment": "WSL" if "microsoft" in kernel.lower() else platform.system(),
        "os": platform.system(),
        "kernel": kernel,
        "python": platform.python_version(),
        "sqlite_python_module": sqlite3.sqlite_version,
        "source_revision": SOURCE_REVISION,
        "input_sha256": INPUT_HASHES,
        "db_browser_gui_tested": False,
        "data": "Entirely synthetic fixtures; no employer exports",
    }
    os_release = Path("/etc/os-release")
    if os_release.is_file():
        for line in os_release.read_text(encoding="utf-8").splitlines():
            if line.startswith("PRETTY_NAME="):
                evidence["distribution"] = line.split("=", 1)[1].strip('"')
                break
    result = subprocess.run(
        [sys.executable, "tests/test_lab.py"], cwd=root,
        capture_output=True, text=True, timeout=60,
    )
    output = result.stdout + result.stderr
    (root / "test-output.txt").write_text(output, encoding="utf-8")
    print(output, end="", flush=True)
    count = re.search(r"Ran (\d+) tests", output)
    evidence["test_count"] = int(count.group(1)) if count else None
    evidence["test_exit_code"] = result.returncode

    if result.returncode == 0:
        database = root / "project06-demo.sqlite"
        db = sqlite3.connect(database)
        try:
            for name in ("schema.sql", "seed.sql"):
                db.executescript((root / name).read_text(encoding="utf-8"))
            evidence["integrity_check"] = db.execute("PRAGMA integrity_check").fetchall()
            evidence["foreign_key_check"] = db.execute("PRAGMA foreign_key_check").fetchall()
            evidence["foreign_keys_enabled_during_build"] = db.execute("PRAGMA foreign_keys").fetchone()[0]
            evidence["queries"] = {}
            for name in INPUT_HASHES:
                if not name.startswith("queries/"):
                    continue
                cursor = db.execute((root / name).read_text(encoding="utf-8"))
                columns = [column[0] for column in cursor.description]
                rows = cursor.fetchall()
                evidence["queries"][name] = {"columns": columns, "rows": rows}
                with (root / (Path(name).stem + ".csv")).open("w", newline="", encoding="utf-8") as handle:
                    writer = csv.writer(handle)
                    writer.writerow(columns)
                    writer.writerows(rows)
        finally:
            db.close()
        evidence["database_sha256"] = hashlib.sha256(database.read_bytes()).hexdigest()

    report = root / "run-results.json"
    report.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print("Evidence: " + str(report), flush=True)
    print("DB Browser GUI validation remains pending.", flush=True)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())

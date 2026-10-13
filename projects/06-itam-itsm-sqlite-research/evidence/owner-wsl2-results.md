# Owner execution — Ubuntu on WSL2 (Windows 11)

This record documents tests actually executed on the repository owner's own
Windows computer, inside **Ubuntu on WSL2**. It is not a VMware or Hyper-V
virtual machine, not a CI run and not DB Browser GUI evidence. Usernames,
host names, private paths and machine inventory are intentionally omitted; the
full logs remain on the owner's computer.

## Environment

| Item | Value |
|---|---|
| Host OS | Windows 11 Home (build 26300) |
| Linux environment | Ubuntu 24.04.4 LTS on WSL2 |
| Kernel | 6.18.33.2-microsoft-standard-WSL2 |
| Python | 3.12.3 |
| SQLite (Python `sqlite3` module) | 3.45.1 |
| DB Browser for SQLite | Not installed; GUI validation **not performed** |
| Network services | None required; no port opened or server started |
| Repository revision tested | `main` at `8a57a24` plus the changes in this branch |
| Lab input revision (pinned) | `0f8be5fd9b931770b176c1730729827c57c856ad` |
| Data | Entirely synthetic fixtures from `seed.sql` |

## Run 1 — 2026-10-13 01:13 UTC-03:00 (04:13 UTC): defect found

Commands, run from the repository root inside Ubuntu (checkout on the Windows
filesystem, cloned with Git for Windows):

```sh
python3 projects/06-itam-itsm-sqlite-research/tests/test_lab.py
python3 projects/06-itam-itsm-sqlite-research/run_lab.py \
  --source-dir projects/06-itam-itsm-sqlite-research --output-parent <evidence-dir>
python3 projects/06-itam-itsm-sqlite-research/run_lab.py --output-parent <evidence-dir>
```

| Step | Exit code | Result |
|---|---|---|
| Direct lab tests | 0 | 8 tests, OK |
| Executor, `--source-dir` (Windows checkout) | 1 | `ValueError: Input hash mismatch: schema.sql` |
| Executor, default HTTPS download | 0 | 8 tests, OK; database, 5 CSVs and JSON produced |

**Root cause.** Git for Windows ships with `core.autocrlf=true`, so the clone
contained CRLF line endings. The executor verifies inputs byte-for-byte, so
the hash no longer matched. Converting `schema.sql` back to LF reproduced the
pinned hash
`4f1f3633089d9641a97656e3cd11ae70605d7862f75417342178093fd20b7d86` exactly. The fixtures themselves were not wrong.

**Fix.** A repository `.gitattributes` keeps LF for Project 06 `.sql` and `.py`
files on every checkout, and the executor's error message now reports the
expected and actual hashes and flags CRLF content. Hash verification remains
strict; nothing is normalised silently.

## Run 2 — 2026-10-13 01:17 UTC-03:00 (04:17 UTC): after the fix

Pinned files were checked out again with LF (verified with `file` and
`git check-attr eol`), then every affected suite was re-run in a new folder.

| Step | Exit code | Result |
|---|---|---|
| `tests/test_lab.py` | 0 | 8 tests, OK |
| `tests/test_run_lab.py` (new) | 0 | 7 tests, OK |
| Executor, `--source-dir` | 0 | 8 tests, OK |
| Executor, default HTTPS download | 0 | 8 tests, OK |
| Repository root suite (`tests/`) | 0 | 19 tests, OK |
| Project 06 discovery (`projects/06-…/tests`) | 0 | 15 tests, OK |

Executor evidence (`run-results.json`, local-source run):

```json
{
  "executed_at_utc": "2026-10-13T04:17:27.533667+00:00",
  "executed_at_local": "2026-10-13T01:17:27.533687-03:00",
  "environment": "WSL",
  "distribution": "Ubuntu 24.04.4 LTS",
  "kernel": "6.18.33.2-microsoft-standard-WSL2",
  "python": "3.12.3",
  "sqlite_python_module": "3.45.1",
  "source_revision": "0f8be5fd9b931770b176c1730729827c57c856ad",
  "test_count": 8,
  "test_exit_code": 0,
  "integrity_check": [["ok"]],
  "foreign_key_check": [],
  "foreign_keys_enabled_during_build": 1,
  "database_sha256": "f3813f8f6cd4faa483232faffa34c58d89565a15f94a78e3de211c9c8932e473",
  "db_browser_gui_tested": false
}
```

Both executor runs produced the same database hash. It differs from the
assistant-environment hash (`3ea55a61…`), which used SQLite 3.53.1; the
on-disk file format depends on the SQLite library version, so compare query
results rather than database hashes across environments.

## Query results (actual output, matches the expected fixtures in LAB.md)

| Query | Columns | Rows |
|---|---|---|
| 01 inventory | finding, asset_id, scan_count | duplicate / DEMO-ASSET-001 / 2; missing / DEMO-ASSET-003 / 0; unexpected / DEMO-ASSET-999 / 1 |
| 02 overdue returns | request_id, asset_id, due_at, approved_exception_until, finding | 1 / DEMO-ASSET-001 / 2026-02-05 00:00:00 / NULL / overdue; 2 / DEMO-ASSET-002 / 2026-02-05 00:00:00 / 2026-02-15 00:00:00 / approved_exception |
| 03 recurring incidents | asset_id, category, incident_count | DEMO-ASSET-001 / vpn / 2 |
| 04 resolution | resolved_count, open_count, mean_elapsed_hours | 3 / 1 / 2.3333 |
| 05 preparation | workload, check_type, cohort, attempts, mean_minutes, pass_percent, serial_attempts_per_hour | after: 2 / 25.0 / 100.0 / 2.4; before: 2 / 45.0 / 50.0 / 1.33 |

## Not validated

- DB Browser for SQLite GUI procedure (not installed on this computer).
- A standalone VMware/Hyper-V virtual machine.
- Performance: test durations above are incidental unittest timings on a
  four-asset fixture and are not benchmarks.

# Reproducible SQLite lab

Read [the research README](README.md) for professional context and attribution. This lab implements its specification; it adds no professional performance claims. All identifiers, observations and measurements are invented fixtures. Timestamps use UTC, fixed-width `YYYY-MM-DD HH:MM:SS`. Scripts expect this format; the schema does not validate arbitrary timestamp strings. Six tables are intentionally retained; exercise scopes are explicit constants in the queries.

## DB Browser for SQLite

1. Obtain a stable DB Browser build from the official download links in the research README. Record your guest OS, DB Browser version and the result of `SELECT sqlite_version();`. The GUI procedure below is provided for reproduction and has not been GUI-tested in the assistant environment.
2. Choose **New Database**, save as `project06-demo.sqlite`, and cancel the initial table creation dialogue. Use a new empty file for every reset; these scripts deliberately reject existing tables or duplicate seeds.
3. In **Execute SQL**, open `schema.sql` and execute the complete script, including `PRAGMA foreign_keys = ON` before `BEGIN`. Then open and execute all of `seed.sql`. If the GUI reports an existing transaction, use **Write Changes**, then execute the script again on an empty database. Do not run only the selected CREATE or INSERT statements.
4. Use **Write Changes** after successful setup. Run `PRAGMA foreign_keys;` (expect 1), `PRAGMA integrity_check;` (expect `ok`) and `PRAGMA foreign_key_check;` (expect no rows). Enable foreign keys again on every new connection before a transaction; enforcement is connection-specific.
5. Open each `queries/01_...sql` through `05_...sql` in **Execute SQL** and run the complete query. Export each result to CSV using the result grid export function. Compare against the expected fixture outputs below and the actual assistant results in [execution evidence](evidence/assistant-linux-results.md).
6. Preserve your own sanitised CSVs/screenshots separately with actual UTC execution time and versions. The existing assistant evidence must not be relabelled as VM evidence.
7. If a script fails during its explicit transaction, execute `ROLLBACK;` before continuing. To reset, close the database and create a new empty file, then repeat steps 3–4. Never use this lab against a production database.

## Automated verification

### Windows with Ubuntu on WSL 2

If Ubuntu is stopped, the following PowerShell command starts it and runs the
standard-library [executor](run_lab.py). Python 3 with its SQLite module must
already be available inside Ubuntu. No Git or pip packages are required. The
initial download requires HTTPS access to raw.githubusercontent.com.

```powershell
wsl -d Ubuntu -- python3 -c "import urllib.request; exec(urllib.request.urlopen('https://raw.githubusercontent.com/marcuspaula-seceng/it-infrastructure-operations-portfolio/main/projects/06-itam-itsm-sqlite-research/run_lab.py', timeout=30).read())"
```

The command above loads the executor from `main`; for an immutable executor,
replace `main` in that URL with a reviewed commit SHA. The executor itself
always downloads the eight original lab inputs from commit
`0f8be5fd9b931770b176c1730729827c57c856ad` and verifies their SHA-256 hashes before
running them. It creates a new `project06-run-*` directory in the Ubuntu user's
home directory, preserving existing runs. A changed fixture needs an explicit
update to both the revision and hashes before this executor can use it.

The printed path contains the actual test log, a populated `project06-demo.sqlite`
database, five CSV result files and `run-results.json` with the execution time,
detected OS/kernel/distribution, Python and SQLite versions, test exit code,
input hashes, database hash and actual query output. CSV represents NULL as an
empty cell; JSON retains NULL explicitly. Test failures return a nonzero exit
code and produce no demonstration database. Download or hash failures abort
before tests run and may leave a partial run directory.

To run without downloading, from the repository root:

```sh
python projects/06-itam-itsm-sqlite-research/run_lab.py --source-dir projects/06-itam-itsm-sqlite-research
```

The JSON reports the environment where execution actually happened. Running
this executor in GitHub Actions or the assistant environment does not create
owner WSL evidence. It does not launch or validate DB Browser and does not
upload evidence. Use the DB Browser procedure above for GUI validation, enabling
foreign keys for that connection.

From the repository root with Python 3 and its standard-library SQLite module:

```sh
python projects/06-itam-itsm-sqlite-research/tests/test_lab.py
```

No pip dependencies or network access are needed. Eight tests cover exact fixture outputs, integrity, foreign-key enforcement, repeat seed rejection, invalid records, audit/window isolation, due-date boundaries, future completions, unresolved cases and equivalent preparation cohorts. Each test builds an isolated in-memory database; your saved database is untouched.

## Expected fixture outputs and decisions

| Query | Expected output | Interpretation |
|---|---|---|
| 01 inventory | duplicate 001 (2 scans), missing 003, unexpected 999 | Investigate scan scope and physical custody; missing is not proof of loss. Expected inventory is current fixture state, not historical reconstruction. |
| 02 returns | request 1 overdue; request 2 approved_exception | Follow up request 1. Request 3 is complete at cutoff; onboarding is excluded. Exception ending exactly at cutoff is treated as valid. |
| 03 recurrence | asset 001 / vpn / 2 | Investigate repeated incidents in February; no root-cause conclusion. |
| 04 resolution | 3 resolved, 1 open, 2.3333 mean elapsed hours | Calendar hours, February opening cohort, March 1 snapshot; not SLA compliance or business hours. |
| 05 preparation | before: n=2, 45 minutes, 50% pass, 1.33 attempts/h; after: n=2, 25 minutes, 100% pass, 2.4 attempts/h | Same synthetic workload and check; all attempts included. Small samples do not establish causality. |

For query 05, attempts/h is the reciprocal of mean serial attempt duration, not measured concurrent throughput or successful deployments/h. A `pass` fixture does not prove secure erasure. Cohort durations intentionally differ from the professional figures in the research README.

## Model boundaries

Assignments preserve custody history and allow at most one open assignment per asset. Audit scans deliberately allow unknown asset IDs and repeated scans. Requests retain approved exception end times. Lifecycle state is not automatically derived from assignments; a production system would need additional workflow controls. Date ordering checks depend on the documented format. This teaching database is not a CMDB, an employer application or a certified ITIL implementation.

## Evidence status

[Assistant execution evidence](evidence/assistant-linux-results.md) records tests actually performed and input hashes. Owner VM execution, DB Browser GUI screenshots and exported VM results remain pending. Existing owner validation of professional activities remains as documented in the research README.

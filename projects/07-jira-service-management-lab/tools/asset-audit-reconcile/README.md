# Assets audit reconcile

> **Lab tool, synthetic data.** Every asset tag, serial, person and location in
> this folder is invented for the Project 07 lab site. No employer data.

## What it does

`reconcile.py` checks a scan-based audit against the **IT Assets** schema in the
Project 07 Jira Service Management lab. It reads two CSV files:

| Input | Columns |
|---|---|
| Scan file (what the auditor scanned) | `asset_tag`, `scanned_location`, `scanned_at`, `scanned_by` |
| Assets export (the Laptop objects in Assets) | `Name`, `Status`, `Location`, `Assigned to` |

It then gives every asset tag one result:

| Result | Meaning |
|---|---|
| Found | Scanned, and the scan location matches the location in Assets |
| Found - wrong location | Scanned, but in a different location |
| Missing | In Assets, not retired, and not scanned |
| Unexpected | Scanned, but not in Assets |
| Retired - not expected | Status is *Retired* in Assets, so it is not counted as missing |

Rules:

- Tags and locations are compared without case and extra spaces, so
  ` lt-0004 ` matches `LT-0004`.
- A tag scanned more than once is reported **once**. The note says how many
  times it was scanned and where. The latest scan (`scanned_at`) gives the
  location.
- A retired laptop that was scanned is still *Retired - not expected*, with a
  note to check the disposal record.
- `scanned_at` must be an ISO 8601 date-time, for example `2026-11-12T10:05`.

The tool uses the Python standard library only (Python 3.11 or later) and has no
network access. It only reads the files it is given and writes the files you ask
for.

## How to run

From this folder:

```bash
python reconcile.py --scan sample-data/scan.csv --assets sample-data/assets-export.csv
```

Optional arguments:

| Argument | Effect |
|---|---|
| `--report PATH` | Also write the full result as CSV (one row per asset tag) |
| `--audit-date YYYY-MM-DD` | Also write an Assets import CSV (see below) |
| `--import-csv PATH` | Where to write the Assets import CSV (default `assets-import.csv`) |

Exit code is `0` after a successful run and `2` if an input file is missing or
not valid (missing column, bad date, the same tag twice in the Assets export).

Run the tests from the repository root:

```bash
python -m unittest discover -s projects/07-jira-service-management-lab/tools/asset-audit-reconcile/tests -v
```

## Sample output

The sample data reproduces the lab audit of 12 November 2026. The Assets
export is the register as it was before the audit, so `LT-0001` is still at
Dublin Office and `LT-0003` is still assigned (see the
[build log](../../build-log.md), Step 13):

```text
Assets audit reconciliation
===========================

Asset tag  Result                  Register location  Scanned location   Note
-----------------------------------------------------------------------------
LT-0001    Found - wrong location  Dublin Office      IT Storage Room
LT-0002    Found                   Remote (Ireland)   Remote (Ireland)
LT-0003    Found                   Dublin Office      Dublin Office
LT-0004    Found                   Dublin Office      Dublin Office
LT-0005    Found                   Dublin Office      Dublin Office      Duplicate scan (2 times; locations: Dublin Office)
LT-0006    Found - wrong location  IT Storage Room    Dublin Office
LT-0007    Missing                 IT Storage Room
LT-0008    Retired - not expected  IT Storage Room
LT-0099    Unexpected                                 IT Storage Room    Not in register

Summary
  Found                  : 4
  Found - wrong location : 2
  Missing                : 1
  Unexpected             : 1
  Retired - not expected : 1
  Duplicate scans        : 1
```

So 6 of the 7 active laptops were found (4 in the right place, 2 in the wrong
place), 1 is missing, the retired laptop is left out, and one scanned tag
(`LT-0099`) is not in Assets.

In the lab register, the retired `LT-0008` was also seen in the IT Storage Room
and recorded as Found, so the lab totals are 5 Found, 2 Found - wrong location
and 1 Missing. The tool keeps retired laptops in their own result so they are
never counted as Missing and their disposal record can be checked.

With `--audit-date 2026-11-12` the tool also writes:

```text
Name,Last audit date,Audit result
LT-0001,2026-11-12,Found - wrong location
LT-0002,2026-11-12,Found
LT-0003,2026-11-12,Found
LT-0004,2026-11-12,Found
LT-0005,2026-11-12,Found
LT-0006,2026-11-12,Found - wrong location
LT-0007,2026-11-12,Missing
```

Only the objects that were expected on the audit are in this file. *Unexpected*
tags have no object to update (an import keyed on `Name` would create a new
laptop), and retired laptops were not audited.

## How it maps to the Jira Assets audit procedure

The full procedure is in
[`procedures/scan-based-asset-audit.md`](../../procedures/scan-based-asset-audit.md).
The tool covers these steps:

| Procedure step | This tool |
|---|---|
| 1. Export the Laptop objects from IT Assets to CSV | `--assets` input |
| 2. Leave out laptops with the status Retired | Reported as *Retired - not expected*, never as Missing |
| 3–4. Scan each location and save the scan as CSV | `--scan` input |
| 5. Compare the scan with the export | Console report and `--report` CSV |
| 6. Set Audit result and Last audit date on each laptop | `--audit-date` writes the Assets import CSV |
| 7–9. Follow up wrong locations, Missing and Unexpected | The result and note columns show what to fix. In the lab, `LT-0007` became ticket `IT-14` |

To load the import file, use a CSV import in the IT Assets schema that maps
`Name` as the identifier, `Last audit date` and `Audit result` to the Laptop
attributes of the same name, and the date format `yyyy-MM-dd`.

## Related project

[Project 02 — Dublin IT Asset Management & Audit Automation](../../../02-asset-management-audit/README.md)
describes the scan-based audit process I contributed to in a real job, with a
generic reconciliation tool (matched, missing, unexpected, duplicate). This lab
tool applies the same principle to Jira Service Management Assets and adds what
an Assets audit needs on top: location check, retired status and an import file
to write the result back to the CMDB.

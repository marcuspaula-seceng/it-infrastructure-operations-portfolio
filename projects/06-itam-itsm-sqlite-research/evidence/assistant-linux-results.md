# Execution evidence — assistant execution environment

Executed UTC: 2026-10-13T01:40:24.749440+00:00
Environment: Linux 6.18.44
Python: 3.12.14
SQLite linked to Python: 3.53.1
Command: `python projects/06-itam-itsm-sqlite-research/tests/test_lab.py`
Exit status: 0

This is actual execution in the assistant's Linux environment using Python's sqlite3 module and fresh in-memory databases. It is not execution on Marcus's VM. DB Browser GUI, guest OS and Windows execution were not tested. No employer data was used.

```text
test_integrity (__main__.LabTests.test_integrity) ... ok
test_inventory (__main__.LabTests.test_inventory) ... ok
test_preparation (__main__.LabTests.test_preparation) ... ok
test_recurrence (__main__.LabTests.test_recurrence) ... ok
test_rejected_invalid_records (__main__.LabTests.test_rejected_invalid_records) ... ok
test_resolution (__main__.LabTests.test_resolution) ... ok
test_returns (__main__.LabTests.test_returns) ... ok
test_seed_is_not_silently_duplicated (__main__.LabTests.test_seed_is_not_silently_duplicated) ... ok

----------------------------------------------------------------------
Ran 8 tests in 0.006s

OK
```

## Actual query output from a fresh seeded database

### 01_inventory.sql

```json
[
  [
    "duplicate",
    "DEMO-ASSET-001",
    2
  ],
  [
    "missing",
    "DEMO-ASSET-003",
    0
  ],
  [
    "unexpected",
    "DEMO-ASSET-999",
    1
  ]
]
```

### 02_overdue_returns.sql

```json
[
  [
    1,
    "DEMO-ASSET-001",
    "2026-02-05 00:00:00",
    null,
    "overdue"
  ],
  [
    2,
    "DEMO-ASSET-002",
    "2026-02-05 00:00:00",
    "2026-02-15 00:00:00",
    "approved_exception"
  ]
]
```

### 03_recurring_incidents.sql

```json
[
  [
    "DEMO-ASSET-001",
    "vpn",
    2
  ]
]
```

### 04_resolution.sql

```json
[
  [
    3,
    1,
    2.3333
  ]
]
```

### 05_preparation_comparison.sql

```json
[
  [
    "DEMO-STANDARD-LAPTOP",
    "reimage",
    "after",
    2,
    25.0,
    100.0,
    2.4
  ],
  [
    "DEMO-STANDARD-LAPTOP",
    "reimage",
    "before",
    2,
    45.0,
    50.0,
    1.33
  ]
]
```

## SHA-256 of tested inputs

- `queries/01_inventory.sql`: `db3554b57eb1ce53762999958638508f1a0cdc71fc327c1a6193e1c67c05c27a`
- `queries/02_overdue_returns.sql`: `6d14f24059dc07c3b3ea525a8eb8a610f2b7c73f8e6d77b9986bf4d11ee076d4`
- `queries/03_recurring_incidents.sql`: `b11fad875809ffe098d88fcc2bc0e12dd0896fe9759a32e01651ece17481987f`
- `queries/04_resolution.sql`: `7815d8a9aa2526241db3546e7816d42bc5653a7487dd0dcaa1c3e003ca2ee7fa`
- `queries/05_preparation_comparison.sql`: `519a961c99fa62c01a7b0780be56c0984f4e9abe070289fbb9cdde333922a019`
- `schema.sql`: `4f1f3633089d9641a97656e3cd11ae70605d7862f75417342178093fd20b7d86`
- `seed.sql`: `09ed93ca3cf1c791dace84d13934e6e403fa06feda5303c8424c6e1cac391414`
- `tests/test_lab.py`: `8788f3e88874c975fc6f0d9ca4269163a5f80eb13ddda541cdca8c2927198281`

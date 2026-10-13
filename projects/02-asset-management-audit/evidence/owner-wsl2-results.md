# Owner execution — Ubuntu on WSL2 (Windows 11)

Executed on 13 October 2026 on the owner's own Windows 11 computer inside
**Ubuntu 24.04.4 LTS on WSL2** (Python 3.12.3), from a clone of `main`.
Not a CI run. All data is the synthetic sample shipped in `examples/`.

## Commands

```sh
python3 projects/02-asset-management-audit/src/asset_audit.py \
  --expected projects/02-asset-management-audit/examples/expected-assets.csv \
  --scanned  projects/02-asset-management-audit/examples/scanned-assets.csv
python3 -m unittest tests/test_asset_audit.py
```

## Results

| Step | Exit code | Result |
|---|---|---|
| Reconciliation run | 0 | Matched 9, Missing 1 (`SAMPLE-0007`), Unexpected 1 (`SAMPLE-9001`), Duplicate 1 (`SAMPLE-0003`) |
| Unit tests | 0 | 11 tests, OK |

A missing tag is a prompt to investigate scan scope and physical custody; it
is not proof that an asset is lost.

# Contributing

This is a personal professional portfolio. External feature contributions are
not generally expected, but corrections, clarity improvements and confidentiality
reports are welcome.

## Ground rules

- **Synthetic data only.** Never add real asset tags, hostnames, IP addresses,
  personal names, room names or credentials. See [CONFIDENTIALITY.md](CONFIDENTIALITY.md).
- **Standard library first.** The Python tools intentionally avoid third-party
  runtime dependencies. Keep them small and readable.
- **British English** for all prose.

## Local development

```bash
# Compile-check the Python sources
python -m py_compile projects/02-asset-management-audit/src/asset_audit.py \
                     projects/05-meeting-room-readiness/src/room_readiness_report.py

# Run the test suite (standard library)
python -m unittest discover -s tests -p "test_*.py" -v

# Or, if pytest is available
python -m pytest
```

## Commit style

Use concise, conventional commit messages, e.g. `docs: clarify project 02
contribution wording` or `fix: handle empty CSV in room readiness report`.

## Pull requests

Keep pull requests focused. Describe what changed and why, and confirm that no
confidential or non-synthetic data has been introduced.

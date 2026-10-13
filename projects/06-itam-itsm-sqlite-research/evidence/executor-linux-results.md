# Executor verification — assistant Linux environment

The new run_lab.py executor was exercised with local source inputs and with its default HTTPS download of the pinned original lab inputs. Both runs returned exit status 0 and ran all eight lab tests. The persistent database was reopened and its integrity and asset count checked; five CSVs and the JSON evidence were produced.

The metadata below is from the actual default-download run in the assistant environment. It is not owner WSL execution and is not DB Browser GUI evidence.

```json
{
  "executed_at_utc": "2026-10-13T02:28:43.457330+00:00",
  "environment": "Linux",
  "os": "Linux",
  "kernel": "6.18.44",
  "distribution": "Ubuntu 24.04.3 LTS",
  "python": "3.12.14",
  "sqlite_python_module": "3.53.1",
  "source_revision": "0f8be5fd9b931770b176c1730729827c57c856ad",
  "test_count": 8,
  "test_exit_code": 0,
  "integrity_check": [
    [
      "ok"
    ]
  ],
  "foreign_key_check": [],
  "foreign_keys_enabled_during_build": 1,
  "database_sha256": "3ea55a61b093ed6215a2c1a2dcd3653ace0eaf5ae2bf1bf8ff618074951343be",
  "db_browser_gui_tested": false
}
```

Executor SHA-256: `474069f0c17063a54ddd9dd8915f78dc0e81e740bb1fc07b3ab9d795fadb6610`

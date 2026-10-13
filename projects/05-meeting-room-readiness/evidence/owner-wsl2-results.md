# Owner execution — Ubuntu on WSL2 (Windows 11)

Executed on 13 October 2026 on the owner's own Windows 11 computer inside
**Ubuntu 24.04.4 LTS on WSL2** (Python 3.12.3), from a clone of `main`.
Not a CI run. All data is the synthetic 19-room sample shipped in `examples/`.

## Commands

```sh
python3 projects/05-meeting-room-readiness/src/room_readiness_report.py \
  --input projects/05-meeting-room-readiness/examples/synthetic-room-results.csv
python3 -m unittest tests/test_room_readiness_report.py
```

## Results

| Step | Exit code | Result |
|---|---|---|
| Readiness report | 0 | 19 rooms assessed: 14 pass, 3 warning, 2 fail; readiness rate 73.7% |
| Unit tests | 0 | 8 tests, OK |

The readiness rate describes the synthetic sample only; it is not a
measurement of any real meeting-room estate.

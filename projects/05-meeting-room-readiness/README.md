# Project 05 — Dublin Lark & Zoom Meeting Room Readiness Programme

## Executive summary

Performed operational readiness and validation checks across 19 documented
meeting rooms at a Dublin site, covering room schedulers and controllers,
displays, cameras, microphones, speakers, audio/video quality, HDMI connectivity
and wireless screen sharing. Validated Lark and Zoom functionality, including
switching between platforms, and helped maintain reliable meeting-room services
during the transition and coexistence of the two technologies.

## Operational challenge

Meeting rooms needed to work reliably across two conferencing platforms during a
transition period. Any weak link — a controller, display, camera, microphone,
HDMI path or wireless share — could disrupt a meeting, so rooms needed consistent,
documented validation.

## My contribution

- Performed operational readiness and validation checks across **19 documented
  meeting rooms** at a Dublin site.
- Tested room schedulers and controllers, displays and projectors, cameras,
  microphones, speakers, audio/video quality, meeting functionality, HDMI
  connectivity and wireless screen sharing.
- Validated Lark and Zoom functionality, including switching between platforms.
- Documented technical issues and completed fixes.
- Helped maintain reliable meeting-room services and supported the transition and
  coexistence of Lark and Zoom technologies.

## Approach

- Applied a consistent readiness checklist to every room.
- Tested each room on both Lark and Zoom, including switching between them.
- Recorded issues and the fixes applied, so results were comparable across rooms.

## Outcomes

- Readiness checks completed across **19 documented meeting rooms**.
- Reliable meeting-room services maintained through the Lark/Zoom transition and
  coexistence.

## Technologies and competencies

- Unified Communications
- Video Conferencing
- Audiovisual Systems
- Lark Suite
- Technical Support

## Public demonstration artefacts

- [`meeting-room-checklist.md`](meeting-room-checklist.md) — a generic readiness
  checklist.
- [`examples/synthetic-room-results.csv`](examples/synthetic-room-results.csv) —
  a synthetic dataset of exactly 19 fictional rooms (`Room-01` .. `Room-19`).
- [`src/room_readiness_report.py`](src/room_readiness_report.py) — a
  standard-library Python tool that reports pass, warning and fail totals plus a
  readiness rate.
- Unit tests:
  [`../../tests/test_room_readiness_report.py`](../../tests/test_room_readiness_report.py).

> These artefacts are **sanitised reference implementations**. Room identifiers
> are fictional; no real room names, floor locations or building names are used.

### Running the tool

```bash
python src/room_readiness_report.py --input examples/synthetic-room-results.csv
```

Expected result for the bundled synthetic data: 19 rooms — 14 pass, 3 warning,
2 fail, readiness rate 73.7%.

## Security and confidentiality considerations

- Room identifiers are fictional (`Room-01` .. `Room-19`).
- No real room names, floors, buildings or internal AV details are included.
- The tool has no network access and reads only the CSV it is given.

## Lessons learned

- A single, consistent checklist made results comparable across rooms and
  platforms.
- Explicitly testing the Lark/Zoom switch caught issues that single-platform
  testing would have missed.
- Distinguishing "warning" from "fail" helped prioritise fixes without blocking
  rooms that were still usable.

## Local execution evidence

See [owner execution on Ubuntu on WSL2](evidence/owner-wsl2-results.md) for the commands, exit codes and results of a run on the owner's own computer.


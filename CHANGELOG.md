# Changelog

All notable changes to this portfolio are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.1.0] - 2026-10-13

### Added

- Project 06 — IT Asset & Service Management: applied research with a
  reproducible SQLite lab (six-table schema, synthetic seed data, five
  exercise queries, evidence executor and 15 standard-library tests).
- Project 06: executor and custody-lifecycle tests (`tests/test_run_lab.py`) and
  owner execution evidence from Ubuntu on WSL2.

### Fixed

- Project 06: Windows clones failed input hash verification because Git for
  Windows converted files to CRLF; `.gitattributes` now keeps LF and the
  executor reports the cause.

## [1.0.0] - 2026-09-21

### Added

- Initial public release of the IT infrastructure and operations portfolio.
- Five sanitised case studies:
  - 01 — Endpoint Imaging Infrastructure Optimisation (Linux & Windows)
  - 02 — IT Asset Management & Audit Automation
  - 03 — Enterprise Virtualisation & Server Infrastructure Deployment
  - 04 — Multi-Site IT Asset Return & Redeployment Workflow
  - 05 — Meeting Room Readiness Programme (Lark & Zoom)
- Public demonstration artefacts using synthetic data only:
  - Read-only PowerShell endpoint readiness script.
  - Python asset reconciliation tool with unit tests.
  - Python meeting room readiness reporting tool with unit tests.
  - Mermaid architecture and lifecycle diagrams, checklists and a RACI template.
- Repository governance: README, LICENSE (MIT), SECURITY, CONTRIBUTING,
  CONFIDENTIALITY, and a GitHub Actions validation workflow.

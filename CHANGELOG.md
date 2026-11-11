# Changelog

All notable changes to this portfolio are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.3.0] - 2026-11-11

### Added

- Project 08 — Identity & Endpoint Lifecycle: case study of joiner, mover and
  leaver administration across Microsoft Entra ID, Microsoft 365, Intune and
  Jamf, with a lifecycle diagram, a joiner/leaver runbook, a troubleshooting
  guide and a read-only Microsoft Graph PowerShell snapshot script.
- CI: PowerShell syntax check now covers every script in the repository.

## [1.2.0] - 2026-11-11

### Added

- Project 07 — Jira Service Management Lab: an IT service desk built on a
  personal Jira Service Management Cloud site, with four request types and
  portal groups, a Dublin office hours SLA calendar, a Time to first response
  and a Time to resolution SLA, a JQL queue for unassigned work at SLA risk,
  onboarding and offboarding automation flows, and a manager-approval
  workflow for access requests.
- Project 07: end-to-end owner test evidence, including a failed approval run,
  its root cause from the automation audit log, and the fix.
- Project 07: step-by-step build log mapping each step to Jira Service
  Management training topics, with 19 screenshots of the configuration and
  test results.
- Project 07: Confluence knowledge base (IT Help Centre) linked to the portal,
  with three self-help articles and a portal search test.

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

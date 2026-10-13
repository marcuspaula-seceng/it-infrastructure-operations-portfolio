# IT Infrastructure & Operations Portfolio

A portfolio of sanitised infrastructure, endpoint management, asset lifecycle,
virtualisation and service delivery case studies drawn from enterprise EMEA IT
operations. Each case study describes real professional work at a high level and
is accompanied by **public demonstration artefacts** recreated later, using only
synthetic data, to illustrate the engineering principles applied.

---

## Confidentiality and sanitisation notice

This repository contains **no** confidential or employer-specific information.
It deliberately excludes employee and colleague names, internal hostnames,
domains, IP addresses, network topology, asset tags, serial numbers, ticket
references, screenshots, credentials and any proprietary material.

All scripts, checklists and datasets published here are **sanitised reference
implementations** created independently for portfolio purposes. They are **not**
the original enterprise production tooling and do not reproduce internal
conventions. Every sample dataset is entirely synthetic. See
[CONFIDENTIALITY.md](CONFIDENTIALITY.md) for the full policy.

---

## Project overview

| # | Case study | Focus | Demonstration artefacts |
|---|------------|-------|-------------------------|
| 01 | [Endpoint Imaging Infrastructure Optimisation](projects/01-endpoint-imaging-optimisation/README.md) | Linux & Windows endpoint imaging | Read-only PowerShell readiness script, validation checklist |
| 02 | [IT Asset Management & Audit Automation](projects/02-asset-management-audit/README.md) | Scan-based stock reconciliation | Python reconciliation tool, synthetic CSVs, unit tests |
| 03 | [Enterprise Virtualisation & Server Infrastructure](projects/03-virtualisation-infrastructure/README.md) | VMware vSphere / vCenter deployment | Mermaid architecture, deployment & validation checklists |
| 04 | [Multi-Site IT Asset Return & Redeployment Workflow](projects/04-asset-return-redeployment/README.md) | Asset lifecycle across three sites | Mermaid workflow, operational checklist, RACI template |
| 05 | [Meeting Room Readiness Programme (Lark & Zoom)](projects/05-meeting-room-readiness/README.md) | AV / UC readiness validation | Python reporting tool, synthetic 19-room CSV, unit tests |
| 06 | [IT Asset & Service Management — SQLite Research](projects/06-itam-itsm-sqlite-research/README.md) | ITAM, ITSM and ITIL practice mapping | Reproducible SQLite lab (six tables, five queries, 15 standard-library tests), evidence from Ubuntu on WSL2 |

---

## Technologies and operational disciplines demonstrated

- **Endpoint management & OS deployment** — Windows and Linux imaging, wipe and
  reimaging standardisation, image validation.
- **Asset management & IT audit** — scan-based reconciliation, inventory
  traceability, audit consistency.
- **Virtualisation & server infrastructure** — VMware vSphere and vCenter,
  storage, RAID, clustering, 10 Gb networking.
- **IT asset lifecycle & service delivery** — receipt, assessment, secure
  wiping, reimaging, quality checks, storage and redeployment.
- **Unified communications & audiovisual systems** — Lark and Zoom room
  readiness, displays, cameras, microphones, wireless screen sharing.
- **Tooling** — PowerShell, Python (standard library), Mermaid, CSV data models,
  GitHub Actions.

---

## Selected documented outcomes

These are documented operational outcomes from the professional work described,
not independently audited guarantees.

- Individual endpoint turnaround reduced from approximately **60 minutes to
  15 minutes**.
- Imaging network capacity upgraded from **100 Mbps to 1 Gbps**.
- Asset reconciliation process validated in an environment containing **more than
  5,000 assets**, contributing to **99% stock and audit visibility**.
- Asset return and redeployment workflow applied across **three sites**.
- Operational readiness checks completed across **19 documented meeting rooms**.

---

## Running the demonstration tools

The Python tools use the standard library only. Python 3.9 or later is
recommended.

### Project 02 — asset reconciliation

```bash
python projects/02-asset-management-audit/src/asset_audit.py \
  --expected projects/02-asset-management-audit/examples/expected-assets.csv \
  --scanned  projects/02-asset-management-audit/examples/scanned-assets.csv
```

### Project 05 — meeting room readiness report

```bash
python projects/05-meeting-room-readiness/src/room_readiness_report.py \
  --input projects/05-meeting-room-readiness/examples/synthetic-room-results.csv
```

### Project 01 — endpoint readiness (PowerShell, read-only)

```powershell
pwsh -File projects/01-endpoint-imaging-optimisation/Get-EndpointReadiness.ps1
```

The PowerShell script only reads system information; it makes no changes.

### Project 06 — ITAM/ITSM SQLite lab

A small, entirely synthetic SQLite database answers five asset and service
questions (inventory reconciliation, overdue returns, recurring incidents,
resolution time, preparation outcomes). No server or network port is used.
See the [lab guide](projects/06-itam-itsm-sqlite-research/LAB.md) for the data
model, Windows/WSL steps and expected results.

```bash
python projects/06-itam-itsm-sqlite-research/run_lab.py \
  --source-dir projects/06-itam-itsm-sqlite-research
python projects/06-itam-itsm-sqlite-research/tests/test_run_lab.py
```

---

## Running the tests

```bash
python -m pytest        # if pytest is installed
python -m unittest discover -s tests -p "test_*.py" -v   # standard library only
```

---

## Synthetic data statement

All datasets in this repository — asset inventories, scan results and meeting
room results — are **entirely synthetic** and were generated for demonstration.
They do not correspond to any real asset, device, room or organisation.

---

## Contact

- **GitHub:** https://github.com/marcuspaula-seceng
- **LinkedIn:** https://www.linkedin.com/in/marcuspaula/

---

## Licence

Released under the [MIT Licence](LICENSE).

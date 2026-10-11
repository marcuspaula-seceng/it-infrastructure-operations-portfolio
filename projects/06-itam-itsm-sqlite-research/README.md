# Project 06 — IT Asset & Service Management: Applied Research with SQLite

**Author:** Marcus Paula  
**Recorded:** 11 October 2026  
**Classification:** Applied research and hands-on study documentation  
**Validation:** Owner-confirmed professional experience and local validation; supporting VM artefacts are not attached to this document.

## Purpose

Translate enterprise IT operations experience into educational questions that other practitioners can explore with SQLite and DB Browser for SQLite. The focus is asset traceability, service delivery, incident analysis and continual improvement.

This is an independent learning project. It is not an employer system, an official ITIL course or evidence of organisational ITIL certification.

## Professional context and chronology

The professional context includes my work as an IT Support Engineer at TikTok Technology Ireland Ltd, from March 2023 to September 2026, supporting enterprise IT operations in an EMEA context.

My preceding experience at Hylas, January 2022 to February 2023, included Active Directory permissions, VPN, LAN/WAN and stock workflows. These roles provide context within the recent five-year career review; this document does not describe five years of employment at TikTok or assign EMEA-wide responsibility to every role.

My experience covers L2/L3 support, Windows/Linux endpoints, identity and access workflows, network troubleshooting, equipment preparation, asset audits and onboarding/offboarding.

## Experience translated into research questions

The mappings below are my educational interpretation of the work, not a claim that an employer formally implemented each ITIL practice.

| Professional activity | Related discipline | Question for a synthetic SQLite exercise |
|---|---|---|
| Inventory reconciliation and physical stock audits | IT asset management | Which expected assets are missing, duplicated or unexpected in a scan? |
| Laptop, monitor and phone assignment | IT asset management and service request management | Which assigned assets lack an accountable custodian? |
| Onboarding, offboarding and internal transfers | Service request management and asset lifecycle | Which device returns remain outstanding after a simulated departure? |
| Equipment return across multiple sites | Asset lifecycle and service delivery | Where is each item in the return, assessment and redeployment process? |
| Wipe, reimage and quality checks | Asset lifecycle and information security | Which devices have documented preparation and verification before reuse? |
| Imaging infrastructure improvement | Continual improvement and change enablement | How should comparable before/after turnaround and throughput be measured? |
| Windows/Linux, VPN and network support | Incident management | Which unresolved incidents require prioritisation by impact and urgency? |
| Recurring endpoint or connectivity failures | Problem management | Which patterns justify investigation rather than another isolated fix? |
| Meeting-room readiness | Monitoring and event management; service delivery | Which checks failed, and what service could be affected? |
| Runbooks and operational handovers | Knowledge management | Can another technician reproduce the procedure and understand the evidence? |

ITAM means IT Asset Management. ITSM means IT Service Management. ITIL provides guidance for managing services. These terms are related, not interchangeable. An asset register alone is not a complete CMDB: service configuration work also needs meaningful relationships and service context.

## Documented professional outcomes

These figures describe professional experience confirmed by the owner, not results produced by the proposed SQLite exercises or independent audit guarantees.

| Area | Outcome and attribution |
|---|---|
| Endpoint preparation | Approximately 60 to 15 minutes per device, as documented in this portfolio |
| Imaging network | Capacity upgraded from 100 Mbps to 1 Gbps |
| Imaging throughput | Approximately 10 to 50 devices per hour, as reported and confirmed by the owner; workload and measurement conditions are not reproduced here |
| Asset audit | Supported validation in an environment containing more than 5,000 assets, contributing to 99% stock and audit visibility |
| Process reuse | Dublin stock/audit workflow became an EMEA reference model |
| Return and redeployment | Workflow applied across three sites, as documented in this portfolio |
| Endpoint deployment | Approximately 400 endpoints, as reported and confirmed by the owner |
| Meeting-room readiness | 19 documented rooms in the existing readiness case study; this scope is not treated as the total number of room deployments |

The audit work was collaborative. I provided operational requirements and a spreadsheet model and contributed to workflow design, implementation and validation. A colleague developed the internal audit application. This study does not claim that application as my sole work.

For context and existing demonstration artefacts:
- [Endpoint imaging optimisation](../01-endpoint-imaging-optimisation/README.md)
- [Asset management and audit](../02-asset-management-audit/README.md)
- [Virtualisation and infrastructure](../03-virtualisation-infrastructure/README.md)
- [Asset return and redeployment](../04-asset-return-redeployment/README.md)
- [Meeting-room readiness](../05-meeting-room-readiness/README.md)

## Research method for the local VM

1. Define a service or asset question and the operational decision it supports.
2. Use an isolated local demonstration database containing entirely synthetic records.
3. Record the guest OS, SQLite and DB Browser versions actually used.
4. Document the schema, assumptions, query and expected output.
5. Execute the query and preserve sanitised evidence of the actual output.
6. Explain what the result supports, what it does not establish and the next action.
7. Make the exercise reproducible for a reader starting with an empty database.

On 11 October 2026, the owner confirmed that the discussed work had already been validated. This records the owner's confirmation; the assistant did not inspect the local VM. The guest OS, exact tool versions, execution logs, screenshots and database were not supplied in this GitHub update. No fabricated execution results are included.

## Proposed educational data model

This is the broader research specification. The executable reconciliation exercise below implements only an expected-inventory snapshot and audit scans; the other proposed tables remain future work.

| Table | Example fields | Purpose |
|---|---|---|
| assets | synthetic_asset_id, asset_type, site_code, lifecycle_state | Describe simulated equipment |
| assignments | asset_id, synthetic_person_id, assigned_at, returned_at | Track custody over time |
| audit_scans | scan_id, audit_id, asset_id, scanned_at | Preserve repeat scans for duplicate detection |
| incidents | incident_id, asset_id, category, priority, opened_at, resolved_at | Relate service interruption to assets |
| service_requests | request_id, request_type, asset_id, due_at, completed_at | Track fulfilment and returns |
| preparation_checks | check_id, asset_id, check_type, outcome, checked_at | Record simulated reuse checks |

Use invented identifiers such as DEMO-ASSET-001 and DEMO-PERSON-001, never transformed exports of employer records. Any timestamps must have a documented timezone.

## Hands-on exercise specification

| Exercise | Required evidence | Interpretation |
|---|---|---|
| Reconcile an inventory | Expected and scanned sets; missing, unexpected and duplicate results | An unscanned item requires investigation; it is not automatically lost |
| Identify overdue returns | Due date, return date and fixed reporting date | Separate overdue returns from approved exceptions |
| Review recurring incidents | Category, time window and incident count | Recurrence does not prove a common root cause |
| Measure resolution | Resolved incident durations and a separate open-incident count | State whether elapsed or business hours are used; do not silently drop open cases |
| Compare preparation outcomes | Equivalent workloads and before/after measurement definitions | Faster throughput alone does not prove secure erasure or better service quality |

The original professional metrics must never be presented as results obtained from these synthetic exercises. A successful SQL query does not establish that a real device was securely wiped.

## Installation and learning sources

Download DB Browser through its official website or official GitHub releases. Select a stable release appropriate to the operating system and architecture; do not assume the first release listed is stable. Record the version actually tested.

The installation article supplied during planning was titled **How to Install DB Browser for SQLite on Your Computer**. Its author, exact course title and canonical course URL were not supplied, so a complete course citation remains pending. The article and its images are not reproduced here. The owner's ITIL learning informed the reflection, but no particular course edition or certification is asserted.

## References and attribution

- [DB Browser for SQLite — official downloads](https://sqlitebrowser.org/dl/): installation source.
- [DB Browser for SQLite — official releases](https://github.com/sqlitebrowser/sqlitebrowser/releases): versions, release notes and published checksums.
- [DB Browser for SQLite — licence](https://github.com/sqlitebrowser/sqlitebrowser/blob/master/LICENSE): the upstream project identifies MPL 2.0 and GPL 3.0-or-later licensing; included dependencies have their own notices.
- [SQLite SQL language documentation](https://www.sqlite.org/lang.html): reference for future queries.
- [PeopleCert ITIL catalogue](https://www.peoplecert.org/browse-certifications/it-governance-and-service-management/ITIL-1): official framework and qualification reference.
- [PeopleCert Incident Management](https://www.peoplecert.org/browse-certifications/it-governance-and-service-management/ITIL-1/itil4-practices-incident-management-3684): incident management study reference.
- [PeopleCert Problem Management](https://www.peoplecert.org/browse-certifications/it-governance-and-service-management/ITIL-1/itil4-practices-problem-management-3688): problem management study reference.
- [PeopleCert Continual Improvement](https://www.peoplecert.org/browse-certifications/it-governance-and-service-management/ITIL-1/itil-4-practitioner-continual-improvement-3871): improvement study reference.

This original synthesis was prepared with AI assistance from the owner's confirmed experience and the existing portfolio. Third-party software, course material and frameworks remain attributable to their respective creators. The repository's licence applies to its own original material, not to those third-party works. No upstream code, course images or installer binaries are included in this study.

## Confidentiality and limitations

Follow the [repository confidentiality policy](../../CONFIDENTIALITY.md). No colleague names, production tickets, internal screenshots, serial numbers, credentials, network topology or proprietary code are published. Employer identification above supplies career context only and implies no endorsement.

This study includes a reproducible synthetic SQLite reconciliation exercise below. Sanitised VM execution evidence remains to be attached separately; the Python tests do not verify the owner's VM or professional outcomes.


## Reproduce the SQLite inventory exercise

Requirements: Python 3.9 or later with its standard-library `sqlite3` module. No
third-party packages, credentials, network calls or existing database are needed.
Run from the repository root:

```bash
python projects/06-itam-itsm-sqlite-research/src/reconcile_demo.py
python -m unittest discover -s tests -p "test_*.py" -v
```

The runner creates a fresh in-memory database and prints JSON. It does not write
or overwrite a database file. Repeated runs produce the same report.

- `sql/schema.sql`: one expected-inventory snapshot and repeatable audit scans
- `sql/seed.sql`: three invented expected assets and five invented scans across two audits
- `sql/reconcile.sql`: a parameterised query, scoped to `:audit_id`
- `src/reconcile_demo.py`: a standard-library runner and reusable query functions
- `../../tests/test_sqlite_reconciliation.py`: category, isolation, constraint and CLI tests

For `DEMO-AUDIT-001`, the fixture's expected summary is matched 2, missing 1,
unexpected 1 and duplicate 1. `DEMO-ASSET-002` is both matched and duplicated:
matched means present in both sets, while duplicate is a separate data-quality
flag. Category totals must not be added as though they were disjoint assets.
A scan from `DEMO-AUDIT-002` must not make an asset appear present in the first audit.

```bash
python projects/06-itam-itsm-sqlite-research/src/reconcile_demo.py --audit-id DEMO-AUDIT-002
```

Unknown audit IDs are treated as an empty scan set: all expected assets are
reported missing. This demonstration has no audit-session registry, historical
inventory snapshots, timestamp calculations, custody workflow or persistence.
Asset IDs are exact, case-sensitive identifiers; fixtures use uppercase IDs.
A missing result warrants investigation, not a conclusion that equipment is lost.

### Optional DB Browser walkthrough

Create a new, disposable database. In Execute SQL, run `schema.sql` and then
`seed.sql` once. Open `reconcile.sql` and, for this synthetic exercise only,
replace `:audit_id` with the SQL literal `'DEMO-AUDIT-001'` before executing it.
The Python runner instead binds the parameter safely. Do not concatenate real
user input into SQL. The schema intentionally refuses recreation rather than
dropping existing tables; start another disposable database to repeat the setup.

These are synthetic fixture expectations and automated Python/SQLite checks,
not evidence that DB Browser or the local VM has been inspected. No employer
records or professional performance measurements are included in the fixture.

# Project 02 — Dublin IT Asset Management & Audit Automation

## Executive summary

Contributed to the design and implementation of a scan-based asset-tag and
automated audit process for Dublin IT stock operations. The standardised
workflow improved asset identification, inventory traceability and audit
consistency, and became a reference model for improving IT stock and asset-audit
operations across EMEA.

## Operational challenge

Stock audits relied on repetitive manual checks that were slow and prone to human
error. Asset identification was inconsistent, and reconciling expected inventory
against what was physically present took significant effort with limited
traceability.

## My contribution

Contribution-accurate wording:

- Contributed to the design and implementation of an asset-tag scanning and
  automated audit process for Dublin IT stock operations.
- Introduced a standardised, scan-based workflow that improved asset
  identification, inventory traceability and audit consistency.
- Helped reduce repetitive manual checks, processing time and the risk of human
  error during stock audits.
- Supported validation across an environment containing **more than 5,000
  assets**, contributing to **99% stock and audit visibility**.
- Collaborated with asset management, audit and IT operations teams to test,
  refine and scale the process.
- Provided operational requirements and a spreadsheet model that contributed to
  an application **later developed by a colleague**.

> The internal application itself was developed by a colleague. This project
> does not claim sole authorship of that application; the demonstration tool
> below is an independent recreation of the reconciliation principle only.

## Approach

- Standardised how assets were identified and scanned so results were consistent
  between people and sessions.
- Reconciled a scanned set against an expected inventory and classified every
  item as matched, missing, unexpected or duplicate.
- Fed operational requirements and a spreadsheet model into a tool that a
  colleague subsequently developed.
- Iterated with asset management, audit and operations teams so the Dublin
  process could scale as an EMEA reference model.

## Outcomes

Documented operational outcomes (not independently audited guarantees):

- Process validated in an environment containing **more than 5,000 assets**.
- Contributed to **99% stock and audit visibility**.
- Reduced repetitive manual checks and the risk of human error.
- The Dublin process became a **reference model** across EMEA.

## Technologies and competencies

- IT Asset Management
- Process Automation
- IT Audit
- Inventory Management
- Microsoft Excel

## Public demonstration artefacts

- [`src/asset_audit.py`](src/asset_audit.py) — a small standard-library Python
  tool that reconciles an expected inventory against a scanned set and reports
  matched, missing, unexpected and duplicate assets.
- [`examples/expected-assets.csv`](examples/expected-assets.csv) and
  [`examples/scanned-assets.csv`](examples/scanned-assets.csv) — synthetic input
  data using a generic `SAMPLE-####` tag format.
- [`process-map.md`](process-map.md) — a generic view of the scan-based audit
  workflow.
- Unit tests: [`../../tests/test_asset_audit.py`](../../tests/test_asset_audit.py).

> These artefacts are **sanitised reference implementations**. The asset-tag
> format shown is deliberately generic and does not reproduce any internal
> convention.

### Running the tool

```bash
python src/asset_audit.py \
  --expected examples/expected-assets.csv \
  --scanned  examples/scanned-assets.csv
```

Expected result for the bundled synthetic data: 9 matched, 1 missing,
1 unexpected, 1 duplicate.

## Security and confidentiality considerations

- All asset tags are synthetic and use a generic placeholder format.
- No real asset tags, serial numbers, ticket references or internal conventions
  are included.
- The tool has no network access and reads only the CSV files it is given.

## Lessons learned

- Classifying "duplicate" separately from "unexpected" surfaced double-scanning
  early, which is a common source of audit noise.
- Normalising tags (trim and case-fold) before comparison removed a whole class
  of false mismatches.
- Providing a clear requirements and spreadsheet model made the hand-over to the
  colleague building the application far smoother.

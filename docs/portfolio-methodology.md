# Portfolio Methodology

This document explains how the portfolio is built, so a reader can judge exactly
what each case study claims and what each artefact is.

## Two clearly separated things

1. **Work completed in the professional environment.** Described at a high level
   in each case study under "My contribution", "Approach" and "Outcomes". These
   describe real work.

2. **Public demonstration artefacts recreated later.** The scripts, checklists,
   diagrams and datasets in each project. These were built independently for this
   portfolio, use synthetic data, and are labelled as **sanitised reference
   implementations**. They are **not** the original production tooling.

## Contribution-accurate language

Wording reflects the actual nature of each contribution. Where work was
supporting or collaborative, the text says "supported", "participated in" or
"collaborated", not "architected" or "single-handedly created". In particular,
the asset-audit application in Project 02 was developed by a colleague; this
portfolio claims only the requirements, spreadsheet model and an independent
demonstration tool.

## Figures

Only documented figures are used, and they are presented as documented
operational outcomes rather than independently audited guarantees:

- Endpoint turnaround approximately 60 minutes → 15 minutes.
- Imaging network 100 Mbps → 1 Gbps.
- More than 5,000 assets in the validation environment.
- Contribution to 99% stock and audit visibility.
- Workflow applied across three sites.
- Readiness checks across 19 meeting rooms.

No other quantitative claims are made.

## Confidentiality

Nothing in this repository identifies an employer, colleague, site, host,
network, room or asset. See [CONFIDENTIALITY.md](../CONFIDENTIALITY.md). All
datasets are synthetic.

## Validation

The Python tools are compile-checked and covered by unit tests; the PowerShell
script is read-only and syntax-checked. A GitHub Actions workflow runs the tests
on every push and pull request.

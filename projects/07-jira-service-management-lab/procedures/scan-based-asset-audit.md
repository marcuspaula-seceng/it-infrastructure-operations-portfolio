# Project 07 — Procedure: scan-based laptop audit in Assets

**Who this is for:** service desk agents and the asset owner in the IT team.
**What you can do after reading:** audit every laptop in Assets against what
is physically present, record the result and follow up every exception.

> Lab procedure. The laptops, locations and tickets are synthetic. The audit
> recorded on 12 Nov 2026 covered the 8 laptops in the lab schema.

---

## Before you start

- Edit access to the **IT Assets** schema (key `ITA`).
- The Laptop object type has three audit attributes: **Last audit date**,
  **Audit result** (Found / Found - wrong location / Missing) and
  **Condition**.
- A scanner or phone that reads asset tags, or a list to tick by hand.
- Optional: Python 3, to run the
  [reconcile tool](../tools/asset-audit-reconcile/).

---

## Steps

1. Export the Laptop objects from IT Assets to CSV. This is the expected list:
   asset tag, serial number, status and location.
2. Laptops with the status **Retired** are not expected in use. If you find
   one in storage, record it as Found and check its disposal record. In the
   lab, `LT-0008` is retired and was found in the IT Storage Room.
3. Go to each location and scan the asset tag of every laptop you find. Note
   the location of each scan.
4. Save the scan results as CSV.
5. Compare the scan with the export. Use the
   [reconcile tool](../tools/asset-audit-reconcile/) or compare by hand.
6. On each Laptop object, set **Audit result** and **Last audit date**.
7. For each **Found - wrong location**, decide which side is wrong:
   - The register is wrong: correct **Location** in Assets. Lab example:
     `LT-0001`, register corrected to IT Storage Room.
   - The laptop is in the wrong place: move it back. Lab example: `LT-0006`,
     moved back to storage.
8. For each **Missing**, raise a follow-up ticket with the asset tag in the
   summary. Lab example: `LT-0007`, ticket `IT-14`.
9. For each **Unexpected** result from the tool (a scanned tag that is not in
   Assets), check the tag and create or correct the object.
10. Record the totals. Lab audit of 12 Nov 2026 (8 laptops): 5 Found (one of
    them the retired `LT-0008`), 2 Found - wrong location, 1 Missing.

How to know the audit is complete: every laptop you scanned has today's
**Last audit date**, and every Missing laptop has a follow-up ticket.

---

## Results and actions

| Result | Meaning | Action |
|---|---|---|
| Found | Scanned where Assets says it is | Set Audit result and Last audit date |
| Found - wrong location | Scanned, but in a different location | Correct the register or move the laptop |
| Missing | In Assets, not scanned | Raise a follow-up ticket |
| Unexpected (tool only) | Scanned, not in Assets | Check the tag; create or correct the object |

---

## How this maps to real work and to the tool

| Part | Real work ([Project 02](../../02-asset-management-audit/README.md)) | This lab (JSM Assets) | Reconcile tool ([`tools/asset-audit-reconcile/`](../tools/asset-audit-reconcile/)) |
|---|---|---|---|
| Scale | More than 5,000 assets; contributed to 99% stock and audit visibility | 8 synthetic laptops | Synthetic CSV files |
| Expected list | Expected inventory | Export of Laptop objects | Assets export CSV |
| Scan | Standardised asset-tag scanning | Scan of each laptop's asset tag | Scan CSV |
| Results | Matched, missing, unexpected, duplicate | Found, Found - wrong location, Missing | Found, Found - wrong location, Missing, Unexpected |
| Record of the result | Spreadsheet model; an application later developed by a colleague | Audit result and Last audit date on each object; follow-up ticket | Tool output, then recorded in Assets |

The real work was done at TikTok in Dublin IT stock operations, as described in
Project 02. This lab recreates the principle in Jira Service Management Assets
with synthetic data only. It is not a copy of any internal tool or process.

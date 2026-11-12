# Project 07 — Agent runbook

**Who this is for:** service desk agents working the `IT` and `ITSM` spaces.
**What you can do after reading:** triage new work, run the first 60 minutes of
a major incident, hand an incident over to problem management, run a scan-based
laptop audit and process a laptop return.

> Lab runbook. Every work item, person, site and laptop is synthetic. The steps
> follow what was configured and tested in this lab
> ([build log](../build-log.md), [test results](../evidence/owner-cloud-results.md)).

---

## Before you start

- Agent access to the **IT** and **IT Operations (ITSM)** spaces.
- Access to the **IT Assets** schema (key `ITA`) to view and edit Laptop
  objects.
- Access to the **IT Help Centre** knowledge base.

---

## 1. Triage

Work the queue **SLA at risk – unassigned** first. It lists work nobody owns
that is within two working hours of breaching first response, most urgent
first.

1. Open the oldest item in the queue.
2. Assign it to yourself.
3. Check the request type matches the problem. Employee requests live in
   `IT`; incidents, problems and changes live in `ITSM`.
4. Set the priority. `Highest` and `High` get the tighter SLA targets.
5. Send the first public reply. This stops the *Time to first response* clock.
6. If you need information from the requester, set the status to **Pending**.
   SLA clocks pause while the request is pending.

SLA targets in the `IT` space (Dublin office hours, Monday–Friday 09:00–17:00):

| SLA | Highest / High | Everything else |
|---|---|---|
| Time to first response | 1h | 4h |
| Time to resolution | 8h | 24h |

---

## 2. Major incident: the first 60 minutes

Use this when many people lose the same service, for example the office has
no internet and nobody can connect to the VPN. The timings come from the lab
incident `ITSM-2`.

**Minute 0–10: declare it**

1. Pick one incident as the major incident. Keep the other reports of the same
   outage open; you complete them together at the end. In the lab, `ITSM-2` was
   the major incident and `ITSM-1` and `ITSM-3` were the other reports.
2. Set priority **Highest**.
3. Set impact **Extensive / Widespread**.
4. Turn on the **Major incident** flag.
5. Check the SLAs: in the lab, first response within 2h and resolution within
   4h.

**Minute 10–30: find the fault and escalate**

1. Check where the service breaks. In `ITSM-2` the ISP line was down at the
   router (WAN down, no sync).
2. Raise a ticket with the supplier and attach the evidence.
3. Inform the wider IT team.
4. Write each finding as an **internal note** with the time, for example
   *09:20 ISP line down at the router, ISP ticket raised with evidence, Group IT
   informed*.

**Minute 30–60: restore and confirm**

1. When the supplier reports a fix, test the service yourself: WAN, VPN and a
   test sign-in to Microsoft 365.
2. Write the result as an internal note with the time.
3. Send one **public reply** to users: what was restored, when, the cause in
   one line, and the problem reference. Example from `ITSM-2`: *Service
   restored at 09:50. ISP fault on their side. Root cause follow-up in problem
   ITSM-5.*
4. Complete the major incident and the linked incidents.

Keep internal notes and public replies separate. Users need the status;
IT needs the evidence.

---

## 3. Hand-off to problem management

Raise a problem when the same fault comes back or the root cause is still
open after the incident is closed.

1. Raise a problem in the `ITSM` space, for example `ITSM-5` *Recurring loss of
   office internet (test)*.
2. Set the priority. `ITSM-5` is **High**.
3. Write the root cause as far as it is known. `ITSM-5`: the ISP line has a
   recurring fault and the office has only one internet line.
4. Write the workaround users can follow now. `ITSM-5`: mobile hotspot for
   urgent work; cloud apps still work from outside the office.
5. Link every incident the problem **causes**.
6. Link any related change with **relates to**.
7. Reference the problem key in the public reply on the major incident.

---

## 4. Scan-based laptop audit

Full procedure, with the comparison to real work and the reconcile tool:
[`procedures/scan-based-asset-audit.md`](../procedures/scan-based-asset-audit.md).

Short version:

1. Export the Laptop objects from IT Assets.
2. Scan the asset tag of every laptop at each location.
3. Compare the scan with the export, by hand or with the
   [reconcile tool](../tools/asset-audit-reconcile/).
4. On each Laptop object, set **Audit result** and **Last audit date**.
5. For **Found - wrong location**, either correct the location in Assets or
   move the laptop back.
6. For **Missing**, raise a follow-up ticket and put the asset tag in the
   summary.

---

## 5. Laptop return on a Leaver request

The Leaver request creates sub-task **Collect laptop, wipe device and update
Assets**. In the lab: Leaver `IT-6`, sub-task `IT-9`, laptop `LT-0003`.

1. Receive the laptop and charger from the leaver, or the courier parcel.
2. Check that the asset tag matches the laptop in the Leaver request.
3. Check the condition of the laptop.
4. Confirm the return in the Leaver request.
5. Wipe and check the laptop.
6. In Assets, open the Laptop object and set:

   | Attribute | Value |
   |---|---|
   | Assigned to | None |
   | Status | In stock |
   | Location | IT Storage Room |
   | Condition | The condition you found, for example Good |
   | Audit result | Found |

7. Set the sub-task to done.
8. Open the object history and check that every change is listed.

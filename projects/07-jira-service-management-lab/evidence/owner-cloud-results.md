# Project 07 — Owner test results (Jira Service Management Cloud)

**Date:** 11 November 2026
**Environment:** personal Jira Service Management Cloud site, Free plan

## Test: onboarding automation end to end

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Raise a **New starter (onboarding)** request through the customer portal with synthetic data (Jane Doe, role QA Tester, team Games QA) | Request created in the IT space | Work item `IT-1` created, request type New starter (onboarding), status To Do |
| 2 | Automation flow evaluates the new work item | JQL condition matches the request type | Flow ran on creation |
| 3 | Check sub-tasks on `IT-1` | Four sub-tasks with the configured summaries | `IT-2` Create Microsoft 365 account and assign licence; `IT-3` Add user to Entra ID security groups; `IT-4` Prepare and enrol laptop (Intune/Jamf) and record in Assets; `IT-5` Grant application access and send welcome email — all Open, Medium, unassigned |

**Result:** pass. One portal request produced the four expected onboarding
sub-tasks with no manual steps.

## Configuration checks

| Item | Check | Result |
|---|---|---|
| Request types | Four custom request types visible in the portal under two portal groups | Pass |
| SLA calendar | Dublin office hours saved with Europe/Dublin time zone and two annual holidays | Pass |
| SLAs | Time to first response (1h / 4h) and Time to resolution (8h / 24h) saved on Dublin office hours | Pass |
| Queue | SLA at risk – unassigned created; JQL accepted and SLA column added | Pass |
| Automation | JQL condition validated in the flow builder before saving; flow enabled | Pass |

All data used in these tests is synthetic.

## Test: offboarding automation end to end

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Raise a **Leaver (offboarding)** request in the portal with synthetic data (John Smith, Producer, Dublin office) | Request created | Work item `IT-6` created |
| 2 | Check sub-tasks on `IT-6` | Four offboarding sub-tasks | `IT-7` Block sign-in and revoke sessions in Entra ID; `IT-8` Convert mailbox to shared and remove licence; `IT-9` Collect laptop, wipe device and update Assets; `IT-10` Remove application access and group memberships |

**Result:** pass.

## Test: access request approval

| Run | Action | Observed | Result |
|---|---|---|---|
| 1 | Raise an **Access request** (`IT-11`) | Approvers set, then the flow failed: "Unable to transition your issue to the selected status" — no To Do → In Review transition in the workflow | Fail — root cause found in the automation audit log |
| Fix | Flow changed to transition To Do → In Progress → In Review | Flow saved | — |
| 2 | Raise a second **Access request** (`IT-12`) | Status **In Review**, "Waiting for 1 approval"; SLA timers running on Dublin office hours; the requester listed under *excluded approvers*, so they cannot approve their own request | Pass |

## SLA check

`IT-11` and `IT-12` show both SLAs on the Dublin office hours calendar:
Time to first response (4h target) and Time to resolution (24h target), with
due times calculated in working hours rather than elapsed time.

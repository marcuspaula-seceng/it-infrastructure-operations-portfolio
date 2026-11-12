# Project 07 — Owner test results (Jira Service Management Cloud)

**Date:** 11 November 2026 (Assets audit: 12 November 2026)
**Environment:** personal Jira Service Management Cloud site, Free plan, then
a 30-day Premium trial for Assets and the later tests

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

## Test: knowledge base self-service

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Link the IT Help Centre Confluence space as the external knowledge base | Space linked | "Knowledge source linked successfully"; articles listed under Knowledge Base |
| 2 | Search the customer portal for *password* | Matching article shown before a request is raised | *How to reset your password* shown under **Self-help resources** with a content preview |

**Result:** pass.

## Test: Assets laptop linked to a request

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Check `LT-0001` in the IT Assets schema before the test | Status In use | In use, assigned to Jane Doe, MacBook Pro 14 |
| 2 | Raise a **Laptop or device issue** (`IT-13`) in the portal and pick `LT-0001` in *Which laptop?* | Picker finds the laptop by asset tag | One result, `LT-0001` with serial `SYN-C02X1001` |
| 3 | Open `IT-13` as an agent | Laptop shown with its details | Serial number, model, assigned to and status shown on the work item |
| 4 | Check the laptop status after the flow ran | In repair | `LT-0001` status **In repair** (read back from Assets and shown on `IT-13`) |

**Result:** pass. All data is synthetic.

## Test: major incident `ITSM-2`

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Raise `ITSM-1`, `ITSM-3` and `ITSM-2` in the IT Operations (ITSM) space | Three incidents created | Created, each ending in "(test)" |
| 2 | Set `ITSM-2` as the major incident | Priority Highest, impact Extensive / Widespread, Major incident flag on | All three values set |
| 3 | Check SLAs on `ITSM-2` | First response and resolution targets shown | Time to first response within 2h; time to resolution within 4h |
| 4 | Add the timeline in comments | Internal notes for IT, one public reply for users | 09:20 and 09:50 internal notes; public reply "Service restored at 09:50. ISP fault on their side. Root cause follow-up in problem ITSM-5." |
| 5 | Complete the incidents | `ITSM-1`, `ITSM-2`, `ITSM-3` completed | Completed |

**Result:** pass. Screenshots 25 and 26.

## Test: problem `ITSM-5`

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Raise problem `ITSM-5` | Problem created | Priority High, status Under review |
| 2 | Record root cause and workaround | Both fields filled | Root cause: recurring ISP line fault with only one office internet line. Workaround: mobile hotspot; cloud apps work from outside the office |
| 3 | Link related work items | Incidents and change linked | Causes `ITSM-1`, `ITSM-2`, `ITSM-3`; relates to `ITSM-4` |

**Result:** pass. Screenshot 27.

## Test: normal change `ITSM-4`

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Raise `ITSM-4` with the request type *Upgrade or change a managed system* | Change created | Change type Normal, risk Medium, reason Upgrade |
| 2 | Fill plan, rollback and communication | All three filled | Back up config, update Saturday 08:00–09:00, test internet/VPN/Wi-Fi; restore previous firmware and config; notify staff two days before and when complete |
| 3 | Move the change through the workflow | Each status in order | Peer review → Planning → Awaiting CAB approval → Awaiting implementation → Implementing → Resolved (from the history) |
| 4 | Record dates | Planned and actual dates on the change | Planned start 21 Nov 2026 08:00; actual start 08:05; actual end 08:40 |
| 5 | Check the approval SLA | Time to approve normal change (40h) met | Met |

**Result:** pass. Screenshots 28 and 29.

## Test: scan-based laptop audit

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Add Last audit date, Audit result and Condition to the Laptop object type | Attributes available on all laptops | Added |
| 2 | Record the audit of 12 Nov 2026 for the 8 laptops | One Audit result per laptop | 5 Found (including the retired `LT-0008`), 2 Found - wrong location, 1 Missing |
| 3 | Fix the two wrong locations | Register or laptop corrected | `LT-0001`: register corrected to IT Storage Room. `LT-0006`: laptop moved back to storage |
| 4 | Follow up the missing laptop | Ticket raised | `LT-0007` → `IT-14` |

**Result:** pass. Screenshot 30.

## Test: laptop return on the Leaver request

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Complete sub-task `IT-9` on the Leaver request `IT-6` | Sub-task done | Done |
| 2 | Update `LT-0003` in Assets | Laptop back in stock, no owner | Assigned to John Smith → None; Status In use → In stock; Location Dublin Office → IT Storage Room; Condition Good; Audit result Found |
| 3 | Check the object history | Each change listed | All changes shown in the `LT-0003` history |

**Result:** pass. Screenshot 31.

## Test: knowledge base articles for assets

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Publish *How to find your laptop asset tag and report a problem* in the IT Help Centre | Article in the knowledge base | Published |
| 2 | Publish *How to return your laptop when you leave* | Article in the knowledge base | Published: Leaver request by the manager, steps before and on the last day, what IT does after the return |

**Result:** pass. Screenshot 32.

## Test: country queues and pre-assignment

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Raise `IT-15` for Ireland, `IT-16` for United Kingdom, `IT-17` for Netherlands | Each in its country queue | Each queue shows 1 work item |
| 2 | Check the assignee | Assigned by the flow (balanced workload) | All three assigned to the engineer |

**Result:** pass. Screenshots 35-36.

## Test: laptop back to In use

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Resolve `IT-13` (laptop `LT-0001`, status In repair) | Flow runs | Run |
| 2 | Check `LT-0001` in Assets | Status In use | In repair → In use |

**Result:** pass. Screenshot 37.

## Test: SaaS licence / external guest access request

| Step | Action | Expected | Observed |
|---|---|---|---|
| 1 | Raise `IT-18` with the new request type | Goes into approval | In Review, waiting for 1 approval |
| 2 | Check approvers | Requester cannot approve | Requester listed under excluded approvers |

**Result:** pass. Screenshot 38.
All data in these tests is synthetic.

# Project 07 — Configuration

Configuration of the personal Jira Service Management Cloud lab, as built in
November 2026. Atlassian now calls projects **spaces**, automation rules
**flows** and issues **work items**; this document uses the current terms.

## 1. Service space

| Setting | Value |
|---|---|
| Space type | Jira Service Management — IT service space |
| Space key | `IT` |
| Workflows in use | Default ESM workflow (requests and incidents), Simple ESM workflow (questions, email) |

## 2. Request types and portal groups

| Request type | Created from template | Work type | Portal group |
|---|---|---|---|
| New starter (onboarding) | Set up new user accounts and systems access | Submit a request or incident | Accounts & access |
| Leaver (offboarding) | Offboard an employee | Submit a request or incident | Accounts & access |
| Access request (apps & admin rights) | Request admin access | Access request (own approval workflow) | Accounts & access |
| Laptop or device issue | Report broken hardware | Submit a request or incident | Hardware & devices |

Request form fields (New starter): summary, account and access requirements,
employee first name, last name, employee ID, company email address, role and
team.

Design note: request types are named in the employee's words ("Laptop or device
issue") and grouped by what the employee needs, so the portal stays short and
the right form is chosen first time.

## 3. SLA calendar

| Setting | Value |
|---|---|
| Name | Dublin office hours |
| Time zone | (GMT+00:00) Dublin |
| Working week | Monday–Friday, 09:00–17:00 |
| Holidays | Christmas Day (25 Dec, annual), St Patrick's Day (17 Mar, annual) |

The site default time zone differed from Dublin, so the calendar sets the time
zone explicitly; otherwise SLA clocks would run on the wrong working hours.

## 4. SLA — Time to first response

Goals are evaluated top to bottom; the first matching JQL wins.

| Applies to (JQL) | Calendar | Target |
|---|---|---|
| `priority in (Highest, High)` | Dublin office hours | 1h |
| All remaining work items | Dublin office hours | 4h |

| Condition | Value |
|---|---|
| Start counting | Work item created |
| Pause counting | Status: Pending (waiting on the customer) |
| Stop counting | Comment: for customers, or Resolution: set |

## 4b. SLA — Time to resolution

| Applies to (JQL) | Calendar | Target |
|---|---|---|
| `priority in (Highest, High)` | Dublin office hours | 8h |
| All remaining work items | Dublin office hours | 24h |

| Condition | Value |
|---|---|
| Start counting | Work item created |
| Pause counting | Status: Pending |
| Stop counting | Resolution: set |

## 5. Queue — SLA at risk – unassigned

```sql
resolution = Unresolved
AND assignee IS EMPTY
AND "Time to first response" < remaining("2h")
ORDER BY "Time to first response" ASC
```

Columns: work type, key, summary, reporter, assignee, status, created and
Time to first response. The queue shows only work nobody owns yet that is
within two working hours of breaching, most urgent first.

## 6. Automation flow — onboarding sub-tasks

| Step | Configuration |
|---|---|
| Name | Onboarding - create sub-tasks for new starter |
| Trigger | Work item created |
| Condition | JQL: `"Request Type" = "New starter (onboarding)"` |
| Action | Create sub-tasks (4) |

Sub-tasks created:

1. Create Microsoft 365 account and assign licence
2. Add user to Entra ID security groups
3. Prepare and enrol laptop (Intune/Jamf) and record in Assets
4. Grant application access and send welcome email

```mermaid
flowchart LR
    A[Employee or HR raises<br/>New starter request<br/>in the portal] --> B{Request type =<br/>New starter?}
    B -- no --> X[Flow stops]
    B -- yes --> C[Create 4 sub-tasks]
    C --> D[M365 account<br/>and licence]
    C --> E[Entra ID<br/>security groups]
    C --> F[Laptop enrolment<br/>Intune/Jamf + Assets]
    C --> G[App access and<br/>welcome email]
```

## 6b. Automation flow — offboarding sub-tasks

| Step | Configuration |
|---|---|
| Name | Offboarding - create sub-tasks for leaver |
| Trigger | Work item created |
| Condition | JQL: `"Request Type" = "Leaver (offboarding)"` |
| Action | Create sub-tasks (4) |

Sub-tasks created:

1. Block sign-in and revoke sessions in Entra ID
2. Convert mailbox to shared and remove licence
3. Collect laptop, wipe device and update Assets
4. Remove application access and group memberships

## 6c. Access request approval

The Access request type uses its own workflow, **IT: Access request with
approval**, created from the "Simple (with approval)" template so the other
request types keep their workflow unchanged.

```mermaid
flowchart LR
    A[To Do] --> B[In Progress]
    B --> C{In Review<br/>approval}
    C -- approved --> D[Approved] --> E[Done]
    C -- declined / needs info --> F[Awaiting information]
    A --> F
```

| Item | Configuration |
|---|---|
| Approval status | In Review — 1 person from the **Approvers** field must approve |
| Flow name | Access request - send to manager approval |
| Trigger | Work item created |
| Condition | JQL: `"Request Type" = "Access request (apps & admin rights)"` |
| Actions | Edit work item: set Approvers → Transition to In Progress → Transition to In Review |

The workflow has no direct To Do → In Review transition, so the flow moves the
work item through In Progress first. The first test run failed on exactly this
point; the automation audit log showed the failed transition and the flow was
corrected (see the evidence file).

## 6d. Knowledge base

| Setting | Value |
|---|---|
| Confluence plan | Free |
| Space | IT Help Centre (knowledge base purpose) |
| Link type | External knowledge base (visible to customers in the portal) |
| Articles | How to reset your password · How to connect to the VPN when working remotely · My laptop is slow - first steps · How to find your laptop asset tag and report a problem · How to return your laptop when you leave |

## 7. Next steps (not yet configured)

- Import laptops into Assets from a device-management tool (the schema and its
  link to the Laptop or device issue form are done; see section 8).

## 8. Assets (CMDB)

Schema **IT Assets** (key `ITA`). All objects are synthetic.

| Object type | Attributes | Objects |
|---|---|---|
| Location | Name, City | 3 |
| Employee | Name, Email, Department, Location (reference) | 5 |
| Model | Name, Manufacturer, Operating system (macOS / Windows) | 4 |
| Laptop | Name (asset tag), Serial number (unique), Model (reference), Assigned to (reference), Location (reference), Status (In use / In stock / In repair / Retired), Encryption (FileVault / BitLocker), Managed by, Purchase date, Warranty end | 8 |

### Assets field

| Setting | Value |
|---|---|
| Field | Laptop (`customfield_10106`), Assets objects |
| Schema | IT Assets |
| Filter scope (AQL) | `objectType = "Laptop" AND Status != "Retired"` |
| Search by | Name, Serial number |
| Shown on work item | Serial number, Model, Assigned to, Status |
| Shown in portal | Serial number, Model |
| Request form | Laptop or device issue: required, shown as *Which laptop?* |

### Flow — Laptop issue: set asset status to In repair

| Step | Configuration |
|---|---|
| Trigger | Work item created |
| Condition | JQL: `"Request Type" = "Laptop or device issue" AND Laptop is not EMPTY` |
| Branch | AQL on IT Assets: `objectType = "Laptop" AND Key IN ({{issue.customfield_10106.Key}})` |
| Action | Edit object: Status = In repair |

### Audit and lifecycle attributes (added for Step 13)

| Attribute | Values |
|---|---|
| Last audit date | Date of the last physical check |
| Audit result | Found / Found - wrong location / Missing |
| Condition | Condition of the laptop, for example Good |

## 9. IT Operations (ITSM) space

A second service space for incidents, problems and changes, kept apart from the
employee request space `IT`. All work items are synthetic and end in "(test)".

| Setting | Value |
|---|---|
| Space name | IT Operations (ITSM) |
| Space key | `ITSM` |
| Components | Office Network, VPN Server |
| Major incident fields used | Priority Highest, Impact Extensive / Widespread, Major incident flag |
| SLAs seen on the major incident `ITSM-2` | Time to first response 2h, Time to resolution 4h |
| SLA on normal changes | Time to approve normal change: 40h |

Work items:

| Key | Type | Summary | Links |
|---|---|---|---|
| `ITSM-1` | Incident | Office internet dropped for 10 minutes (test) | Caused by `ITSM-5` |
| `ITSM-2` | Incident (major) | Office has no internet and users cannot connect to the VPN (test) | Caused by `ITSM-5` |
| `ITSM-3` | Incident | Cannot sign in to Microsoft 365 from the office (test) | Caused by `ITSM-5` |
| `ITSM-4` | Change | Firmware update on the office firewall (test) | Relates to `ITSM-5` |
| `ITSM-5` | Problem | Recurring loss of office internet (test) | Causes `ITSM-1/2/3`; relates to `ITSM-4` |

## 10. Change workflow and CAB approval

Change `ITSM-4` was raised with the request type **Upgrade or change a managed
system**.

| Field | Value |
|---|---|
| Change type | Normal |
| Risk | Medium |
| Change reason | Upgrade |
| Implementation plan | Back up the configuration; update out of hours (Saturday 08:00–09:00); test internet, VPN and Wi-Fi |
| Rollback plan | Restore the previous firmware and the saved configuration |
| Communication | Notify staff two days before and when complete |
| Planned start | 21 Nov 2026 08:00 |
| Actual start / end | 08:05 / 08:40 |

```mermaid
flowchart LR
    A[Peer review] --> B[Planning]
    B --> C{Awaiting<br/>CAB approval}
    C -- approved --> D[Awaiting<br/>implementation]
    D --> E[Implementing]
    E --> F[Resolved]
```

The diagram shows the path `ITSM-4` took, read from its history. It does not
show every transition in the workflow.

## 11. Scan-based audit procedure

The audit compares what is physically found with the **Laptop** objects in
Assets and records the result on each object. Full steps:
[`procedures/scan-based-asset-audit.md`](procedures/scan-based-asset-audit.md).

| Result | Meaning | Action recorded in the lab |
|---|---|---|
| Found | Laptop found where Assets says it is | Set Audit result and Last audit date |
| Found - wrong location | Laptop found somewhere else | Correct the register (`LT-0001`) or move the laptop back (`LT-0006`) |
| Missing | Laptop not found | Raise a follow-up ticket (`LT-0007` → `IT-14`) |

Audit of 12 Nov 2026 on 8 synthetic laptops: 5 Found (one of them the retired `LT-0008`,
seen in the IT Storage Room), 2 Found - wrong location, 1 Missing.

The reconcile tool in
[`tools/asset-audit-reconcile/`](tools/asset-audit-reconcile/) does the
comparison from a scan CSV and an Assets export, and adds a fourth result,
**Unexpected**, for a scanned tag that is not in Assets.

## 12. Reports and dashboard

| Item | Content |
|---|---|
| Custom report | SLA: first response met vs breached (series Met, Breached) |
| Dashboard | IT service desk overview (lab): created vs resolved chart; pie chart of work items by work type |
| Result seen | Report: 0 Met, 12 Breached (test requests never got a first public reply). Dashboard: 14 created, 0 resolved in 30 days |

## 13. Organizations, country queues and new flows

| Item | Content |
|---|---|
| Organizations | Ireland, United Kingdom, Netherlands (SiteA, SiteB, SiteC) |
| Queues | Ireland - Team IE; United Kingdom - Team UK; Netherlands - Team NL (`resolution = Unresolved AND Organizations = "<country>" ORDER BY created ASC`) |
| Flow | Country queues - pre-assign new requests to an engineer: work item created; JQL `Organizations in ("Ireland", "United Kingdom", "Netherlands") AND assignee is EMPTY`; assign from a user list with balanced workload |
| Flow | Laptop issue resolved - set asset status back to In use: work item transitioned; JQL `"Request Type" = "Laptop or device issue" AND Laptop is not EMPTY AND statusCategory = Done`; AQL branch; Edit object Status = In use |
| Request type | SaaS licence or external guest access (Access request work type, approval workflow); approval flow condition covers both access request types |

# Project 07 — Build log: step by step

How I built the lab, in the order I built it. After completing Jira Service
Management training, I wanted to apply each topic on a real site rather than
only read about it, so every step below starts from a training topic, records
the decision I made and why, and ends with a check that it works.

Built on 11 November 2026 on a personal Jira Service Management Cloud site
(Free plan). Every work item in the screenshots is synthetic test data.

| Step | Training topic | What I built |
|---|---|---|
| 1 | Service spaces and the customer portal | IT service space and portal groups |
| 2 | Request types and request forms | Four request types with their own forms |
| 3 | SLAs and business calendars | Dublin office hours calendar |
| 4 | SLAs: goals and conditions | Time to first response and Time to resolution |
| 5 | Queues and JQL | SLA at risk – unassigned queue |
| 6 | Automation: triggers, conditions, actions | Onboarding (joiner) flow |
| 7 | Automation reuse | Offboarding (leaver) flow |
| 8 | Workflows and approvals | Access request approval workflow and flow |
| 9 | Testing and troubleshooting | End-to-end tests, audit log, fix |
| 10 | Knowledge base and self-service | Confluence knowledge base linked to the portal |
| 11 | Assets (CMDB) | Laptop schema, Assets field on the request form, automation, end-to-end test |

---

## Step 1 — Service space and customer portal

**Training topic:** a service space holds the requests, queues and settings for
one service team; the customer portal is what employees see.

**What I did:** created an IT service space (key `IT`) from the IT service
management template, then organised the portal into portal groups by what the
employee needs: **Accounts & access** and **Hardware & devices**.

**Why:** employees should find the right form in one click, without knowing how
IT categorises work.

![Customer portal with portal groups](screenshots/01-customer-portal-groups.jpg)

---

## Step 2 — Request types and request forms

**Training topic:** a request type is what the customer chooses in the portal;
behind it sit a work type, a workflow and a form.

**What I did:** created four request types from Atlassian templates and renamed
them in the employee's words:

- New starter (onboarding)
- Leaver (offboarding)
- Laptop or device issue
- Access request (apps & admin rights)

**Why:** templates give a sensible starting form; renaming and regrouping makes
the portal clear. The New starter form captures what the resolver needs up
front (name, employee ID, company email, role, team), so IT does not have to
chase details later.

![Request types with work type, workflow and portal group](screenshots/02-request-types.jpg)

![New starter request form](screenshots/03-new-starter-request-form.jpg)

---

## Step 3 — Business-hours calendar

**Training topic:** SLAs should be measured against the hours the team actually
works, not 24/7.

**What I did:** created the **Dublin office hours** calendar: time zone
(GMT+00:00) Dublin, Monday–Friday 09:00–17:00, with Christmas Day and
St Patrick's Day as annual holidays.

**Why:** the site default time zone was not Dublin. Without an explicit
calendar, SLA clocks would run on the wrong hours and breach overnight.

![Dublin office hours calendar](screenshots/07-sla-calendar-dublin.jpg)

---

## Step 4 — SLAs: goals and conditions

**Training topic:** an SLA has goals (matched top to bottom with JQL, with a
catch-all last) and conditions (start, pause, stop).

**What I did:**

| SLA | High priority (`priority in (Highest, High)`) | Everything else |
|---|---|---|
| Time to first response | 1h | 4h |
| Time to resolution | 8h | 24h |

Both start when the work item is created and pause while the status is
**Pending** (waiting on the customer). First response stops on the first public
reply or on resolution; resolution stops when the resolution is set.

**Why:** the team should not be penalised for time the customer holds the
ticket, and high-priority work needs a tighter target.

![Time to first response goals](screenshots/04-sla-first-response-goals.jpg)

![Time to first response conditions](screenshots/05-sla-first-response-conditions.jpg)

![Time to resolution goals and conditions](screenshots/06-sla-time-to-resolution.jpg)

---

## Step 5 — Queue with JQL

**Training topic:** queues are saved JQL filters that tell agents what to work
on next.

**What I did:** created **SLA at risk – unassigned**:

```sql
resolution = Unresolved AND assignee IS EMPTY
AND "Time to first response" < remaining("2h")
ORDER BY "Time to first response" ASC
```

**Why:** the most useful queue is the one that shows problems before they
happen: tickets nobody owns that are about to breach, most urgent first.

![Queue JQL](screenshots/08-queue-sla-at-risk-jql.jpg)

---

## Step 6 — Onboarding automation (joiner)

**Training topic:** an automation flow is trigger → condition → action.

**What I did:** created **Onboarding - create sub-tasks for new starter**:

- Trigger: work item created
- Condition (JQL): `"Request Type" = "New starter (onboarding)"`
- Action: create four sub-tasks: Microsoft 365 account and licence; Entra ID
  security groups; laptop enrolment (Intune/Jamf) and record in Assets;
  application access and welcome email

**Why:** I used the request type as the condition, not keywords in the summary,
so the flow fires only for genuine onboarding requests. HR raises one request
and every team gets its task, with an audit trail.

![Onboarding flow](screenshots/09-automation-onboarding-flow.jpg)

---

## Step 7 — Offboarding automation (leaver)

**Training topic:** the same flow pattern can be reused for related processes.

**What I did:** created **Offboarding - create sub-tasks for leaver**, which
mirrors the onboarding flow with four leaver sub-tasks: block sign-in and
revoke sessions in Entra ID; convert the mailbox to shared and remove the
licence; collect, wipe and update the laptop record; remove application access
and group memberships.

**Why:** offboarding is a security control as much as an admin task. Blocking
sign-in and revoking sessions comes first.

![All three flows enabled](screenshots/10-automation-flows-list.jpg)

![Offboarding flow](screenshots/11-automation-offboarding-flow.jpg)

---

## Step 8 — Workflow and approvals

**Training topic:** approvals are configured on a workflow status; the
**Approvers** field decides who must approve.

**What I did:**

1. Replaced the Access request workflow with a new one, **IT: Access request
   with approval**, from the "Simple (with approval)" template. Only this
   request type uses it, so the other request types keep their workflow.
2. The **In Review** status requires one person in the Approvers field to
   approve.
3. Created **Access request - send to manager approval**: when an Access
   request is created, it sets the Approvers field and moves the work item into
   **In Review**.

**Why:** nobody should receive admin rights or system access without sign-off,
and the approval should start automatically rather than rely on an agent
remembering it.

![Approval workflow](screenshots/13-workflow-access-approval.jpg)

![Approval flow](screenshots/12-automation-approval-flow.jpg)

---

## Step 9 — Testing and troubleshooting

**Training topic:** test every change with a real request; use the automation
audit log when a flow does not behave.

**What I did:** raised synthetic requests through the portal for each process.

| Test | Result |
|---|---|
| New starter `IT-1` | Four sub-tasks created (`IT-2` to `IT-5`); both SLAs running |
| Leaver `IT-6` | Four sub-tasks created (`IT-7` to `IT-10`) |
| Access request `IT-11` | **Failed** — see below |
| Access request `IT-12` | In Review, waiting for 1 approval |

![Onboarding test](screenshots/14-test-onboarding-IT-1.jpg)

![Offboarding test](screenshots/15-test-offboarding-IT-6.jpg)

**The failure and the fix.** The first access request stayed in To Do. The
automation audit log showed the step that failed: *"Unable to transition your
issue to the selected status"*. The workflow had no direct transition from To Do
to In Review. I changed the flow to move the work item To Do → In Progress →
In Review, raised a second request, and it went straight into approval. The
audit log shows the failed run and the successful run after the fix.

![Audit log: failed run and successful run](screenshots/17-audit-log-failure-and-fix.jpg)

**A control I did not have to build.** On `IT-12`, Jira listed the requester
under *excluded approvers*: a person cannot approve their own request. That is
segregation of duties enforced by the platform.

![Approval waiting, requester excluded](screenshots/16-test-approval-IT-12.jpg)

---

## Step 10 — Knowledge base and self-service

**Training topic:** a knowledge base linked to the portal lets employees solve
common problems themselves before raising a ticket (ticket deflection).

**What I did:**

1. Moved Confluence on the site to the **Free** plan and gave my account access.
2. Created a Confluence space, **IT Help Centre**, with the knowledge base
   purpose.
3. Linked it to the service space as an **external** knowledge base, so
   employees can see it in the portal.
4. Wrote three articles for the most common first-line requests: *How to reset
   your password*, *How to connect to the VPN when working remotely* and
   *My laptop is slow - first steps*. Each ends by telling the employee which
   request type to raise if the steps do not work.

**Why:** password resets, VPN problems and slow laptops are repeat tickets.
Good self-help articles reduce volume and leave agents for real problems.

![Knowledge base articles](screenshots/18-knowledge-base-articles.jpg)

**Test:** in the customer portal, a search for *password* returned the article
under **Self-help resources**, with its content preview, before any request was
raised.

![Portal search showing the self-help article](screenshots/19-test-portal-self-help-search.jpg)

---

## Step 11 — Assets: laptops linked to requests

**Training topic:** Assets is the configuration management database (CMDB) in
Jira Service Management. Object schemas hold object types (for example laptops
and people), each with attributes; an Assets custom field lets a request point
at a real object.

**What I did:**

1. Started a 30-day Premium trial on the site, which includes Assets, and gave
   my account the **Assets App admin** role in Atlassian Administration (Assets
   is now a separate platform app, so the role must be granted there).
2. Created an object schema, **IT Assets** (key `ITA`), with four object types:
   **Location**, **Employee**, **Model** and **Laptop**.
3. Gave **Laptop** the attributes an IT team needs: serial number (unique),
   model, assigned to, location, status (In use, In stock, In repair, Retired),
   encryption (FileVault or BitLocker), managed by, purchase date and warranty
   end. Model, Assigned to and Location are references to the other object
   types, so the schema shows who has which laptop and where it is.
4. Loaded synthetic data: 3 locations, 4 models, 5 employees and 8 laptops
   (in use, in stock, in repair and retired).

![Laptop objects in the IT Assets schema](screenshots/20-assets-laptop-schema.jpg)

5. Created an **Assets objects** custom field, **Laptop**, scoped with AQL to
   `objectType = "Laptop" AND Status != "Retired"`, searchable by name and
   serial number, and showing serial number, model, assigned to and status on
   the work item.

![Assets field configuration with the AQL filter scope](screenshots/21-assets-field-configuration.jpg)

6. Added the field to the **Laptop or device issue** request form as a required
   question, *Which laptop?*, with help text, and removed the old free-text
   hardware field.

![Customer portal: the employee picks the laptop by asset tag](screenshots/22-portal-laptop-picker.jpg)

7. Built a flow, **Laptop issue - set asset status to In repair**: when a
   Laptop or device issue is created with a laptop selected, an AQL branch finds
   that laptop and an **Edit object** action sets its status to *In repair*.

![Automation flow: AQL branch and Edit object](screenshots/23-automation-laptop-in-repair-flow.jpg)

**Why:** a free-text "affected hardware" box gives agents nothing to work with.
Linking the request to the real asset shows the serial number, model and owner
straight away, and keeps the inventory status correct without manual updates.

**Test:** raised `IT-13` in the portal for `LT-0001` (status *In use*). The work
item shows the laptop with its serial number, model and owner, and the flow
changed the laptop's status to **In repair**.

![IT-13 with the linked laptop now In repair](screenshots/24-test-IT-13-laptop-in-repair.jpg)

---

## What I would do next

- **Assets:** a flow that sets the laptop back to *In use* when the request is
  resolved, and laptop return on the Leaver request.
- **Knowledge base:** more articles, with categories, and reporting on which
  searches end without an article.
- **SSO and SCIM** from Entra ID so access to the service desk follows the
  identity lifecycle.
- **Approver from the manager field** instead of a fixed approver, once the
  site has more than one user.

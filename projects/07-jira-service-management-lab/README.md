# Project 07 — Jira Service Management Lab (IT Service Desk Build)

## Executive summary

After completing Jira Service Management training, I built and tested an IT
service desk on a personal Jira Service Management Cloud site (Free plan, now
on a 30-day Premium trial) to practise the administration side of a tool I
used daily as an agent. The lab covers request types and portal groups,
response and resolution SLAs on a Dublin working-hours calendar, a JQL-based
queue for SLA risk, joiner and leaver automation flows, a manager-approval step
on access requests, a Confluence knowledge base for self-service, and an Assets
(CMDB) laptop schema linked to the device request form. A second space covers
a major incident, a problem with its root cause and a normal change with CAB
approval. Asset procedures cover a scan-based laptop audit and laptop return on
the Leaver request. Every item was checked end to end with synthetic data.

## Why I built this

After years using Jira every day as an agent in IT operations at TikTok, I am
learning the admin side. I want to understand both sides: the IT team and the
business on one side, and the employee who raises the request on the other.
This is proactive learning. It is a lab with synthetic data, not a claim about
a production system.

## Evidence at a glance

Every claim in this project has a screenshot from the lab site. Full detail is
in the [build log](build-log.md) and the [test results](evidence/owner-cloud-results.md).

| What I built | Proof |
|---|---|
| Customer portal grouped by employee need | [Portal](screenshots/01-customer-portal-groups.jpg) |
| Four request types, each with its own form and workflow | [Request types](screenshots/02-request-types.jpg) · [New starter form](screenshots/03-new-starter-request-form.jpg) |
| Dublin office hours calendar with Irish holidays | [Calendar](screenshots/07-sla-calendar-dublin.jpg) |
| Time to first response SLA (1h / 4h) | [Goals](screenshots/04-sla-first-response-goals.jpg) · [Conditions](screenshots/05-sla-first-response-conditions.jpg) |
| Time to resolution SLA (8h / 24h) | [Resolution SLA](screenshots/06-sla-time-to-resolution.jpg) |
| JQL queue for unassigned work at SLA risk | [Queue JQL](screenshots/08-queue-sla-at-risk-jql.jpg) |
| Onboarding automation — tested | [Flow](screenshots/09-automation-onboarding-flow.jpg) · [Test IT-1: four sub-tasks](screenshots/14-test-onboarding-IT-1.jpg) |
| Offboarding automation — tested | [Flow](screenshots/11-automation-offboarding-flow.jpg) · [Test IT-6: four sub-tasks](screenshots/15-test-offboarding-IT-6.jpg) |
| Manager approval on access requests — tested | [Workflow](screenshots/13-workflow-access-approval.jpg) · [Flow](screenshots/12-automation-approval-flow.jpg) · [Test IT-12: waiting for approval](screenshots/16-test-approval-IT-12.jpg) |
| Troubleshooting: failed run, root cause, fix | [Audit log](screenshots/17-audit-log-failure-and-fix.jpg) |
| All automation flows enabled | [Flows list](screenshots/10-automation-flows-list.jpg) |
| Confluence knowledge base — tested | [Articles](screenshots/18-knowledge-base-articles.jpg) · [Portal search shows the article](screenshots/19-test-portal-self-help-search.jpg) |
| Assets (CMDB): laptop schema linked to requests — tested | [Laptop objects](screenshots/20-assets-laptop-schema.jpg) · [Field and AQL scope](screenshots/21-assets-field-configuration.jpg) · [Portal picker](screenshots/22-portal-laptop-picker.jpg) · [Flow](screenshots/23-automation-laptop-in-repair-flow.jpg) · [Test IT-13: laptop set to In repair](screenshots/24-test-IT-13-laptop-in-repair.jpg) |
| Major incident with SLAs and a timeline — tested | [ITSM-2](screenshots/25-major-incident-ITSM-2.jpg) · [Timeline](screenshots/26-major-incident-timeline.jpg) |
| Problem with root cause, workaround and linked incidents | [ITSM-5](screenshots/27-problem-ITSM-5-root-cause.jpg) |
| Normal change through CAB approval — tested | [ITSM-4](screenshots/28-change-ITSM-4.jpg) · [History](screenshots/29-change-ITSM-4-history.jpg) |
| Scan-based laptop audit in Assets | [Audit results](screenshots/30-assets-audit-results.jpg) |
| Laptop return on the Leaver request — tested | [LT-0003 history](screenshots/31-asset-return-LT-0003-history.jpg) |
| Knowledge base article: return your laptop | [Article](screenshots/32-kb-return-laptop-article.jpg) |
| SLA report and dashboard | [SLA first response: met vs breached](screenshots/33-report-sla-first-response.jpg) · [Dashboard](screenshots/34-dashboard.jpg) |

## Operational challenge

In enterprise IT operations I worked tickets from the agent side: triaging by
priority, owning L2/L3 escalations and turning fixes into runbooks. A service
desk only works well when the configuration behind it is deliberate: clear
request types, forms that capture what the resolver needs, time targets that
reflect business hours, queues that surface risk early, and automation that
removes repetitive manual steps such as onboarding hand-offs. This lab rebuilds
that configuration from scratch so each design decision can be explained.

## My contribution

- Created an IT service space and four request types with their own request
  forms: **New starter (onboarding)**, **Leaver (offboarding)**,
  **Laptop or device issue** and **Access request (apps & admin rights)**.
- Organised the customer portal into two portal groups:
  **Accounts & access** and **Hardware & devices**.
- Built a **Dublin office hours** SLA calendar (Europe/Dublin, Monday–Friday
  09:00–17:00) with recurring Irish public holidays.
- Configured two SLAs on that calendar: **Time to first response** (1 hour for
  high priority, 4 hours otherwise) and **Time to resolution** (8 hours for high
  priority, 24 working hours otherwise), both paused while pending on the
  customer.
- Created a JQL queue, **SLA at risk – unassigned**, ordered by time remaining.
- Built an automation flow that creates four onboarding sub-tasks whenever a
  New starter request is raised, and a mirror flow that creates four
  offboarding sub-tasks for every Leaver request.
- Gave Access requests their own workflow with an approval status
  (**In review**) and a flow that sets the approver and routes every new access
  request into approval before any work starts.
- Created a Confluence knowledge base (**IT Help Centre**), linked it to the
  portal and wrote three self-help articles: password reset, VPN and slow
  laptop.
- Built an **Assets** object schema (**IT Assets**: Location, Employee, Model,
  Laptop) with 8 synthetic laptops, an Assets field (**Laptop**) scoped with
  AQL, a required *Which laptop?* question on the device request form, and a
  flow that sets the selected laptop to **In repair** when a request is raised.
- Built a second space, **IT Operations (ITSM)**, and ran one office outage
  through it: three incidents, one flagged as the **major incident** with a
  timed timeline; a **problem** with root cause, workaround and linked
  incidents; and a **normal change** (firewall firmware update) with plan,
  rollback and communication, through CAB approval to Resolved.
- Added audit attributes to the Laptop object type and recorded a synthetic
  scan-based audit (Found / Found - wrong location / Missing), with a
  follow-up ticket for the missing laptop.
- Processed a laptop return on the Leaver request: the laptop went back to
  stock with no owner, the right location and its condition recorded.
- Wrote two more knowledge base articles (find your asset tag; return your
  laptop), plus a [user guide](manuals/user-guide.md), an
  [agent runbook](manuals/agent-runbook.md), an
  [admin guide](manuals/admin-guide.md) and an
  [audit procedure](procedures/scan-based-asset-audit.md).
- Built an SLA report (first response met vs breached) and a dashboard.
- Verified every flow with synthetic requests, including one failed run that
  exposed a missing workflow transition and was fixed, and recorded the results
  in [`evidence/owner-cloud-results.md`](evidence/owner-cloud-results.md).

## Approach

- Started from Atlassian request-type templates, then renamed and regrouped
  them around how employees describe their problem, not how IT categorises it.
- Kept the SLA conditions simple and explicit: start on creation, pause while
  pending on the customer, stop on the first public reply or on resolution.
- Matched SLA goals top to bottom with JQL, with a catch-all goal last, so every
  work item receives exactly one target.
- Used the request type, rather than free-text keywords, as the automation
  condition, so the flow fires only for genuine onboarding requests.
- Tested each change with a real request through the customer portal instead of
  assuming the configuration behaved as intended.

## Outcomes

- A working, portal-facing IT service desk with four request types and two
  portal groups.
- SLA targets calculated against Dublin business hours and public holidays.
- An agent queue that surfaces unassigned work items before they breach.
- One onboarding request now produces four assigned-ready sub-tasks with no
  manual copying (verified: one request in, four sub-tasks out); the same holds
  for leavers.
- Employees searching the portal see the matching self-help article before
  raising a ticket.
- Access requests cannot be worked until approved; the platform also excluded
  the requester from approving their own request (segregation of duties).
- One outage, three incidents: a single major incident carried the timeline
  and the user update, and a problem linked all three to one root cause.
- The firewall change met its approval SLA (40h) and recorded plan, rollback
  and communication before work started.
- The audit gave every laptop not retired an audit result and left a ticket
  for the missing one; a returned laptop went back to stock with owner,
  status, location and condition updated.

## Technologies and competencies

- Jira Service Management Cloud (service space administration)
- ITSM / ITIL request fulfilment and SLA management
- Incident, major incident, problem and change management (normal change,
  CAB approval)
- JQL (Jira Query Language)
- Jira automation (trigger, JQL condition, create sub-tasks, edit field,
  transition actions) and the automation audit log for troubleshooting
- Jira workflows and approvals
- Assets (CMDB): object schemas, reference attributes, AQL, Assets fields and
  Edit object automation
- IT asset management procedures: scan-based audit and laptop return
- Jira Service Management reports and dashboards
- Python (audit reconcile tool)
- Confluence knowledge base and self-service (ticket deflection)
- Joiner and leaver process design (Microsoft 365, Entra ID, device enrolment step)
- Technical documentation

## Public demonstration artefacts

- [`build-log.md`](build-log.md) — **start here**: the build step by step,
  each step tied to the Jira Service Management training topic it applies,
  with the decision made, the reason, and a screenshot.
- [`screenshots/`](screenshots/) — 34 screenshots of the configuration and the
  test results.
- [`configuration.md`](configuration.md) — the full configuration: request
  types, portal groups, SLA calendar and goals, queue JQL, automation flows,
  Assets, the ITSM space, the change workflow and the audit procedure, with
  Mermaid diagrams.
- [`evidence/owner-cloud-results.md`](evidence/owner-cloud-results.md) — the
  end-to-end tests and their observed results.
- [`manuals/`](manuals/) — [user guide](manuals/user-guide.md),
  [agent runbook](manuals/agent-runbook.md) and
  [admin guide](manuals/admin-guide.md).
- [`procedures/scan-based-asset-audit.md`](procedures/scan-based-asset-audit.md)
  — the audit procedure, mapped to real work in
  [Project 02](../02-asset-management-audit/README.md).
- [`tools/asset-audit-reconcile/`](tools/asset-audit-reconcile/) — a Python
  tool that compares a scan CSV with an Assets export: Found, Found - wrong
  location, Missing or Unexpected.

## Related projects

| This lab | Real work |
|---|---|
| Scan-based laptop audit in Assets | [Project 02](../02-asset-management-audit/README.md): scan-based asset audit at TikTok, more than 5,000 assets, 99% stock and audit visibility |
| Laptop return on the Leaver request | [Project 04](../04-asset-return-redeployment/README.md): asset return and redeployment workflow at TikTok across three sites |

## Scope and limitations

Configured and tested in this lab: everything listed above. The site started
on the Free plan and now runs on a 30-day Premium trial, which added Assets.
**Not** configured here: SAML SSO or SCIM provisioning from Entra ID.
These are documented as next steps rather than claimed.

> This lab runs on a personal site created for portfolio purposes. It
> contains no employer data; every work item, person, location and asset is
> synthetic.

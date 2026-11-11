# Project 07 — Jira Service Management Lab (IT Service Desk Build)

## Executive summary

After completing Jira Service Management training, I built and tested an IT
service desk on a personal Jira Service Management Cloud site (Free plan) to
practise the administration side of a tool I used daily as an agent. The lab covers request types and portal groups, response and
resolution SLAs on a Dublin working-hours calendar, a JQL-based queue for SLA
risk, joiner and leaver automation flows, and a manager-approval step on access
requests, and a Confluence knowledge base for self-service. Every configuration
item was checked end to end with synthetic test requests.

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

## Technologies and competencies

- Jira Service Management Cloud (service space administration)
- ITSM / ITIL request fulfilment and SLA management
- JQL (Jira Query Language)
- Jira automation (trigger, JQL condition, create sub-tasks, edit field,
  transition actions) and the automation audit log for troubleshooting
- Jira workflows and approvals
- Confluence knowledge base and self-service (ticket deflection)
- Joiner and leaver process design (Microsoft 365, Entra ID, Intune/Jamf)
- Technical documentation

## Public demonstration artefacts

- [`build-log.md`](build-log.md) — **start here**: the build step by step,
  each step tied to the Jira Service Management training topic it applies,
  with the decision made, the reason, and a screenshot.
- [`screenshots/`](screenshots/) — 19 screenshots of the configuration and the
  test results.
- [`configuration.md`](configuration.md) — the full configuration: request
  types, portal groups, SLA calendar and goals, queue JQL and the automation
  flow, with a Mermaid diagram of the onboarding flow.
- [`evidence/owner-cloud-results.md`](evidence/owner-cloud-results.md) — the
  end-to-end test and its observed result.

## Scope and limitations

Configured and tested in this lab: everything listed above. **Not** configured
here: Assets (CMDB) object schemas (a Premium feature on this plan) and SAML SSO
or SCIM provisioning from Entra ID.
These are documented as next steps rather than claimed.

> This lab runs on a personal Free-plan site created for portfolio purposes. It
> contains no employer data; the only work item data is a synthetic test
> request.

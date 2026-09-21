# Project 03 — Enterprise Virtualisation & Server Infrastructure Deployment

## Executive summary

Supported the deployment of server and virtualisation infrastructure for an
enterprise environment, including storage and 10 Gb networking, VMware vSphere
and vCenter, and Linux and Windows virtual machines. The work helped deliver a
stable virtualised platform for operational use and future expansion.

## Operational challenge

The environment needed a reliable virtualisation platform built on properly
configured compute, storage and networking, with clustering and resilience in
place, and validated before being handed over for operational use.

## My contribution

- Supported server and virtualisation infrastructure deployment for an
  enterprise environment.
- Installed server storage and 10 Gb network adapters.
- Deployed VMware vSphere and vCenter.
- Provisioned Linux and Windows virtual machines.
- Supported cluster, RAID, storage, application and network configuration.
- Participated in infrastructure testing and troubleshooting.
- Helped deliver a stable virtualised environment for operational use and future
  expansion.

## Approach

- Installed and cabled server storage and 10 Gb network adapters.
- Deployed the vSphere hypervisor hosts and vCenter management.
- Configured RAID, storage presentation and clustering for resilience.
- Provisioned Linux and Windows virtual machines onto the cluster.
- Tested and troubleshot compute, storage, application and network behaviour
  before hand-over.

## Outcomes

- A stable, clustered virtualised environment delivered for operational use.
- Headroom for future expansion through the cluster and 10 Gb networking.

## Technologies and competencies

- VMware vSphere
- Virtualisation
- Server Administration
- Network Infrastructure
- Linux

## Public demonstration artefacts

- [`architecture.md`](architecture.md) — a high-level, **generic** Mermaid
  architecture diagram of a clustered vSphere environment.
- [`deployment-checklist.md`](deployment-checklist.md) — a generic deployment
  checklist.
- [`validation-checklist.md`](validation-checklist.md) — a generic validation
  checklist.

> These artefacts are **sanitised reference implementations**. The diagram is
> deliberately generic and does **not** reproduce the real internal topology,
> addressing, host counts or naming.

## Security and confidentiality considerations

- No internal hostnames, IP addresses, VLANs, datastore names or host counts.
- The architecture is a generic reference pattern, not the production design.

## Lessons learned

- Validating storage and network paths **before** provisioning virtual machines
  avoided rework that is expensive to unpick later.
- Clustering and RAID choices are easiest to get right when resilience
  requirements are agreed up front, not retrofitted.
- A shared validation checklist made hand-over to operations cleaner and less
  ambiguous.

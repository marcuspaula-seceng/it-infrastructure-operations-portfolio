# Virtualisation Deployment Checklist (Generic)

A generic deployment checklist for a clustered vSphere environment. Contains no
internal names, addresses or counts.

## 1. Hardware and cabling

- [ ] Server storage installed and seated.
- [ ] 10 Gb network adapters installed.
- [ ] Redundant power and network cabling connected and labelled.

## 2. Storage

- [ ] RAID configured to the agreed resilience level.
- [ ] Datastores created and presented to all hosts.
- [ ] Multipathing configured and verified.

## 3. Hypervisor and management

- [ ] ESXi installed on each host at the agreed build.
- [ ] Hosts added to vCenter.
- [ ] Cluster created with resilience features enabled.

## 4. Networking

- [ ] Management, workload and storage networks separated.
- [ ] Redundant uplinks configured.
- [ ] Connectivity verified across all paths.

## 5. Workloads

- [ ] Linux virtual machines provisioned to baseline.
- [ ] Windows virtual machines provisioned to baseline.
- [ ] VM tools / guest agents installed.

## 6. Hand-over

- [ ] Configuration recorded.
- [ ] Validation checklist completed (see `validation-checklist.md`).
- [ ] Environment accepted by operations.

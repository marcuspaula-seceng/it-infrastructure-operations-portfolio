# Virtualisation Validation Checklist (Generic)

A generic validation checklist to confirm a clustered vSphere environment is
ready for operational use. Contains no internal names, addresses or counts.

## 1. Cluster health

- [ ] All hosts connected and healthy in vCenter.
- [ ] Cluster resilience features active and tested.
- [ ] No outstanding hardware or configuration alarms.

## 2. Storage

- [ ] Datastores accessible from every host.
- [ ] RAID status healthy.
- [ ] Multipathing failover tested.

## 3. Networking

- [ ] Redundant uplink failover tested.
- [ ] Management, workload and storage traffic reachable as designed.
- [ ] No packet loss on the 10 Gb fabric under test load.

## 4. Workloads

- [ ] Linux and Windows VMs boot and reach the network.
- [ ] VM mobility between hosts verified.
- [ ] Application services respond as expected.

## 5. Resilience testing

- [ ] Simulated host failure recovers workloads as designed.
- [ ] Simulated path / link failure recovers as designed.

## 6. Sign-off

- [ ] Test results recorded.
- [ ] Exceptions logged with remediation.
- [ ] Environment signed off for operational use and future expansion.

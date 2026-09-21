# Generic Virtualisation Architecture (Reference Pattern)

A high-level, **generic** reference pattern for a clustered VMware vSphere
environment. It intentionally does **not** represent the real internal topology,
host counts, addressing or naming — it exists only to illustrate the components
and relationships involved.

```mermaid
flowchart TB
    subgraph Management
        VC[vCenter Server]
    end

    subgraph Cluster[vSphere Cluster]
        H1[ESXi Host A]
        H2[ESXi Host B]
        H3[ESXi Host C]
    end

    subgraph Network[10 Gb Network Fabric]
        SW1[Switch 1]
        SW2[Switch 2]
    end

    subgraph Storage[Shared Storage]
        DS[(RAID-protected datastore)]
    end

    subgraph Workloads[Virtual Machines]
        LX[Linux VMs]
        WN[Windows VMs]
    end

    VC --- H1
    VC --- H2
    VC --- H3
    H1 --- SW1
    H2 --- SW1
    H3 --- SW2
    SW1 --- DS
    SW2 --- DS
    H1 --- Workloads
    H2 --- Workloads
    H3 --- Workloads
```

## Components

| Layer | Role |
|-------|------|
| Management | vCenter provides centralised management of the cluster. |
| Compute | Multiple ESXi hosts form a cluster for resilience and capacity. |
| Network | Redundant 10 Gb switching for host, storage and VM traffic. |
| Storage | Shared, RAID-protected datastore presented to all hosts. |
| Workloads | Linux and Windows virtual machines running operational services. |

## Design principles illustrated

- Redundancy at the host, network and storage layers.
- Shared storage to enable cluster features and VM mobility.
- Separation of management and workload responsibilities.

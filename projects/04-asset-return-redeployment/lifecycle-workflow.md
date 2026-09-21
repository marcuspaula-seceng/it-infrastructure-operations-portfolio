# Asset Return & Redeployment — Lifecycle Workflow

A generic end-to-end workflow for returned and offboarded IT assets, with
decision gates. It names no real product, location or routing.

```mermaid
flowchart TD
    A[Asset returned / offboarded] --> B[Receipt and logging]
    B --> C[Technical assessment]
    C --> D{Condition?}

    D -->|Reusable| E[Secure wipe]
    D -->|Damaged| F{Repairable?}
    D -->|Uncertain| G[Quarantine for review]

    F -->|Yes| H[Repair] --> E
    F -->|No| I[Route to disposal]

    G --> C

    E --> J[Reimage to baseline]
    J --> K[Quality checks]
    K --> L{Pass?}
    L -->|Yes| M[Store in operational stock]
    L -->|No| C
    M --> N{Stock level low?}
    N -->|Yes| O[Trigger replenishment control]
    N -->|No| P[Available for redeployment]
    O --> P
    P --> Q[Redeploy to user / site]
```

## Decision gates

| Gate | Outcome |
|------|---------|
| Reusable | Proceed to secure wipe and reimage. |
| Damaged | Assess repairability; repair or route to disposal. |
| Quarantined | Hold for review, then re-assess. |
| Disposal-bound | Route to disposal following the agreed process. |

## Stages

1. Receipt and logging
2. Technical assessment
3. Secure wipe (generic)
4. Reimage to baseline
5. Quality checks
6. Storage in operational stock (with low-stock control)
7. Redeployment

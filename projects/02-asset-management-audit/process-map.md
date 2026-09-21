# Scan-Based Asset Audit — Process Map

A generic view of the standardised, scan-based stock audit workflow. It contains
no internal locations, systems or asset formats.

```mermaid
flowchart TD
    A[Start audit cycle] --> B[Export expected inventory]
    B --> C[Scan physical assets by asset tag]
    C --> D[Normalise and de-duplicate scan data]
    D --> E[Reconcile scanned vs expected]
    E --> F{Category}
    F -->|Matched| G[Confirm and record]
    F -->|Missing| H[Investigate: mislocated or off-site?]
    F -->|Unexpected| I[Investigate: untracked or wrong location?]
    F -->|Duplicate| J[Resolve double-scan]
    G --> K[Update inventory records]
    H --> K
    I --> K
    J --> K
    K --> L[Report audit visibility and exceptions]
    L --> M[Close audit cycle]
```

## Categories

| Category | Meaning | Typical follow-up |
|----------|---------|-------------------|
| Matched | Present and expected | Confirm and record |
| Missing | Expected but not scanned | Locate, or flag as off-site / in transit |
| Unexpected | Scanned but not expected | Add to records or correct location |
| Duplicate | Scanned more than once | Resolve double-scan, correct count |

## Notes

- Tags are normalised (trimmed and case-folded) before reconciliation.
- The demonstration tool implements exactly this reconciliation and category
  logic on synthetic data.

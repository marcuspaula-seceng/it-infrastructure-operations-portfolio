# Project 01 — Endpoint Imaging Infrastructure Optimisation (Linux & Windows)

## Executive summary

Improved a Linux and Windows endpoint-imaging environment by upgrading imaging
servers, standardising post-image validation and increasing network capacity.
Individual device turnaround was reduced from approximately 60 minutes to
15 minutes, with more consistent, repeatable results.

## Operational challenge

Endpoint imaging was slower and less predictable than it needed to be. Image
builds drifted from current operating-system baselines, validation was
inconsistent between technicians, and network throughput on the imaging path
constrained how quickly devices could be prepared and returned to service.

## My contribution

- Improved the Linux and Windows endpoint-imaging environment.
- Upgraded imaging servers and kept operating-system builds current.
- Introduced a test instance for daily image validation.
- Increased imaging-network capacity from 100 Mbps to 1 Gbps.
- Standardised endpoint wipe and reimaging procedures.
- Collaborated with teams in Singapore and China to test image versions,
  investigate failures and improve reliability.

## Approach

- Established a repeatable set of post-image checks covering camera, microphone,
  audio, networking, Windows updates and vendor updates.
- Ran daily image validation on a dedicated test instance to catch regressions
  before they reached production imaging.
- Standardised the wipe-and-reimage sequence so any technician could achieve the
  same result.
- Worked across time zones with colleagues in Singapore and China to compare
  image versions and resolve failures.

## Outcomes

Documented operational outcomes (not independently audited guarantees):

- Individual device turnaround reduced from **approximately 60 minutes to
  15 minutes**.
- Imaging-network capacity upgraded from **100 Mbps to 1 Gbps**.
- More consistent validation and fewer image-related failures reaching
  production.

## Technologies and competencies

- Endpoint Management
- Operating System Deployment
- Windows
- Linux
- Server Administration

## Public demonstration artefacts

- [`Get-EndpointReadiness.ps1`](Get-EndpointReadiness.ps1) — a **read-only**
  PowerShell script that collects generic endpoint readiness information
  (OS build, disk space, networking, Windows Update service state, and
  audio/visual device presence). It makes **no** system changes.
- [`endpoint-validation-checklist.md`](endpoint-validation-checklist.md) — a
  generic post-image validation checklist.

> **Important:** these artefacts are **sanitised reference implementations**
> created for portfolio purposes. They are **not** the original enterprise
> production imaging or validation scripts, and they contain no internal
> hostnames, paths, image names or vendor-specific details.

### Running the script

```powershell
pwsh -File ./Get-EndpointReadiness.ps1
pwsh -File ./Get-EndpointReadiness.ps1 -AsJson
```

## Security and confidentiality considerations

- The script is strictly read-only and collects no personal or identifying data.
- No internal server names, image repositories or network addresses are included.
- All examples are generic and safe to run on any workstation.

## Lessons learned

- A dedicated daily-validation instance catches image regressions far earlier
  and cheaper than discovering them during live provisioning.
- Standardising the validation checklist mattered as much as the server and
  network upgrades: consistency between technicians was the real multiplier.
- Cross-region collaboration needs a shared, unambiguous definition of "passed
  validation" to be effective across time zones.

# Endpoint Post-Image Validation Checklist

A generic, repeatable checklist for validating a device after imaging. This is a
sanitised reference version; it contains no internal image names, hostnames or
vendor-specific detail.

## 1. Operating system

- [ ] Correct operating-system build applied and current with baseline.
- [ ] Device boots cleanly to the desktop / login.
- [ ] Hostname set according to the local naming standard.
- [ ] Time zone, region and locale correct.

## 2. Updates

- [ ] Windows Update service running; latest quality updates applied.
- [ ] Vendor / firmware updates applied (BIOS/UEFI, drivers).
- [ ] No pending reboots outstanding.

## 3. Networking

- [ ] Wired network connectivity confirmed.
- [ ] Wireless connectivity confirmed where applicable.
- [ ] DNS resolution and general internet reachability confirmed.

## 4. Peripherals and audio/visual

- [ ] Camera detected and produces an image.
- [ ] Microphone detected and captures audio.
- [ ] Speakers / audio output detected and audible.
- [ ] External displays detected at correct resolution.

## 5. Endpoint management

- [ ] Device enrolled in the management platform.
- [ ] Required baseline applications present.
- [ ] Security agent present and reporting.

## 6. Wipe-and-reimage hygiene (when reimaging a returned device)

- [ ] Previous user profile and data removed per the standard wipe procedure.
- [ ] Disk encryption re-enabled where required.
- [ ] Device reset to a clean, known baseline before reissue.

## 7. Sign-off

- [ ] Validation results recorded.
- [ ] Any failures logged with the fix applied.
- [ ] Device marked ready for issue / redeployment.

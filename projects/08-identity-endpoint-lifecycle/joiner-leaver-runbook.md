# Joiner and Leaver Runbook (Entra ID, Microsoft 365, Intune, Jamf)

A generic reference runbook. Adapt names, groups and policies to the
organisation. All examples use the fictional `contoso.com` domain.

## Joiner — before day one

| # | Step | Where | Check |
|---|------|-------|-------|
| 1 | Confirm the request: name, start date, role, manager, office, device type | Service desk ticket | Approved by manager or HR |
| 2 | Create the user account with the standard naming format | Entra ID → Users | UPN and display name correct |
| 3 | Set usage location, then assign the Microsoft 365 licence | Entra ID / M365 admin centre | Mailbox provisions within minutes |
| 4 | Add to role-based security groups and distribution lists | Entra ID → Groups | Access comes from groups, not one-off grants |
| 5 | Grant shared mailbox or Teams access if requested | Exchange admin centre / Teams | Owner approved |
| 6 | Prepare the device | — | — |
| 6a | Windows: confirm device is registered for Autopilot, assign to user, enrol | Intune | Required apps installed, compliant |
| 6b | Mac: confirm device is in Apple Business Manager and assigned to Jamf, enrol | Jamf Pro | Policies run, FileVault on, checked in |
| 7 | Issue a temporary password through a secure channel | — | User must change at first sign-in |
| 8 | Day one: user signs in and registers MFA (Microsoft Authenticator) | Entra ID | MFA method registered |
| 9 | Confirm Outlook, Teams, OneDrive and required apps work | Device | User confirms |
| 10 | Update the ticket and close | Service desk | Asset assigned to user |

## Leaver — on the last day

Order matters: remove access first, then tidy up.

| # | Step | Where | Check |
|---|------|-------|-------|
| 1 | Confirm the leaver request and exact end time | Service desk ticket | Approved by manager or HR |
| 2 | **Block sign-in** | Entra ID → User → Edit properties | Account disabled |
| 3 | **Revoke sessions** so existing tokens stop working | Entra ID → User → Revoke sessions | Signed out everywhere |
| 4 | Reset password (optional extra step) | Entra ID | — |
| 5 | Convert mailbox to shared or set delegation / forwarding as agreed | Exchange admin centre | Manager has access if approved |
| 6 | Transfer OneDrive files to the manager if required | M365 admin centre | Retention respected |
| 7 | Remove licence (after mailbox is converted) | M365 admin centre | Licence released |
| 8 | Remove from groups, distribution lists and app access | Entra ID / apps | No remaining access |
| 9 | Device | — | — |
| 9a | Windows: retire or wipe | Intune → Devices | Action completed |
| 9b | Mac: lock or erase | Jamf Pro → Computer → Management | Command acknowledged |
| 10 | Collect device and process for reuse | Asset process (see Project 04) | Asset status updated |
| 11 | Update the ticket and close | Service desk | Checklist complete |

## Mover — role change

1. Confirm the new role and manager.
2. Add the new role groups **and remove the old ones** so access does not build
   up over time.
3. Review shared mailboxes and app access.
4. Check whether the device or licence type needs to change.

## Notes

- An MFA reset is only done after verifying the person's identity (for
  example, a video call or a manager confirmation), never on request alone.
- Lost or stolen device: lock first, wipe once recovery is ruled out, and
  revoke the user's sessions.

# Identity and Device Troubleshooting Guide

Common identity and device issues, with how to diagnose and fix them. Identity
rows reflect day-to-day Entra ID and Microsoft 365 support. Device rows are
written as a reference for an Intune and Jamf environment, plus BitLocker and
Puppet. Generic reference; no employer-specific details.

| Issue | How to diagnose | Fix |
|-------|-----------------|-----|
| User cannot sign in: "account locked" or wrong password | Entra ID sign-in logs: failure reason and location | Verify identity, reset password, confirm the account is not blocked |
| New phone, cannot approve MFA | User has no working MFA method | Verify identity, require re-registration of MFA methods, guide set-up in Microsoft Authenticator |
| Sign-in blocked by Conditional Access | Sign-in logs show the policy that failed (for example, non-compliant device) | Fix the cause (device compliance, location) rather than excluding the user |
| No mailbox after account creation | Licence missing or usage location not set | Set usage location, assign licence, wait for provisioning |
| Cannot see a shared mailbox | Not a member, or Outlook not refreshed | Grant Full Access, restart Outlook (auto-mapping) |
| Windows device shows "Not compliant" | Intune → Device → Device compliance: which setting failed | Fix the setting (BitLocker, OS version, Defender), then **Sync** |
| Required app not installed | Intune → Device → Managed apps: install status and error | Confirm assignment group, sync, check disk space and network |
| Policy change not applied | Last check-in time in Intune | Trigger **Sync** from Intune or Company Portal |
| Mac not checking in | Jamf Pro → Computer → Inventory: last check-in | Run `sudo jamf policy` / `sudo jamf recon` on the Mac, check network and MDM profile |
| Mac missing an app | Jamf policy logs for that computer | Re-run the policy or install from Self Service |
| New Mac did not enrol automatically | Serial not in Apple Business Manager or not assigned to the Jamf server | Assign in Apple Business Manager, erase and set up again |
| Windows asks for a BitLocker recovery key | Usually after a BIOS/firmware update or hardware change | Verify identity, retrieve the recovery key for that device, unlock, then check why it was triggered |
| Mac drifted from the standard configuration | Puppet run report for that Mac | Trigger a Puppet run (`sudo puppet agent -t`), check the agent can reach the server |
| Lost laptop | Last check-in and user confirmation | Lock (Jamf / Intune), revoke sessions, wipe if not recovered |

## Approach

1. Reproduce or confirm the symptom with the user.
2. Check the logs first (sign-in logs, Intune device status, Jamf inventory)
   instead of guessing.
3. Fix the cause, then confirm with the user.
4. Write the fix in the ticket, and as a knowledge-base article if it repeats.

<#
.SYNOPSIS
    Read-only snapshot of one user's identity, access and managed devices.

.DESCRIPTION
    Uses the Microsoft Graph PowerShell SDK to report, for a single user:
      - account state (enabled, created, last password change)
      - assigned Microsoft 365 licences
      - group memberships
      - registered authentication (MFA) methods
      - Intune-managed devices and their compliance state

    Useful as a check before and after a joiner, mover or leaver change.
    The script only reads data. It makes NO changes to the tenant.

.PARAMETER UserPrincipalName
    The user to report on, for example jane.doe@contoso.com.

.PARAMETER AsJson
    Output the snapshot as JSON instead of formatted text.

.EXAMPLE
    ./Get-UserAccessSnapshot.ps1 -UserPrincipalName jane.doe@contoso.com

.NOTES
    Requires: Microsoft.Graph module and delegated read permissions
    (User.Read.All, GroupMember.Read.All, UserAuthenticationMethod.Read.All,
    DeviceManagementManagedDevices.Read.All).
    Sanitised reference implementation for portfolio purposes.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserPrincipalName,

    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

$scopes = @(
    'User.Read.All',
    'GroupMember.Read.All',
    'UserAuthenticationMethod.Read.All',
    'DeviceManagementManagedDevices.Read.All'
)

if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes $scopes -NoWelcome
}

$user = Get-MgUser -UserId $UserPrincipalName `
    -Property 'id,displayName,userPrincipalName,accountEnabled,createdDateTime,lastPasswordChangeDateTime,usageLocation'

$licences = Get-MgUserLicenseDetail -UserId $user.Id |
    Select-Object -ExpandProperty SkuPartNumber

$groups = Get-MgUserMemberOf -UserId $user.Id -All |
    ForEach-Object { $_.AdditionalProperties['displayName'] } |
    Where-Object { $_ } |
    Sort-Object

$methods = Get-MgUserAuthenticationMethod -UserId $user.Id |
    ForEach-Object { ($_.AdditionalProperties['@odata.type'] -replace '#microsoft.graph.', '') -replace 'AuthenticationMethod$', '' }

$devices = Get-MgDeviceManagementManagedDevice -All `
    -Filter "userPrincipalName eq '$($user.UserPrincipalName)'" |
    Select-Object DeviceName, OperatingSystem, OsVersion, ComplianceState, LastSyncDateTime

$snapshot = [ordered]@{
    DisplayName         = $user.DisplayName
    UserPrincipalName   = $user.UserPrincipalName
    AccountEnabled      = $user.AccountEnabled
    Created             = $user.CreatedDateTime
    LastPasswordChange  = $user.LastPasswordChangeDateTime
    UsageLocation       = $user.UsageLocation
    Licences            = @($licences)
    Groups              = @($groups)
    AuthMethods         = @($methods)
    ManagedDevices      = @($devices)
}

if ($AsJson) {
    $snapshot | ConvertTo-Json -Depth 4
}
else {
    Write-Host "`n== Account ==" -ForegroundColor Cyan
    [pscustomobject]$snapshot | Select-Object DisplayName, UserPrincipalName, AccountEnabled, Created, LastPasswordChange, UsageLocation | Format-List

    Write-Host '== Licences ==' -ForegroundColor Cyan
    if ($licences) { $licences } else { '(none)' }

    Write-Host "`n== Groups ==" -ForegroundColor Cyan
    if ($groups) { $groups } else { '(none)' }

    Write-Host "`n== Authentication methods ==" -ForegroundColor Cyan
    if ($methods) { $methods } else { '(none)' }

    Write-Host "`n== Intune-managed devices ==" -ForegroundColor Cyan
    if ($devices) { $devices | Format-Table -AutoSize } else { '(none)' }
}

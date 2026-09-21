#Requires -Version 5.1
<#
.SYNOPSIS
    Collects generic, read-only endpoint readiness information.

.DESCRIPTION
    Sanitised reference implementation created for portfolio purposes. This is
    NOT the original enterprise production imaging or validation script. It only
    READS information from the local machine and prints a readiness summary; it
    makes no changes of any kind -- it does not install, configure, wipe or
    reimage anything.

    It illustrates the type of repeatable post-image checks described in the
    accompanying case study: operating system build, networking, disk space,
    Windows Update service state, and the presence of common audio/visual
    devices (camera, microphone, speakers).

    No confidential, employer-specific or personally identifying data is
    collected or transmitted. Output stays on the local console unless the
    operator redirects it.

.PARAMETER AsJson
    Emit the readiness summary as JSON instead of formatted text.

.EXAMPLE
    pwsh -File ./Get-EndpointReadiness.ps1

.EXAMPLE
    pwsh -File ./Get-EndpointReadiness.ps1 -AsJson

.NOTES
    Read-only. Cross-platform where the underlying data is available; some
    checks are Windows-specific and are reported as 'unavailable' elsewhere.
#>

[CmdletBinding()]
param(
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Detect Windows in a way that works on both Windows PowerShell 5.1 (where the
# automatic $IsWindows variable does not exist) and PowerShell 7+.
$script:OnWindows = ($env:OS -eq 'Windows_NT')

function Get-OperatingSystemInfo {
    <#
        Returns a small object describing the OS build. Uses CIM on Windows and
        falls back to environment data elsewhere.
    #>
    try {
        if ($script:OnWindows) {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
            return [pscustomobject]@{
                Name    = $os.Caption
                Version = $os.Version
                Build   = $os.BuildNumber
            }
        }
    }
    catch {
        Write-Verbose "OS CIM query unavailable: $($_.Exception.Message)"
    }

    return [pscustomobject]@{
        Name    = [System.Environment]::OSVersion.Platform.ToString()
        Version = [System.Environment]::OSVersion.Version.ToString()
        Build   = 'unavailable'
    }
}

function Get-SystemDriveFreeGb {
    <# Returns free space on the system drive in GB, or $null if unavailable. #>
    try {
        if ($env:SystemDrive) {
            $systemDrive = $env:SystemDrive.TrimEnd(':')
        }
        else {
            $systemDrive = '/'
        }
        $drive = Get-PSDrive -PSProvider FileSystem -ErrorAction Stop |
            Where-Object { $_.Name -eq $systemDrive -or $_.Root -eq '/' } |
            Select-Object -First 1
        if ($null -ne $drive -and $null -ne $drive.Free) {
            return [math]::Round($drive.Free / 1GB, 1)
        }
    }
    catch {
        Write-Verbose "Drive space query unavailable: $($_.Exception.Message)"
    }
    return $null
}

function Test-NetworkConnectivity {
    <# Read-only connectivity probe. Returns $true/$false, never throws. #>
    try {
        return [bool](Get-NetRoute -ErrorAction Stop |
            Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' })
    }
    catch {
        try {
            return (Test-Connection -ComputerName '127.0.0.1' -Count 1 -Quiet -ErrorAction Stop)
        }
        catch {
            return $false
        }
    }
}

function Get-WindowsUpdateServiceState {
    <# Returns the Windows Update service status, or 'unavailable'. #>
    try {
        $service = Get-Service -Name 'wuauserv' -ErrorAction Stop
        return $service.Status.ToString()
    }
    catch {
        return 'unavailable'
    }
}

function Get-AudioVisualDevicePresence {
    <#
        Reports whether camera, microphone and speaker devices are present.
        Uses PnP device data on Windows; returns 'unavailable' elsewhere.
    #>
    $result = [ordered]@{
        Camera     = 'unavailable'
        Microphone = 'unavailable'
        Speaker    = 'unavailable'
    }
    try {
        $devices = Get-PnpDevice -PresentOnly -ErrorAction Stop
        $result.Camera = [bool]($devices | Where-Object { $_.Class -eq 'Camera' -or $_.Class -eq 'Image' })
        $result.Microphone = [bool]($devices | Where-Object { $_.Class -eq 'AudioEndpoint' -and $_.FriendlyName -match 'Microphone' })
        $result.Speaker = [bool]($devices | Where-Object { $_.Class -eq 'AudioEndpoint' -and $_.FriendlyName -match 'Speaker' })
    }
    catch {
        Write-Verbose "PnP device query unavailable: $($_.Exception.Message)"
    }
    return [pscustomobject]$result
}

function Get-EndpointReadiness {
    <# Assembles the full readiness summary object. #>
    $os = Get-OperatingSystemInfo
    return [pscustomobject]@{
        CollectedAtUtc       = (Get-Date).ToUniversalTime().ToString('s') + 'Z'
        OperatingSystem      = $os.Name
        OsVersion            = $os.Version
        OsBuild              = $os.Build
        SystemDriveFreeGb    = Get-SystemDriveFreeGb
        NetworkConnected     = Test-NetworkConnectivity
        WindowsUpdateService = Get-WindowsUpdateServiceState
        AudioVisualDevices   = Get-AudioVisualDevicePresence
    }
}

# --- Main -----------------------------------------------------------------
try {
    $summary = Get-EndpointReadiness

    if ($AsJson) {
        $summary | ConvertTo-Json -Depth 4
    }
    else {
        Write-Host 'Endpoint readiness summary (read-only)'
        Write-Host '======================================'
        $summary | Format-List | Out-String | Write-Host
        Write-Host 'Note: sanitised reference implementation. No changes were made.'
    }
    exit 0
}
catch {
    Write-Error "Failed to collect endpoint readiness: $($_.Exception.Message)"
    exit 1
}

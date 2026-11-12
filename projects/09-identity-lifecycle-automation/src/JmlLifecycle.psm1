<#
.SYNOPSIS
    Joiner, mover and leaver (JML) automation for Microsoft Entra ID and
    Microsoft 365 with Microsoft Graph PowerShell.

.DESCRIPTION
    Lab module with four public functions:
      - Get-JmlActions     plans the actions for one HR record (no Graph calls)
      - Invoke-JmlAction   runs one planned action (supports -WhatIf)
      - Invoke-JmlRun      reads the HR feed, plans and runs every row
      - Test-LeaverAccess  checks that a leaver is disabled and has no groups

    Access comes from groups only: one department security group
    (SG-Dept-<Department>) and one licence group (group-based licensing, for
    example LIC-M365-BusinessPremium).

    Tested with Pester mocks and synthetic data only. Running it for real needs
    a Microsoft 365 tenant and the permissions listed in README.md.

.NOTES
    Written for PowerShell 7 on Windows and Linux. Sanitised reference
    implementation for portfolio purposes.
#>

Set-StrictMode -Version Latest

$script:ValidStatuses = @('Joiner', 'Mover', 'Leaver')
$script:DepartmentGroupPrefix = 'SG-Dept-'
$script:LicenceGroupPrefix = 'LIC-'
$script:DistributionListPrefix = 'DL-'
$script:DateFormat = 'yyyy-MM-dd'

#region Private helpers

function Get-JmlField {
    # Import-Csv gives empty strings, hand-built records may give $null or miss
    # the column; under StrictMode a missing property would throw, so read it here.
    param($Record, [string]$Name)

    $property = $Record.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) { return '' }
    return ([string]$property.Value).Trim()
}

function ConvertTo-JmlDate {
    param([string]$Text)

    $parsed = [datetime]::MinValue
    $ok = [datetime]::TryParseExact($Text, $script:DateFormat,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None, [ref]$parsed)
    if ($ok) { return $parsed }
    return $null
}

function Get-JmlUpn {
    param([string]$DisplayName, [string]$UpnSuffix)

    # Strip accents (Sean with an acute a -> sean) before dropping anything
    # that is not a-z, 0-9 or a space, so names never produce an invalid UPN.
    $decomposed = $DisplayName.Normalize([Text.NormalizationForm]::FormD)
    $baseLetters = -join ($decomposed.ToCharArray() | Where-Object {
            [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark
        })
    $localPart = (($baseLetters.ToLowerInvariant() -replace '[^a-z0-9 ]', '').Trim()) -replace '\s+', '.'
    if (-not $localPart) {
        throw "Cannot build a user principal name from display name '$DisplayName'."
    }
    return "$localPart@$UpnSuffix"
}

function Get-JmlDepartmentGroup {
    param([string]$Department)

    return $script:DepartmentGroupPrefix + ($Department -replace '\s', '')
}

function Assert-JmlRecord {
    # Collects every problem in the row, so one ticket can fix the whole row.
    param([Parameter(Mandatory)] $Record)

    $problems = New-Object System.Collections.Generic.List[string]

    $employeeId = Get-JmlField $Record 'EmployeeId'
    $displayName = Get-JmlField $Record 'DisplayName'
    $status = Get-JmlField $Record 'Status'
    $department = Get-JmlField $Record 'Department'
    $country = Get-JmlField $Record 'Country'
    $manager = Get-JmlField $Record 'Manager'
    $startDateText = Get-JmlField $Record 'StartDate'
    $endDateText = Get-JmlField $Record 'EndDate'

    # EmployeeId goes into a Graph $filter, so only letters, digits and hyphens.
    if ($employeeId -notmatch '^[A-Za-z0-9-]{1,20}$') {
        $problems.Add('EmployeeId is missing or has invalid characters.')
    }
    if ($displayName -notmatch '[A-Za-z]') {
        $problems.Add('DisplayName is missing.')
    }
    if ($script:ValidStatuses -notcontains $status) {
        $problems.Add("Status '$status' is not Joiner, Mover or Leaver.")
    }
    if ($status -in @('Joiner', 'Mover') -and $department -notmatch '^[A-Za-z][A-Za-z ]*$') {
        $problems.Add('Department is missing or has characters other than letters and spaces.')
    }
    if ($status -eq 'Joiner' -and -not $country) {
        $problems.Add('Country is required for a joiner (it sets the usage location).')
    }
    if ($country -and $country -cnotmatch '^[A-Z]{2}$') {
        $problems.Add("Country '$country' is not a two-letter ISO code such as IE.")
    }
    if ($manager -and $manager -notmatch '^[^@\s]+@[^@\s]+$') {
        $problems.Add("Manager '$manager' is not a user principal name.")
    }

    $startDate = $null
    if ($startDateText) {
        $startDate = ConvertTo-JmlDate $startDateText
        if (-not $startDate) { $problems.Add("StartDate '$startDateText' is not in yyyy-MM-dd format.") }
    }
    elseif ($status -eq 'Joiner') {
        $problems.Add('StartDate is required for a joiner.')
    }

    $endDate = $null
    if ($endDateText) {
        $endDate = ConvertTo-JmlDate $endDateText
        if (-not $endDate) { $problems.Add("EndDate '$endDateText' is not in yyyy-MM-dd format.") }
    }
    elseif ($status -eq 'Leaver') {
        $problems.Add('EndDate is required for a leaver.')
    }

    if ($startDate -and $endDate -and $endDate -lt $startDate) {
        $problems.Add('EndDate is before StartDate.')
    }

    if ($problems.Count -gt 0) {
        throw ('Invalid HR record: ' + ($problems -join ' '))
    }
}

function New-JmlAction {
    param(
        [string]$EmployeeId,
        [string]$UserPrincipalName,
        [string]$Type,
        [string]$Target,
        [hashtable]$Parameters = @{}
    )

    [pscustomobject]@{
        Step              = 0
        EmployeeId        = $EmployeeId
        UserPrincipalName = $UserPrincipalName
        Type              = $Type
        Target            = $Target
        Parameters        = $Parameters
    }
}

function New-JmlLogEntry {
    # Action parameters are left out on purpose: the log only needs what was
    # done to whom, and keeping it this narrow means nothing sensitive can leak.
    param($Action, [string]$Result, [string]$Message)

    [pscustomobject]@{
        Timestamp         = [datetime]::UtcNow.ToString('o')
        EmployeeId        = $Action.EmployeeId
        UserPrincipalName = $Action.UserPrincipalName
        Step              = $Action.Step
        Action            = $Action.Type
        Target            = $Action.Target
        Result            = $Result
        Message           = $Message
    }
}

function New-JmlException {
    param($Record, [int]$Row, [string]$FailedAction, [string]$Target, [string]$Reason)

    $status = Get-JmlField $Record 'Status'
    $displayName = Get-JmlField $Record 'DisplayName'
    $employeeId = Get-JmlField $Record 'EmployeeId'

    # A failed leaver may still have access, so it goes to the top of the queue.
    $priority = 'Medium'
    if ($status -eq 'Leaver') { $priority = 'High' }

    [pscustomobject]@{
        Timestamp      = [datetime]::UtcNow.ToString('o')
        Row            = $Row
        EmployeeId     = $employeeId
        DisplayName    = $displayName
        Status         = $status
        Manager        = Get-JmlField $Record 'Manager'
        FailedAction   = $FailedAction
        Target         = $Target
        Reason         = $Reason
        TicketPriority = $priority
        TicketSummary  = "JML exception: $status $displayName ($employeeId) - $FailedAction failed"
    }
}

function New-JmlTemporaryPassword {
    # Never shown or logged. The new starter signs in with a Temporary Access
    # Pass issued by the service desk, so nobody needs to know this value.
    $bytes = New-Object byte[] 24
    $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $generator.GetBytes($bytes) } finally { $generator.Dispose() }
    # Base64 alone is not guaranteed to contain every character class, so a
    # fixed suffix makes sure the Entra ID complexity rule always passes.
    return [Convert]::ToBase64String($bytes) + 'Aa1!'
}

function Get-JmlDirectoryObjectName {
    param($DirectoryObject)

    $extra = $DirectoryObject.PSObject.Properties['AdditionalProperties']
    if ($extra -and $extra.Value -and $extra.Value['displayName']) {
        return [string]$extra.Value['displayName']
    }
    return [string]$DirectoryObject.Id
}

function Resolve-JmlGroupId {
    param([string]$Name)

    $escapedName = $Name -replace "'", "''"
    $groups = @(Get-MgGroup -Filter "displayName eq '$escapedName'" -Property 'id,displayName' -ErrorAction Stop |
            Where-Object { $_ })
    if ($groups.Count -ne 1) {
        throw "Expected one group named '$Name', found $($groups.Count)."
    }
    return $groups[0].Id
}

function Resolve-JmlUserId {
    param([string]$UserId)

    return (Get-MgUser -UserId $UserId -Property 'id' -ErrorAction Stop).Id
}

function Get-JmlCurrentState {
    param([string]$EmployeeId)

    $users = @(Get-MgUser -Filter "employeeId eq '$EmployeeId'" `
            -Property 'id,userPrincipalName,accountEnabled,department' -ErrorAction Stop |
            Where-Object { $_ })
    if ($users.Count -eq 0) { return $null }
    if ($users.Count -gt 1) {
        throw "More than one account has employeeId '$EmployeeId'. Fix the duplicate before running JML."
    }

    $user = $users[0]
    $groups = @(Get-MgUserMemberOf -UserId $user.Id -All -ErrorAction Stop |
            Where-Object { $_ } |
            ForEach-Object { Get-JmlDirectoryObjectName $_ })

    [pscustomobject]@{
        Id                = $user.Id
        UserPrincipalName = $user.UserPrincipalName
        AccountEnabled    = $user.AccountEnabled
        Department        = $user.Department
        Groups            = $groups
    }
}

#endregion

function Get-JmlActions {
    <#
    .SYNOPSIS
        Plans the ordered JML actions for one HR record. Makes no Graph calls.

    .PARAMETER Record
        One HR feed row: EmployeeId, DisplayName, Department, JobTitle, Manager,
        StartDate, EndDate, Status (Joiner, Mover or Leaver) and Country.

    .PARAMETER CurrentState
        The account as it is now: Id, UserPrincipalName, AccountEnabled,
        Department and Groups (display names). $null when no account exists.

    .PARAMETER AsOf
        Leavers are only planned once their EndDate is on or before this date.

    .EXAMPLE
        Get-JmlActions -Record $row -CurrentState $null
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Record,

        [psobject]$CurrentState,

        [string]$UpnSuffix = 'contoso.com',

        [string]$LicenceGroup = 'LIC-M365-BusinessPremium',

        [datetime]$AsOf = (Get-Date).Date
    )

    Assert-JmlRecord -Record $Record

    $employeeId = Get-JmlField $Record 'EmployeeId'
    $status = Get-JmlField $Record 'Status'
    $department = Get-JmlField $Record 'Department'
    $jobTitle = Get-JmlField $Record 'JobTitle'
    $manager = Get-JmlField $Record 'Manager'

    $currentGroups = @()
    if ($CurrentState -and $CurrentState.Groups) { $currentGroups = @($CurrentState.Groups) }

    $planned = New-Object System.Collections.Generic.List[object]

    switch ($status) {
        'Joiner' {
            if ($CurrentState) {
                # Re-running a joiner must not create a second account; only
                # the missing steps are planned.
                $upn = $CurrentState.UserPrincipalName
            }
            else {
                $upn = Get-JmlUpn -DisplayName (Get-JmlField $Record 'DisplayName') -UpnSuffix $UpnSuffix
                $createParameters = @{
                    DisplayName  = Get-JmlField $Record 'DisplayName'
                    MailNickname = $upn.Split('@')[0]
                    Department   = $department
                    JobTitle     = $jobTitle
                    EmployeeId   = $employeeId
                }
                $planned.Add((New-JmlAction $employeeId $upn 'CreateUser' $upn $createParameters))
            }

            # Usage location must be set before the licence group, or
            # group-based licensing cannot assign the licence.
            $planned.Add((New-JmlAction $employeeId $upn 'SetUsageLocation' (Get-JmlField $Record 'Country')))
            if ($manager) {
                $planned.Add((New-JmlAction $employeeId $upn 'SetManager' $manager))
            }

            $departmentGroup = Get-JmlDepartmentGroup $department
            if ($currentGroups -notcontains $departmentGroup) {
                $planned.Add((New-JmlAction $employeeId $upn 'AddToGroup' $departmentGroup))
            }
            if ($currentGroups -notcontains $LicenceGroup) {
                $planned.Add((New-JmlAction $employeeId $upn 'AssignLicenceGroup' $LicenceGroup))
            }
        }

        'Mover' {
            if (-not $CurrentState) {
                throw "Mover $employeeId has no account in Entra ID."
            }
            $upn = $CurrentState.UserPrincipalName
            $newDepartmentGroup = Get-JmlDepartmentGroup $department

            $planned.Add((New-JmlAction $employeeId $upn 'UpdateProfile' $upn @{
                        Department = $department
                        JobTitle   = $jobTitle
                    }))

            # New access first, then remove the old: if the run stops in
            # between, the person can still work and the exception ticket
            # tells the service desk which removal is still open.
            if ($currentGroups -notcontains $newDepartmentGroup) {
                $planned.Add((New-JmlAction $employeeId $upn 'AddToGroup' $newDepartmentGroup))
            }
            foreach ($group in $currentGroups) {
                if ($group -like "$($script:DepartmentGroupPrefix)*" -and $group -ne $newDepartmentGroup) {
                    $planned.Add((New-JmlAction $employeeId $upn 'RemoveFromGroup' $group))
                }
            }
            if ($manager) {
                $planned.Add((New-JmlAction $employeeId $upn 'SetManager' $manager))
            }
        }

        'Leaver' {
            if (-not $CurrentState) {
                throw "Leaver $employeeId has no account in Entra ID."
            }
            $endDate = ConvertTo-JmlDate (Get-JmlField $Record 'EndDate')
            if ($endDate -gt $AsOf) {
                Write-Verbose "Leaver $employeeId ends on $($endDate.ToString($script:DateFormat)); nothing to do yet."
                return
            }
            $upn = $CurrentState.UserPrincipalName

            # Block sign-in and revoke sessions first so access ends at once;
            # everything after is tidy-up.
            $planned.Add((New-JmlAction $employeeId $upn 'BlockSignIn' $upn))
            $planned.Add((New-JmlAction $employeeId $upn 'RevokeSessions' $upn))
            # Convert before the licence goes, otherwise the mailbox is
            # removed with the licence.
            $planned.Add((New-JmlAction $employeeId $upn 'ConvertMailboxToShared' $upn))
            foreach ($group in $currentGroups) {
                if ($group -like "$($script:LicenceGroupPrefix)*") {
                    $planned.Add((New-JmlAction $employeeId $upn 'RemoveLicenceGroup' $group))
                }
            }
            foreach ($group in $currentGroups) {
                if ($group -notlike "$($script:LicenceGroupPrefix)*" -and $group -notlike "$($script:DistributionListPrefix)*") {
                    $planned.Add((New-JmlAction $employeeId $upn 'RemoveFromGroup' $group))
                }
            }
            # Graph cannot change distribution list membership; Exchange
            # Online owns it, so these get their own action type.
            foreach ($group in $currentGroups) {
                if ($group -like "$($script:DistributionListPrefix)*") {
                    $planned.Add((New-JmlAction $employeeId $upn 'RemoveFromDistributionList' $group))
                }
            }
            $planned.Add((New-JmlAction $employeeId $upn 'RaiseDeviceReturnTicket' $upn))
        }
    }

    $step = 0
    foreach ($action in $planned) {
        $step++
        $action.Step = $step
        $action
    }
}

function Invoke-JmlAction {
    <#
    .SYNOPSIS
        Runs one planned JML action with Microsoft Graph PowerShell.

    .DESCRIPTION
        Returns a log object (Timestamp, EmployeeId, UserPrincipalName, Step,
        Action, Target, Result, Message). With -WhatIf nothing is called and
        Result is WhatIf. On failure the error is thrown to the caller, which
        decides whether to continue.

        ConvertMailboxToShared and RemoveFromDistributionList use Set-Mailbox
        and Remove-DistributionGroupMember from the Exchange Online PowerShell
        module, because Microsoft Graph cannot convert a mailbox or change
        distribution list membership.

    .EXAMPLE
        Get-JmlActions -Record $row -CurrentState $state | Invoke-JmlAction -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [psobject]$Action
    )

    process {
        $upn = $Action.UserPrincipalName
        if (-not $PSCmdlet.ShouldProcess($upn, "$($Action.Type) $($Action.Target)")) {
            return New-JmlLogEntry -Action $Action -Result 'WhatIf' -Message 'Not run (-WhatIf).'
        }

        $result = 'Done'
        $message = ''

        switch ($Action.Type) {
            'CreateUser' {
                $newUser = @{
                    DisplayName       = $Action.Parameters.DisplayName
                    UserPrincipalName = $upn
                    MailNickname      = $Action.Parameters.MailNickname
                    AccountEnabled    = $true
                    EmployeeId        = $Action.Parameters.EmployeeId
                    PasswordProfile   = @{
                        Password                      = New-JmlTemporaryPassword
                        ForceChangePasswordNextSignIn = $true
                    }
                }
                # Graph rejects empty strings for these, so only send them when set.
                foreach ($name in @('Department', 'JobTitle')) {
                    if ($Action.Parameters[$name]) { $newUser[$name] = $Action.Parameters[$name] }
                }
                New-MgUser @newUser -ErrorAction Stop | Out-Null
                $message = 'Account created. Issue a Temporary Access Pass for first sign-in.'
            }
            'SetUsageLocation' {
                Update-MgUser -UserId $upn -UsageLocation $Action.Target -ErrorAction Stop
            }
            'SetManager' {
                $managerId = Resolve-JmlUserId $Action.Target
                Set-MgUserManagerByRef -UserId $upn -BodyParameter @{
                    '@odata.id' = "https://graph.microsoft.com/v1.0/users/$managerId"
                } -ErrorAction Stop
            }
            'UpdateProfile' {
                $profileUpdate = @{ UserId = $upn }
                foreach ($name in @('Department', 'JobTitle')) {
                    if ($Action.Parameters[$name]) { $profileUpdate[$name] = $Action.Parameters[$name] }
                }
                Update-MgUser @profileUpdate -ErrorAction Stop
            }
            { $_ -in @('AddToGroup', 'AssignLicenceGroup') } {
                New-MgGroupMember -GroupId (Resolve-JmlGroupId $Action.Target) `
                    -DirectoryObjectId (Resolve-JmlUserId $upn) -ErrorAction Stop
            }
            { $_ -in @('RemoveFromGroup', 'RemoveLicenceGroup') } {
                Remove-MgGroupMemberByRef -GroupId (Resolve-JmlGroupId $Action.Target) `
                    -DirectoryObjectId (Resolve-JmlUserId $upn) -ErrorAction Stop
            }
            'BlockSignIn' {
                Update-MgUser -UserId $upn -AccountEnabled:$false -ErrorAction Stop
            }
            'RevokeSessions' {
                Revoke-MgUserSignInSession -UserId $upn -ErrorAction Stop | Out-Null
            }
            'ConvertMailboxToShared' {
                Set-Mailbox -Identity $upn -Type Shared -ErrorAction Stop
            }
            'RemoveFromDistributionList' {
                Remove-DistributionGroupMember -Identity $Action.Target -Member $upn -Confirm:$false -ErrorAction Stop
            }
            'RaiseDeviceReturnTicket' {
                # Device wipe and return are done by people (see README), so
                # this step only hands over to the service desk.
                $result = 'Handoff'
                $message = 'Raise a device return ticket: collect, wipe and return the device to stock.'
            }
            default {
                throw "Unknown action type '$($Action.Type)'."
            }
        }

        New-JmlLogEntry -Action $Action -Result $result -Message $message
    }
}

function Invoke-JmlRun {
    <#
    .SYNOPSIS
        Reads the HR feed, plans every row and runs the actions.

    .DESCRIPTION
        Dry run (-WhatIf) unless -Apply is given. Writes to OutputDirectory:
          - jml-log-<time>.csv            every action and its result
          - jml-exceptions-<time>.csv     rejected rows and failed actions, one
                                          line per ticket (only when there are any)
          - jml-device-returns-<time>.csv leavers whose device must come back
                                          (only when there are any)
        A failed action stops the remaining steps for that person only; the
        run continues with the next row.

    .EXAMPLE
        Invoke-JmlRun -Path ./sample-data/hr-feed.csv -OutputDirectory ./out

    .EXAMPLE
        Invoke-JmlRun -Path ./hr-feed.csv -OutputDirectory ./out -Apply
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$OutputDirectory = (Get-Location).Path,

        [switch]$Apply,

        [string]$UpnSuffix = 'contoso.com',

        [string]$LicenceGroup = 'LIC-M365-BusinessPremium',

        [datetime]$AsOf = (Get-Date).Date
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "HR feed not found: $Path"
    }
    if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
        throw "Output directory not found: $OutputDirectory"
    }

    # A wrong HR row should be seen in a plan before it changes the tenant,
    # so nothing is written to Entra ID unless -Apply is given.
    $dryRun = [bool]$WhatIfPreference -or -not $Apply

    $rows = @(Import-Csv -LiteralPath $Path)
    $log = New-Object System.Collections.Generic.List[object]
    $exceptions = New-Object System.Collections.Generic.List[object]
    $deviceReturns = New-Object System.Collections.Generic.List[object]

    $rowNumber = 1 # line 1 is the header
    foreach ($row in $rows) {
        $rowNumber++
        $rowAction = New-JmlAction -EmployeeId (Get-JmlField $row 'EmployeeId') -Type 'Plan' -Target "row $rowNumber"

        try {
            Assert-JmlRecord -Record $row
            $state = Get-JmlCurrentState -EmployeeId (Get-JmlField $row 'EmployeeId')
            $actions = @(Get-JmlActions -Record $row -CurrentState $state -UpnSuffix $UpnSuffix `
                    -LicenceGroup $LicenceGroup -AsOf $AsOf)
        }
        catch {
            $log.Add((New-JmlLogEntry -Action $rowAction -Result 'Rejected' -Message $_.Exception.Message))
            $exceptions.Add((New-JmlException -Record $row -Row $rowNumber -FailedAction 'Plan' `
                        -Target "row $rowNumber" -Reason $_.Exception.Message))
            continue
        }

        if ($actions.Count -eq 0) {
            $log.Add((New-JmlLogEntry -Action $rowAction -Result 'Skipped' -Message 'Nothing to do yet.'))
            continue
        }

        foreach ($action in $actions) {
            try {
                $entry = Invoke-JmlAction -Action $action -WhatIf:$dryRun
                $log.Add($entry)
                if ($entry.Result -eq 'Handoff') {
                    $deviceReturns.Add([pscustomobject]@{
                            EmployeeId        = $action.EmployeeId
                            DisplayName       = Get-JmlField $row 'DisplayName'
                            UserPrincipalName = $action.UserPrincipalName
                            Manager           = Get-JmlField $row 'Manager'
                            EndDate           = Get-JmlField $row 'EndDate'
                            Country           = Get-JmlField $row 'Country'
                        })
                }
            }
            catch {
                $log.Add((New-JmlLogEntry -Action $action -Result 'Failed' -Message $_.Exception.Message))
                $exceptions.Add((New-JmlException -Record $row -Row $rowNumber -FailedAction $action.Type `
                            -Target $action.Target -Reason $_.Exception.Message))
                # Later steps depend on earlier ones (a group add needs the
                # account), so stop this person and go on to the next row.
                break
            }
        }
    }

    $stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $logPath = Join-Path $OutputDirectory "jml-log-$stamp.csv"
    $exceptionsPath = $null
    $deviceReturnsPath = $null

    # -WhatIf:$false because these are local report files: a dry run must
    # still show its plan and its rejected rows.
    $log | Export-Csv -LiteralPath $logPath -NoTypeInformation -Encoding UTF8 -WhatIf:$false
    if ($exceptions.Count -gt 0) {
        $exceptionsPath = Join-Path $OutputDirectory "jml-exceptions-$stamp.csv"
        $exceptions | Export-Csv -LiteralPath $exceptionsPath -NoTypeInformation -Encoding UTF8 -WhatIf:$false
    }
    if ($deviceReturns.Count -gt 0) {
        $deviceReturnsPath = Join-Path $OutputDirectory "jml-device-returns-$stamp.csv"
        $deviceReturns | Export-Csv -LiteralPath $deviceReturnsPath -NoTypeInformation -Encoding UTF8 -WhatIf:$false
    }

    [pscustomobject]@{
        DryRun            = $dryRun
        Rows              = $rows.Count
        Log               = $log.ToArray()
        Exceptions        = $exceptions.ToArray()
        LogPath           = $logPath
        ExceptionsPath    = $exceptionsPath
        DeviceReturnsPath = $deviceReturnsPath
    }
}

function Test-LeaverAccess {
    <#
    .SYNOPSIS
        Checks that a leaver is disabled and is no longer a member of any group.

    .DESCRIPTION
        Read-only. Passed is $true only when the account is disabled and has
        no direct memberships (groups or directory roles) left.

    .EXAMPLE
        Test-LeaverAccess -UserId liam.byrne@contoso.com
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$UserId
    )

    process {
        $user = Get-MgUser -UserId $UserId -Property 'id,userPrincipalName,accountEnabled' -ErrorAction Stop
        $memberships = @(Get-MgUserMemberOf -UserId $user.Id -All -ErrorAction Stop |
                Where-Object { $_ } |
                ForEach-Object { Get-JmlDirectoryObjectName $_ })

        $problems = @()
        if ($user.AccountEnabled) { $problems += 'Account is still enabled.' }
        if ($memberships.Count -gt 0) {
            $problems += "Still a member of $($memberships.Count) group(s): $($memberships -join ', ')."
        }

        [pscustomobject]@{
            UserPrincipalName = $user.UserPrincipalName
            AccountEnabled    = [bool]$user.AccountEnabled
            Memberships       = $memberships
            Passed            = ($problems.Count -eq 0)
            Problems          = $problems
        }
    }
}

Export-ModuleMember -Function Get-JmlActions, Invoke-JmlAction, Invoke-JmlRun, Test-LeaverAccess

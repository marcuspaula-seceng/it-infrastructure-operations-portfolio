<#
    Pester 5+ tests for JmlLifecycle.psm1.

    No tenant is used. Every Microsoft Graph and Exchange Online cmdlet is
    mocked. When the Microsoft.Graph or ExchangeOnlineManagement modules are
    not installed, a stub with the same parameter names is defined first,
    because Pester can only mock a command that exists. Each stub throws, so a
    call that was not mocked fails the test instead of passing silently.
#>

BeforeAll {
    $script:GraphStubs = [ordered]@{
        'Get-MgUser'                     = '[CmdletBinding()] param($UserId, $Filter, $Property, [switch]$All)'
        'Get-MgUserMemberOf'             = '[CmdletBinding()] param($UserId, [switch]$All)'
        'Get-MgGroup'                    = '[CmdletBinding()] param($Filter, $Property)'
        'New-MgUser'                     = '[CmdletBinding()] param($DisplayName, $UserPrincipalName, $MailNickname, [switch]$AccountEnabled, $PasswordProfile, $Department, $JobTitle, $EmployeeId)'
        'Update-MgUser'                  = '[CmdletBinding()] param($UserId, $UsageLocation, [switch]$AccountEnabled, $Department, $JobTitle)'
        'Set-MgUserManagerByRef'         = '[CmdletBinding()] param($UserId, $BodyParameter)'
        'New-MgGroupMember'              = '[CmdletBinding()] param($GroupId, $DirectoryObjectId)'
        'Remove-MgGroupMemberByRef'      = '[CmdletBinding()] param($GroupId, $DirectoryObjectId)'
        'Revoke-MgUserSignInSession'     = '[CmdletBinding()] param($UserId)'
        'Set-Mailbox'                    = '[CmdletBinding()] param($Identity, $Type)'
        'Remove-DistributionGroupMember' = '[CmdletBinding(SupportsShouldProcess)] param($Identity, $Member)'
    }
    $script:CreatedStubs = @()
    foreach ($name in $script:GraphStubs.Keys) {
        if (-not (Get-Command -Name $name -ErrorAction SilentlyContinue)) {
            $body = "$($script:GraphStubs[$name]) throw 'Stub for $name was called without a mock.'"
            Set-Item -Path "function:global:$name" -Value ([scriptblock]::Create($body))
            $script:CreatedStubs += $name
        }
    }

    # Cmdlets that change the tenant. Reads (Get-*) are allowed in a dry run.
    $script:WriteCmdlets = @(
        'New-MgUser', 'Update-MgUser', 'Set-MgUserManagerByRef', 'New-MgGroupMember',
        'Remove-MgGroupMemberByRef', 'Revoke-MgUserSignInSession', 'Set-Mailbox',
        'Remove-DistributionGroupMember'
    )

    $projectRoot = Split-Path -Parent $PSScriptRoot
    Import-Module (Join-Path $projectRoot 'src/JmlLifecycle.psm1') -Force
    $script:SampleFeed = Join-Path $projectRoot 'sample-data/hr-feed.csv'
    $script:AsOf = [datetime]'2026-11-12'

    function New-HrRecord {
        param([hashtable]$Override = @{})

        $record = [ordered]@{
            EmployeeId  = 'E1001'
            DisplayName = 'Jane Doe'
            Department  = 'Finance'
            JobTitle    = 'Accounts Payable Clerk'
            Manager     = 'finance.lead@contoso.com'
            StartDate   = '2026-12-01'
            EndDate     = ''
            Status      = 'Joiner'
            Country     = 'IE'
        }
        foreach ($key in $Override.Keys) { $record[$key] = $Override[$key] }
        [pscustomobject]$record
    }

    function New-State {
        param([string]$UserPrincipalName, [string[]]$Groups, [bool]$AccountEnabled = $true)

        [pscustomobject]@{
            Id                = "id-$UserPrincipalName"
            UserPrincipalName = $UserPrincipalName
            AccountEnabled    = $AccountEnabled
            Department        = ''
            Groups            = $Groups
        }
    }

    function New-GroupObject {
        param([string]$Name)

        [pscustomobject]@{ Id = "grp-$Name"; AdditionalProperties = @{ displayName = $Name } }
    }
}

AfterAll {
    Remove-Module JmlLifecycle -ErrorAction SilentlyContinue
    foreach ($name in $script:CreatedStubs) {
        Remove-Item -Path "function:global:$name" -ErrorAction SilentlyContinue
    }
}

Describe 'Get-JmlActions' {
    Context 'Joiner' {
        It 'plans account, usage location, manager, department group and licence group in that order' {
            $actions = @(Get-JmlActions -Record (New-HrRecord) -CurrentState $null)

            $actions.Type | Should -Be @('CreateUser', 'SetUsageLocation', 'SetManager', 'AddToGroup', 'AssignLicenceGroup')
            $actions[0].Target | Should -Be 'jane.doe@contoso.com'
            $actions[1].Target | Should -Be 'IE'
            $actions[3].Target | Should -Be 'SG-Dept-Finance'
            $actions[4].Target | Should -Be 'LIC-M365-BusinessPremium'
            $actions.Step | Should -Be @(1, 2, 3, 4, 5)
        }

        It 'builds a clean user principal name from a name with an accent and an apostrophe' {
            $name = "Se$([char]0x00E1)n O'Brien"
            $actions = @(Get-JmlActions -Record (New-HrRecord @{ DisplayName = $name }) -CurrentState $null)

            $actions[0].Target | Should -Be 'sean.obrien@contoso.com'
            $actions[0].Parameters.MailNickname | Should -Be 'sean.obrien'
        }

        It 'does not create a second account and skips groups already held when re-run' {
            $state = New-State 'jane.doe@contoso.com' @('SG-Dept-Finance')
            $actions = @(Get-JmlActions -Record (New-HrRecord) -CurrentState $state)

            $actions.Type | Should -Not -Contain 'CreateUser'
            $actions.Target | Should -Not -Contain 'SG-Dept-Finance'
            $actions.Type | Should -Contain 'AssignLicenceGroup'
        }
    }

    Context 'Mover' {
        BeforeAll {
            $script:MoverRecord = New-HrRecord @{
                EmployeeId = 'E0874'; DisplayName = 'Aoife Murphy'; Department = 'Finance'
                JobTitle = 'Financial Analyst'; StartDate = '2024-03-04'; Status = 'Mover'
            }
            $script:MoverState = New-State 'aoife.murphy@contoso.com' @(
                'SG-Dept-Sales', 'LIC-M365-BusinessPremium', 'DL-Dublin-Office')
        }

        It 'adds the new department group and removes the old one' {
            $actions = @(Get-JmlActions -Record $script:MoverRecord -CurrentState $script:MoverState)

            ($actions | Where-Object Type -EQ 'AddToGroup').Target | Should -Be 'SG-Dept-Finance'
            ($actions | Where-Object Type -EQ 'RemoveFromGroup').Target | Should -Be 'SG-Dept-Sales'
        }

        It 'keeps the licence group and groups that are not department groups' {
            $actions = @(Get-JmlActions -Record $script:MoverRecord -CurrentState $script:MoverState)

            $actions.Target | Should -Not -Contain 'LIC-M365-BusinessPremium'
            $actions.Target | Should -Not -Contain 'DL-Dublin-Office'
        }

        It 'adds new access before removing old access' {
            $types = @(Get-JmlActions -Record $script:MoverRecord -CurrentState $script:MoverState).Type

            [array]::IndexOf($types, 'AddToGroup') | Should -BeLessThan ([array]::IndexOf($types, 'RemoveFromGroup'))
        }

        It 'rejects a mover who has no account' {
            { Get-JmlActions -Record $script:MoverRecord -CurrentState $null } | Should -Throw '*has no account*'
        }
    }

    Context 'Leaver' {
        BeforeAll {
            $script:LeaverRecord = New-HrRecord @{
                EmployeeId = 'E0512'; DisplayName = 'Liam Byrne'; Department = 'Sales'
                StartDate = '2023-06-12'; EndDate = '2026-11-06'; Status = 'Leaver'
            }
            $script:LeaverState = New-State 'liam.byrne@contoso.com' @(
                'SG-Dept-Sales', 'LIC-M365-BusinessPremium', 'DL-Sales-Team')
        }

        It 'blocks sign-in and revokes sessions before anything else' {
            $actions = @(Get-JmlActions -Record $script:LeaverRecord -CurrentState $script:LeaverState -AsOf $script:AsOf)

            $actions[0].Type | Should -Be 'BlockSignIn'
            $actions[1].Type | Should -Be 'RevokeSessions'
        }

        It 'converts the mailbox before the licence is removed, then removes every group and raises a device ticket' {
            $actions = @(Get-JmlActions -Record $script:LeaverRecord -CurrentState $script:LeaverState -AsOf $script:AsOf)

            $actions.Type | Should -Be @(
                'BlockSignIn', 'RevokeSessions', 'ConvertMailboxToShared', 'RemoveLicenceGroup',
                'RemoveFromGroup', 'RemoveFromDistributionList', 'RaiseDeviceReturnTicket')
            ($actions | Where-Object Type -EQ 'RemoveLicenceGroup').Target | Should -Be 'LIC-M365-BusinessPremium'
            ($actions | Where-Object Type -EQ 'RemoveFromGroup').Target | Should -Be 'SG-Dept-Sales'
            ($actions | Where-Object Type -EQ 'RemoveFromDistributionList').Target | Should -Be 'DL-Sales-Team'
        }

        It 'plans nothing before the end date' {
            $actions = @(Get-JmlActions -Record $script:LeaverRecord -CurrentState $script:LeaverState -AsOf ([datetime]'2026-11-01'))

            $actions.Count | Should -Be 0
        }
    }

    Context 'Invalid rows' {
        It 'rejects a row where <Case>' -TestCases @(
            @{ Case = 'EmployeeId is missing'; Override = @{ EmployeeId = '' }; Expected = '*EmployeeId*' }
            @{ Case = 'EmployeeId would break the Graph filter'; Override = @{ EmployeeId = "E1' or 1 eq 1" }; Expected = '*EmployeeId*' }
            @{ Case = 'Status is unknown'; Override = @{ Status = 'Contractor' }; Expected = '*Status*' }
            @{ Case = 'a joiner has no StartDate'; Override = @{ StartDate = '' }; Expected = '*StartDate*' }
            @{ Case = 'Country is not an ISO code'; Override = @{ Country = 'Ireland' }; Expected = '*Country*' }
            @{ Case = 'a leaver has no EndDate'; Override = @{ Status = 'Leaver' }; Expected = '*EndDate*' }
            @{ Case = 'the date format is wrong'; Override = @{ StartDate = '01/12/2026' }; Expected = '*yyyy-MM-dd*' }
        ) {
            param($Case, $Override, $Expected)

            { Get-JmlActions -Record (New-HrRecord $Override) -CurrentState $null } | Should -Throw $Expected
        }
    }
}

Describe 'Invoke-JmlAction' {
    BeforeAll {
        $script:CreateAction = (Get-JmlActions -Record (New-HrRecord) -CurrentState $null)[0]
        $script:BlockAction = [pscustomobject]@{
            Step = 1; EmployeeId = 'E0512'; UserPrincipalName = 'liam.byrne@contoso.com'
            Type = 'BlockSignIn'; Target = 'liam.byrne@contoso.com'; Parameters = @{}
        }
        $script:GroupAction = [pscustomobject]@{
            Step = 4; EmployeeId = 'E1001'; UserPrincipalName = 'jane.doe@contoso.com'
            Type = 'AddToGroup'; Target = 'SG-Dept-Finance'; Parameters = @{}
        }
    }

    BeforeEach {
        foreach ($name in $script:GraphStubs.Keys) { Mock $name -ModuleName JmlLifecycle { } }
        Mock Get-MgUser -ModuleName JmlLifecycle { [pscustomobject]@{ Id = "id-$UserId" } }
        Mock Get-MgGroup -ModuleName JmlLifecycle {
            if ($Filter -match "displayName eq '(.+)'") { [pscustomobject]@{ Id = "grp-$($Matches[1])" } }
        }
    }

    It 'makes no Graph or Exchange call with -WhatIf' {
        $entry = Invoke-JmlAction -Action $script:CreateAction -WhatIf

        $entry.Result | Should -Be 'WhatIf'
        foreach ($name in $script:GraphStubs.Keys) {
            Should -Invoke $name -ModuleName JmlLifecycle -Times 0 -Exactly
        }
    }

    It 'creates the user with a forced password change and never puts the password in the log' {
        $entry = Invoke-JmlAction -Action $script:CreateAction
        $logText = $entry | ConvertTo-Json -Compress

        $entry.Result | Should -Be 'Done'
        Should -Invoke New-MgUser -ModuleName JmlLifecycle -Times 1 -Exactly -ParameterFilter {
            $UserPrincipalName -eq 'jane.doe@contoso.com' -and
            $PasswordProfile.ForceChangePasswordNextSignIn -eq $true -and
            $PasswordProfile.Password.Length -ge 16 -and
            -not $logText.Contains($PasswordProfile.Password)
        }
    }

    It 'blocks sign-in by disabling the account' {
        Invoke-JmlAction -Action $script:BlockAction | Out-Null

        Should -Invoke Update-MgUser -ModuleName JmlLifecycle -Times 1 -Exactly -ParameterFilter {
            $UserId -eq 'liam.byrne@contoso.com' -and $PesterBoundParameters.ContainsKey('AccountEnabled') -and -not $AccountEnabled
        }
    }

    It 'resolves group and user names to ids before adding the member' {
        Invoke-JmlAction -Action $script:GroupAction | Out-Null

        Should -Invoke New-MgGroupMember -ModuleName JmlLifecycle -Times 1 -Exactly -ParameterFilter {
            $GroupId -eq 'grp-SG-Dept-Finance' -and $DirectoryObjectId -eq 'id-jane.doe@contoso.com'
        }
    }

    It 'throws when the group does not exist, so the caller can raise an exception' {
        Mock Get-MgGroup -ModuleName JmlLifecycle { }

        { Invoke-JmlAction -Action $script:GroupAction } | Should -Throw "*found 0*"
        Should -Invoke New-MgGroupMember -ModuleName JmlLifecycle -Times 0 -Exactly
    }

    It 'hands the device return over to the service desk without calling Graph' {
        $ticketAction = [pscustomobject]@{
            Step = 7; EmployeeId = 'E0512'; UserPrincipalName = 'liam.byrne@contoso.com'
            Type = 'RaiseDeviceReturnTicket'; Target = 'liam.byrne@contoso.com'; Parameters = @{}
        }

        (Invoke-JmlAction -Action $ticketAction).Result | Should -Be 'Handoff'
        foreach ($name in $script:WriteCmdlets) {
            Should -Invoke $name -ModuleName JmlLifecycle -Times 0 -Exactly
        }
    }
}

Describe 'Invoke-JmlRun' {
    BeforeEach {
        foreach ($name in $script:GraphStubs.Keys) { Mock $name -ModuleName JmlLifecycle { } }

        # Synthetic tenant: Aoife (mover) and Liam (leaver) already exist,
        # Jane and Sara (joiners) do not.
        Mock Get-MgUser -ModuleName JmlLifecycle {
            switch ($Filter) {
                "employeeId eq 'E0874'" {
                    [pscustomobject]@{ Id = 'id-aoife'; UserPrincipalName = 'aoife.murphy@contoso.com'; AccountEnabled = $true; Department = 'Sales' }
                }
                "employeeId eq 'E0512'" {
                    [pscustomobject]@{ Id = 'id-liam'; UserPrincipalName = 'liam.byrne@contoso.com'; AccountEnabled = $true; Department = 'Sales' }
                }
            }
            if (-not $Filter) { [pscustomobject]@{ Id = "id-$UserId" } }
        }
        Mock Get-MgUserMemberOf -ModuleName JmlLifecycle {
            $names = switch ($UserId) {
                'id-aoife' { 'SG-Dept-Sales', 'LIC-M365-BusinessPremium', 'DL-Dublin-Office' }
                'id-liam' { 'SG-Dept-Sales', 'LIC-M365-BusinessPremium', 'DL-Sales-Team' }
            }
            foreach ($name in $names) { New-GroupObject $name }
        }
        Mock Get-MgGroup -ModuleName JmlLifecycle {
            if ($Filter -match "displayName eq '(.+)'") { [pscustomobject]@{ Id = "grp-$($Matches[1])" } }
        }

        $script:OutDir = Join-Path $TestDrive "run output $([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $script:OutDir | Out-Null
    }

    It 'is a dry run by default and changes nothing in the tenant' {
        $run = Invoke-JmlRun -Path $script:SampleFeed -OutputDirectory $script:OutDir -AsOf $script:AsOf

        $run.DryRun | Should -BeTrue
        $run.Rows | Should -Be 5
        ($run.Log | Where-Object Result -EQ 'WhatIf').Count | Should -BeGreaterThan 0
        $run.Log.Result | Should -Not -Contain 'Done'
        foreach ($name in $script:WriteCmdlets) {
            Should -Invoke $name -ModuleName JmlLifecycle -Times 0 -Exactly
        }
        Test-Path -LiteralPath $run.LogPath | Should -BeTrue
    }

    It 'rejects the invalid row and writes it to the exceptions CSV' {
        $run = Invoke-JmlRun -Path $script:SampleFeed -OutputDirectory $script:OutDir -AsOf $script:AsOf

        $rows = @(Import-Csv -LiteralPath $run.ExceptionsPath)
        $rows.Count | Should -Be 1
        $rows[0].DisplayName | Should -Be 'John Smith'
        $rows[0].Row | Should -Be '6'
        $rows[0].FailedAction | Should -Be 'Plan'
        $rows[0].Reason | Should -BeLike '*EmployeeId*'
    }

    It 'with -Apply logs a failed action as an exception and carries on with the other rows' {
        Mock New-MgUser -ModuleName JmlLifecycle -ParameterFilter { $DisplayName -eq 'Jane Doe' } {
            throw 'Simulated Graph error: 503 Service Unavailable'
        }

        $run = Invoke-JmlRun -Path $script:SampleFeed -OutputDirectory $script:OutDir -AsOf $script:AsOf -Apply

        $run.DryRun | Should -BeFalse
        $failed = @($run.Exceptions | Where-Object EmployeeId -EQ 'E1001')
        $failed.Count | Should -Be 1
        $failed[0].FailedAction | Should -Be 'CreateUser'
        $failed[0].Reason | Should -BeLike '*503*'
        $failed[0].TicketPriority | Should -Be 'Medium'

        # Jane stops at the failed step; everybody else still runs.
        Should -Invoke Update-MgUser -ModuleName JmlLifecycle -Times 0 -Exactly -ParameterFilter { $UserId -eq 'jane.doe@contoso.com' }
        Should -Invoke New-MgUser -ModuleName JmlLifecycle -Times 1 -Exactly -ParameterFilter { $DisplayName -eq 'Sara Costa' }
        Should -Invoke Remove-MgGroupMemberByRef -ModuleName JmlLifecycle -Times 1 -Exactly -ParameterFilter {
            $GroupId -eq 'grp-SG-Dept-Sales' -and $DirectoryObjectId -eq 'id-aoife.murphy@contoso.com'
        }
        Should -Invoke Revoke-MgUserSignInSession -ModuleName JmlLifecycle -Times 1 -Exactly
        Should -Invoke Remove-DistributionGroupMember -ModuleName JmlLifecycle -Times 1 -Exactly -ParameterFilter {
            $Identity -eq 'DL-Sales-Team' -and $Member -eq 'liam.byrne@contoso.com'
        }

        @(Import-Csv -LiteralPath $run.ExceptionsPath).Count | Should -Be 2
    }

    It 'with -Apply writes the leaver to the device returns CSV' {
        $run = Invoke-JmlRun -Path $script:SampleFeed -OutputDirectory $script:OutDir -AsOf $script:AsOf -Apply

        $returns = @(Import-Csv -LiteralPath $run.DeviceReturnsPath)
        $returns.Count | Should -Be 1
        $returns[0].UserPrincipalName | Should -Be 'liam.byrne@contoso.com'
    }

    It 'raises a high priority exception and stops the leaver when sign-in cannot be blocked' {
        Mock Update-MgUser -ModuleName JmlLifecycle -ParameterFilter { $UserId -eq 'liam.byrne@contoso.com' } {
            throw 'Simulated Graph error: Insufficient privileges'
        }

        $run = Invoke-JmlRun -Path $script:SampleFeed -OutputDirectory $script:OutDir -AsOf $script:AsOf -Apply

        $failed = @($run.Exceptions | Where-Object EmployeeId -EQ 'E0512')
        $failed[0].FailedAction | Should -Be 'BlockSignIn'
        $failed[0].TicketPriority | Should -Be 'High'
        Should -Invoke Revoke-MgUserSignInSession -ModuleName JmlLifecycle -Times 0 -Exactly
        $run.DeviceReturnsPath | Should -BeNullOrEmpty
    }
}

Describe 'Test-LeaverAccess' {
    BeforeEach {
        Mock Get-MgUser -ModuleName JmlLifecycle {
            [pscustomobject]@{ Id = 'id-liam'; UserPrincipalName = 'liam.byrne@contoso.com'; AccountEnabled = $false }
        }
        Mock Get-MgUserMemberOf -ModuleName JmlLifecycle { }
    }

    It 'passes when the account is disabled and has no memberships' {
        $check = Test-LeaverAccess -UserId 'liam.byrne@contoso.com'

        $check.Passed | Should -BeTrue
        $check.Problems.Count | Should -Be 0
    }

    It 'fails when the account is still enabled' {
        Mock Get-MgUser -ModuleName JmlLifecycle {
            [pscustomobject]@{ Id = 'id-liam'; UserPrincipalName = 'liam.byrne@contoso.com'; AccountEnabled = $true }
        }

        $check = Test-LeaverAccess -UserId 'liam.byrne@contoso.com'

        $check.Passed | Should -BeFalse
        $check.Problems | Should -Contain 'Account is still enabled.'
    }

    It 'fails and names the group when a membership is left' {
        Mock Get-MgUserMemberOf -ModuleName JmlLifecycle { New-GroupObject 'DL-Sales-Team' }

        $check = Test-LeaverAccess -UserId 'liam.byrne@contoso.com'

        $check.Passed | Should -BeFalse
        $check.Memberships | Should -Be @('DL-Sales-Team')
    }
}

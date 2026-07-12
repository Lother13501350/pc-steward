# pc-steward scanner: startup — every autostart entry with its enabled/disabled state. Read-only.
# Covers Run/RunOnce registry keys (HKCU, HKLM, WOW6432Node) and startup folders,
# cross-referenced against the StartupApproved keys (the mechanism behind Task
# Manager's enable/disable toggle) so stale or already-disabled entries are visible.
$ErrorActionPreference = 'SilentlyContinue'

function Get-ApprovedState([string]$approvedKey, [string]$name) {
    if (-not (Test-Path $approvedKey)) { return 'Enabled' }
    $val = (Get-ItemProperty $approvedKey -ErrorAction SilentlyContinue).$name
    if ($null -eq $val -or $val -isnot [byte[]] -or $val.Length -lt 1) { return 'Enabled' }
    if ($val[0] -band 1) { return 'Disabled' } else { return 'Enabled' }
}

$entries = New-Object System.Collections.Generic.List[object]

$runKeys = @(
    @{ path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
       scope = 'HKCU'
       approved = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' },
    @{ path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
       scope = 'HKCU-RunOnce'
       approved = $null },
    @{ path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
       scope = 'HKLM'
       approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' },
    @{ path = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
       scope = 'HKLM-32'
       approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32' }
)
foreach ($k in $runKeys) {
    if (-not (Test-Path $k.path)) { continue }
    (Get-ItemProperty $k.path).PSObject.Properties |
        Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
            $state = if ($k.approved) { Get-ApprovedState $k.approved $_.Name } else { 'Enabled' }
            $entries.Add(@{ name = $_.Name; scope = $k.scope; command = [string]$_.Value; state = $state })
        }
}

$folders = @(
    @{ path = [Environment]::GetFolderPath('Startup')
       scope = 'StartupFolder-User'
       approved = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder' },
    @{ path = [Environment]::GetFolderPath('CommonStartup')
       scope = 'StartupFolder-Common'
       approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder' }
)
foreach ($f in $folders) {
    if (-not $f.path -or -not (Test-Path $f.path)) { continue }
    Get-ChildItem $f.path -File | Where-Object { $_.Name -ne 'desktop.ini' } | ForEach-Object {
        $entries.Add(@{ name = $_.Name; scope = $f.scope; command = $_.FullName; state = (Get-ApprovedState $f.approved $_.Name) })
    }
}

[PSCustomObject]@{
    scanner      = 'startup'
    entries      = $entries
    enabledCount = @($entries | Where-Object { $_.state -eq 'Enabled' }).Count
} | ConvertTo-Json -Depth 4

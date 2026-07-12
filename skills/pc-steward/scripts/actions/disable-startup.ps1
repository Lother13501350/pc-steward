# pc-steward action: disable startup entries. Reversible by design.
#
# Backs up the relevant registry keys as .reg files, then marks entries disabled
# via the StartupApproved mechanism — the exact same thing Task Manager's
# "Disable" button does. Nothing is deleted. Undo with restore-startup.ps1 or by
# double-clicking the exported .reg backups.
#
# HKLM scope requires an elevated PowerShell; the script checks and fails cleanly.
param(
    [Parameter(Mandatory = $true)][string[]]$Name,
    [ValidateSet('HKCU', 'HKLM')][string]$Scope = 'HKCU',
    [string]$BackupDir = (Join-Path ([Environment]::GetFolderPath('MyDocuments')) `
        ('pc-steward-backups\' + (Get-Date -Format 'yyyy-MM-dd_HHmmss')))
)
$ErrorActionPreference = 'Stop'

# powershell.exe -File passes "-Name A,B,C" as one literal string, not an array —
# normalize so both calling styles work.
$Name = @($Name | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })

# Entries pc-steward refuses to touch: security software must keep running.
$protected = @('SecurityHealth', 'SecurityHealthSystray', 'WindowsDefender', 'WinDefend')

$runKey      = "${Scope}:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$approvedKey = "${Scope}:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"

if ($Scope -eq 'HKLM') {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        [PSCustomObject]@{
            ok    = $false
            error = 'HKLM scope requires an elevated (administrator) PowerShell. Re-run this script elevated, e.g. via Start-Process powershell -Verb RunAs.'
        } | ConvertTo-Json
        exit 1
    }
}

# Backup before touching anything — and refuse to proceed if the backup fails,
# because reversibility is the whole safety contract of this script.
New-Item -ItemType Directory -Force $BackupDir | Out-Null
$runBackup = Join-Path $BackupDir "$Scope-Run.reg"
& reg.exe export ($runKey -replace ':', '') $runBackup /y | Out-Null
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $runBackup)) {
    [PSCustomObject]@{ ok = $false; error = "backup of $runKey failed — aborting, nothing was changed" } | ConvertTo-Json
    exit 1
}
if (Test-Path $approvedKey) {
    $approvedBackup = Join-Path $BackupDir "$Scope-StartupApproved-Run.reg"
    & reg.exe export ($approvedKey -replace ':', '') $approvedBackup /y | Out-Null
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $approvedBackup)) {
        [PSCustomObject]@{ ok = $false; error = "backup of $approvedKey failed — aborting, nothing was changed" } | ConvertTo-Json
        exit 1
    }
} else {
    New-Item -Path $approvedKey -Force | Out-Null
}

$disabledBytes = [byte[]](3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
$runValues = Get-ItemProperty $runKey -ErrorAction SilentlyContinue

$results = @()
foreach ($n in $Name) {
    if ($protected -contains $n) {
        $results += @{ name = $n; ok = $false; reason = 'protected entry (security software) — pc-steward will not disable it' }
        continue
    }
    if ($null -eq $runValues -or $null -eq $runValues.PSObject.Properties[$n]) {
        $results += @{ name = $n; ok = $false; reason = "no entry named '$n' in $runKey" }
        continue
    }
    New-ItemProperty -Path $approvedKey -Name $n -Value $disabledBytes -PropertyType Binary -Force | Out-Null
    $verify = (Get-ItemProperty $approvedKey).$n
    $results += @{ name = $n; ok = (($verify[0] -band 1) -eq 1); state = 'Disabled' }
}

[PSCustomObject]@{
    ok        = @($results | Where-Object { -not $_.ok }).Count -eq 0
    scope     = $Scope
    backupDir = $BackupDir
    undoHint  = "restore-startup.ps1 -BackupDir '$BackupDir' (or double-click the .reg backups)"
    results   = $results
} | ConvertTo-Json -Depth 4

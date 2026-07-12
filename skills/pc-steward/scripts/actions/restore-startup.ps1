# pc-steward action: undo — restore startup entries from a pc-steward backup directory
# by re-importing the .reg files that disable-startup.ps1 exported.
# Backups containing HKLM keys need an elevated PowerShell to import.
param(
    [Parameter(Mandatory = $true)][string]$BackupDir
)
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $BackupDir)) {
    [PSCustomObject]@{ ok = $false; error = "backup directory not found: $BackupDir" } | ConvertTo-Json
    exit 1
}

$regs = @(Get-ChildItem $BackupDir -Filter *.reg)
if ($regs.Count -eq 0) {
    [PSCustomObject]@{ ok = $false; error = "no .reg files in $BackupDir" } | ConvertTo-Json
    exit 1
}

# reg.exe import writes its success message to stderr; in Windows PowerShell 5.1
# redirecting native stderr wraps it into an error record. Start-Process sidesteps
# the stream entirely and gives us a clean exit code.
$results = @()
foreach ($r in $regs) {
    $p = Start-Process -FilePath reg.exe -ArgumentList 'import', ('"' + $r.FullName + '"') `
        -Wait -PassThru -WindowStyle Hidden
    $results += @{ file = $r.Name; ok = ($p.ExitCode -eq 0) }
}

[PSCustomObject]@{
    ok       = @($results | Where-Object { -not $_.ok }).Count -eq 0
    imported = $results
} | ConvertTo-Json -Depth 3

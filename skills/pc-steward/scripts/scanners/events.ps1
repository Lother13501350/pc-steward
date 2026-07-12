# pc-steward scanner: events — recent System log errors and disk-related warnings. Read-only.
# Grouped counts only; individual events can be pulled later if a group looks suspicious.
$ErrorActionPreference = 'SilentlyContinue'

$sinceDays = 7
$since = (Get-Date).AddDays(-$sinceDays)

$errorsByProvider = @()
try {
    $errorsByProvider = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2; StartTime = $since } -MaxEvents 500 -ErrorAction Stop |
        Group-Object ProviderName | Sort-Object Count -Descending | ForEach-Object {
            @{ provider = $_.Name; count = $_.Count }
        })
} catch { }

# Storage-stack events (disk resets, NTFS warnings) are early signals of failing
# drives or storage driver issues — worth surfacing even at low counts.
$diskRelated = @()
try {
    $diskRelated = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; StartTime = $since } -MaxEvents 3000 -ErrorAction Stop |
        Where-Object { $_.ProviderName -match 'disk|ntfs|storahci|stornvme|volmgr' } |
        Group-Object Id, ProviderName | ForEach-Object {
            @{ idAndProvider = $_.Name; count = $_.Count }
        })
} catch { }

[PSCustomObject]@{
    scanner          = 'events'
    sinceDays        = $sinceDays
    errorsByProvider = $errorsByProvider
    diskRelated      = $diskRelated
} | ConvertTo-Json -Depth 4

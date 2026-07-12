# pc-steward scanner: processes — top RAM/CPU consumers and multi-process app groups. Read-only.
$ErrorActionPreference = 'SilentlyContinue'

$procs = Get-Process

$topRam = @($procs | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 | ForEach-Object {
    @{ name = $_.Name; processId = $_.Id; ramMB = [math]::Round($_.WorkingSet64 / 1MB, 0) }
})

# Instantaneous per-process CPU%. Values are per-core based and can exceed 100 on multi-core systems.
$topCpu = @(Get-CimInstance Win32_PerfFormattedData_PerfProc_Process |
    Where-Object { $_.Name -ne '_Total' -and $_.Name -ne 'Idle' } |
    Sort-Object PercentProcessorTime -Descending | Select-Object -First 10 | ForEach-Object {
        @{ name = $_.Name; cpuPercent = $_.PercentProcessorTime; ramMB = [math]::Round($_.WorkingSetPrivate / 1MB, 0) }
    })

# Apps that spawn many processes (browsers, Electron apps) — their true footprint is the group total.
$groups = @($procs | Group-Object Name | Where-Object Count -ge 3 | ForEach-Object {
    @{
        name       = $_.Name
        count      = $_.Count
        totalRamMB = [math]::Round(($_.Group | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 0)
    }
} | Sort-Object { $_.totalRamMB } -Descending | Select-Object -First 15)

[PSCustomObject]@{
    scanner     = 'processes'
    topByRam    = $topRam
    topByCpuNow = $topCpu
    groups      = $groups
} | ConvertTo-Json -Depth 5

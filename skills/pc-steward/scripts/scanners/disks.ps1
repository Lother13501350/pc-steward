# pc-steward scanner: disks — physical disk health, volume free space, page file pressure. Read-only.
$ErrorActionPreference = 'SilentlyContinue'

$physical = @(Get-PhysicalDisk | ForEach-Object {
    @{
        model     = $_.FriendlyName
        mediaType = [string]$_.MediaType
        bus       = [string]$_.BusType
        health    = [string]$_.HealthStatus
        sizeGB    = [math]::Round($_.Size / 1GB, 0)
    }
})

$volumes = @(Get-Volume | Where-Object DriveLetter | ForEach-Object {
    @{
        letter      = [string]$_.DriveLetter
        label       = $_.FileSystemLabel
        fileSystem  = $_.FileSystem
        sizeGB      = [math]::Round($_.Size / 1GB, 1)
        freeGB      = [math]::Round($_.SizeRemaining / 1GB, 1)
        freePercent = if ($_.Size -gt 0) { [math]::Round($_.SizeRemaining / $_.Size * 100, 1) } else { $null }
    }
})

# High page file usage relative to RAM is the clearest signal of memory pressure.
$pageFiles = @(Get-CimInstance Win32_PageFileUsage | ForEach-Object {
    @{ path = $_.Name; allocatedMB = $_.AllocatedBaseSize; currentUsageMB = $_.CurrentUsage; peakUsageMB = $_.PeakUsage }
})

[PSCustomObject]@{
    scanner       = 'disks'
    physicalDisks = $physical
    volumes       = $volumes
    pageFiles     = $pageFiles
} | ConvertTo-Json -Depth 4

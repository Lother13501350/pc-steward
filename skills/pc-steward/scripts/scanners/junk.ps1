# pc-steward scanner: junk — size of safely-cleanable locations. Read-only; measures, never deletes.
# Note: recursive size measurement can take a minute or two on large temp folders.
$ErrorActionPreference = 'SilentlyContinue'

function Get-DirSizeGB([string]$path) {
    if (-not $path -or -not (Test-Path $path)) { return $null }
    $sum = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue |
        Measure-Object Length -Sum).Sum
    if ($null -eq $sum) { $sum = 0 }
    return [math]::Round($sum / 1GB, 2)
}

$targets = [ordered]@{
    userTemp           = $env:TEMP
    windowsTemp        = Join-Path $env:SystemRoot 'Temp'
    windowsUpdateCache = Join-Path $env:SystemRoot 'SoftwareDistribution\Download'
    inetCache          = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\INetCache'
}
$cleanable = @{}
foreach ($k in $targets.Keys) {
    $cleanable[$k] = @{ path = $targets[$k]; sizeGB = Get-DirSizeGB $targets[$k] }
}

$recycleBinGB = $null
try {
    $rb = (New-Object -ComObject Shell.Application).NameSpace(0xA)
    $sum = 0
    foreach ($item in $rb.Items()) { $sum += $item.Size }
    $recycleBinGB = [math]::Round($sum / 1GB, 2)
} catch { }

[PSCustomObject]@{
    scanner      = 'junk'
    cleanable    = $cleanable
    recycleBinGB = $recycleBinGB
    # Informational only — Downloads is the user's data, never a cleanup target.
    downloadsFolderGB = Get-DirSizeGB (Join-Path $env:USERPROFILE 'Downloads')
} | ConvertTo-Json -Depth 4

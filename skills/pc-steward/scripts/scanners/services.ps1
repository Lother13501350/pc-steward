# pc-steward scanner: services — running third-party (non-Microsoft) services. Read-only.
# Third-party services are the usual suspects for background resource drain;
# Windows' own services are listed only as a count.
$ErrorActionPreference = 'SilentlyContinue'

$all = Get-CimInstance Win32_Service

$thirdParty = @($all | Where-Object {
    $_.State -eq 'Running' -and $_.PathName -and $_.PathName -notmatch '\\Windows\\|Microsoft'
} | ForEach-Object {
    @{
        name        = $_.Name
        displayName = $_.DisplayName
        startMode   = $_.StartMode
        processId   = $_.ProcessId
        path        = $_.PathName
    }
})

[PSCustomObject]@{
    scanner           = 'services'
    runningTotal      = @($all | Where-Object { $_.State -eq 'Running' }).Count
    thirdPartyRunning = $thirdParty
} | ConvertTo-Json -Depth 4

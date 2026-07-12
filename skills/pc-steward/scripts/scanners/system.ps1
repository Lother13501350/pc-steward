# pc-steward scanner: system — CPU, RAM, uptime, GPU, power plan. Read-only.
$ErrorActionPreference = 'SilentlyContinue'

$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$cs  = Get-CimInstance Win32_ComputerSystem
$os  = Get-CimInstance Win32_OperatingSystem
$mem = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
$gpus = @(Get-CimInstance Win32_VideoController | ForEach-Object {
    @{ name = $_.Name; driverVersion = $_.DriverVersion }
})
$plan = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan -ErrorAction SilentlyContinue |
    Where-Object IsActive | Select-Object -First 1

$uptime = (Get-Date) - $os.LastBootUpTime

[PSCustomObject]@{
    scanner  = 'system'
    computer = @{
        manufacturer = $cs.Manufacturer
        model        = $cs.Model
        os           = $os.Caption
        build        = $os.BuildNumber
    }
    cpu = @{
        name               = ([string]$cpu.Name).Trim()
        cores              = $cpu.NumberOfCores
        logicalProcessors  = $cpu.NumberOfLogicalProcessors
        currentLoadPercent = $cpu.LoadPercentage
    }
    memory = @{
        totalGB       = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        freeGB        = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        availableMB   = $mem.AvailableMBytes
        commitPercent = $mem.PercentCommittedBytesInUse
    }
    uptime = @{
        lastBoot = $os.LastBootUpTime.ToString('s')
        days     = [math]::Round($uptime.TotalDays, 1)
    }
    gpus      = $gpus
    powerPlan = if ($plan) { $plan.ElementName } else { $null }
} | ConvertTo-Json -Depth 5

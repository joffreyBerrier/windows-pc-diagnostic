param(
    [switch]$QuickScan,
    [string]$OutputPath = [Environment]::GetFolderPath("Desktop"),
    [switch]$NoHTML
)

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script needs administrator rights to check your computer's health. Please run it as Administrator!" -ForegroundColor Red
    exit
}

Write-Host "=== Starting Complete PC Health Check ===" -ForegroundColor Green

$script:globalScore = 100
$script:checkResults = @()

$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PC Health Check Results</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; }
        h1 { color: #2d89ef; }
        .result { padding: 10px; border-bottom: 1px solid #ddd; }
        .ok { color: green; }
        .not-ok { color: red; }
        .details { color: #555; }
        .chart-container { width: 600px; margin: 20px auto; }
        .summary { background: #f5f5f5; padding: 15px; margin: 20px 0; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>PC Health Check Results</h1>
    <div class="summary" id="globalScore"></div>
    <div class="chart-container">
        <canvas id="resultsChart"></canvas>
    </div>
"@

function SafeExecute {
    param(
        [string]$componentName,
        [scriptblock]$action
    )
    try {
        & $action
    } catch {
        Add-Result $componentName "Not OK" "Error during check: $($_.Exception.Message)"
        Write-Host "Error in $componentName check: $($_.Exception.Message)" -ForegroundColor Red
        UpdateScore $componentName "Not OK" 10
    }
}

function UpdateScore {
    param (
        [string]$component,
        [string]$status,
        [int]$impact
    )
    if ($status -eq "Not OK") {
        $script:globalScore -= $impact
    }
}

function Add-Result {
    param (
        [string]$testName,
        [string]$status,
        [string]$details = ""
    )
    $colorClass = if ($status -eq "OK") { "ok" } else { "not-ok" }
    $htmlContent += "<div class='result'><strong class='$colorClass'>$testName : $status</strong><div class='details'>$details</div></div>`n"
    
    $displayColor = if ($status -eq "OK") { "Green" } else { "Red" }
    Write-Host "$testName : $status" -ForegroundColor $displayColor
    if ($details) { Write-Host "  -> $details" -ForegroundColor Yellow }

    $script:checkResults += @{
        name = $testName
        status = $status
        details = $details
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

function CheckDiskHealth {
    Write-Host "`n=== Checking Disk Health ===" -ForegroundColor Cyan
    $disks = Get-PhysicalDisk
    foreach ($disk in $disks) {
        $status = if ($disk.HealthStatus -eq "Healthy") { "OK" } else { "Not OK" }
        if ($status -eq "OK") {
            Add-Result "Disk $($disk.FriendlyName)" $status "This disk is healthy and working properly."
        } else {
            Add-Result "Disk $($disk.FriendlyName)" $status "Warning: This disk may be failing. Please backup your important files and consider replacing the disk."
        }
    }
}

function CheckSMART {
    Write-Host "`n=== Checking Disk Reliability Status ===" -ForegroundColor Cyan
    try {
        $smartDisks = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus |
            Where-Object { $_.PredictFailure -eq $true }
        
        if ($null -eq $smartDisks -or $smartDisks.Count -eq 0) {
            Add-Result "Disk Reliability" "OK" "All your disks are reporting good SMART status."
        } else {
            Add-Result "Disk Reliability" "Not OK" "One or more disks are showing SMART warning signs. Please backup your data and have the disks checked by a professional."
        }
    } catch {
        Add-Result "Disk Reliability" "Not OK" "Unable to check SMART status: $($_.Exception.Message)"
    }
}

function CheckBatteryHealth {
    Write-Host "`n=== Checking Battery Health ===" -ForegroundColor Cyan
    $batteryReport = "$env:USERPROFILE\battery-report.html"
    powercfg /batteryreport > $batteryReport
    if (Test-Path $batteryReport) {
        Add-Result "Battery Status" "OK" "A detailed battery report has been generated. You can find it at: $batteryReport"
    } else {
        Add-Result "Battery Status" "Not OK" "Unable to generate battery report. If you're using a laptop, this might indicate a battery problem."
    }
}

function CheckRAM {
    Write-Host "`n=== Checking Memory (RAM) ===" -ForegroundColor Cyan
    $ram = Get-WmiObject Win32_PhysicalMemory
    $totalRam = ($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB
    if ($totalRam -lt 4) {
        Add-Result "RAM" "Not OK" "Your computer has $([math]::Round($totalRam, 2)) GB of RAM. We recommend at least 4GB for smooth operation. Consider upgrading your RAM."
    } else {
        Add-Result "RAM" "OK" "Your computer has $([math]::Round($totalRam, 2)) GB of RAM, which is sufficient for normal use."
    }
}

function CheckCPU {
    Write-Host "`n=== Checking CPU Performance ===" -ForegroundColor Cyan
    $cpu = Get-CimInstance Win32_Processor
    
    try {
        $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        
        $currentSpeed = $cpu.CurrentClockSpeed
        $maxSpeed = $cpu.MaxClockSpeed
        $speedPercentage = [math]::Round(($currentSpeed / $maxSpeed) * 100, 1)

        if ($cpuLoad -lt 80) {
            Add-Result "CPU Usage" "OK" "CPU usage: $([math]::Round($cpuLoad, 1))%`nCurrent speed: $currentSpeed MHz ($speedPercentage% of max $maxSpeed MHz)"
        } else {
            Add-Result "CPU Usage" "Not OK" "High CPU usage detected: $([math]::Round($cpuLoad, 1))%`nThis might slow down your computer. Check Task Manager to see which applications are using the most CPU."
        }
    } catch {
        Add-Result "CPU Usage" "OK" "Unable to get detailed CPU metrics. Basic CPU info:`nProcessor: $($cpu.Name)`nMax Speed: $maxSpeed MHz"
    }
}

function CheckTemperature {
    Write-Host "`n=== Checking System Temperature ===" -ForegroundColor Cyan
    $temp = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" | Select-Object CurrentTemperature
    if ($temp) {
        $tempC = ($temp.CurrentTemperature - 2732) / 10
        if ($tempC -lt 85) {
            Add-Result "Temperature" "OK" "Your computer's temperature ($([math]::Round($tempC, 1))°C) is within safe limits."
        } else {
            Add-Result "Temperature" "Not OK" "Your computer is running too hot ($([math]::Round($tempC, 1))°C). Please check if the cooling fans are working and clean any dust from vents."
        }
    } else {
        Add-Result "Temperature" "Not OK" "Unable to read temperatures. Consider having your cooling system checked by a professional."
    }
}

function CheckGPU {
    Write-Host "`n=== Checking Graphics Card Performance ===" -ForegroundColor Cyan
    try {
        $gpu = Get-WmiObject Win32_VideoController

        foreach ($adapter in $gpu) {
            $dedicatedMemory = [math]::Round($adapter.AdapterRAM / 1GB, 2)
            
            try {
                $gpuCounter = Get-Counter "\GPU Engine(*)\Utilization Percentage" -ErrorAction Stop
                $gpuLoad = ($gpuCounter.CounterSamples | Where-Object { $_.InstanceName -match "engtype_3D" } | Measure-Object -Property CookedValue -Average).Average
                
                if ($gpuLoad) {
                    $status = if ($gpuLoad -lt 80) { "OK" } else { "Not OK" }
                    $message = if ($gpuLoad -lt 80) {
                        @"
GPU is working properly:
- Current Load: $([math]::Round($gpuLoad, 1))%
- Dedicated Memory: $dedicatedMemory GB
- Driver Version: $($adapter.DriverVersion)
- Current Resolution: $($adapter.CurrentHorizontalResolution)x$($adapter.CurrentVerticalResolution)
"@
                    } else {
                        @"
High GPU usage detected:
- Current Load: $([math]::Round($gpuLoad, 1))%
- Dedicated Memory: $dedicatedMemory GB
Consider closing demanding applications or games if you're not using them.
"@
                    }
                    Add-Result "Graphics Card $($adapter.Name)" $status $message
                }
            } catch {
                Add-Result "Graphics Card $($adapter.Name)" "OK" @"
GPU information:
- Dedicated Memory: $dedicatedMemory GB
- Driver Version: $($adapter.DriverVersion)
- Current Resolution: $($adapter.CurrentHorizontalResolution)x$($adapter.CurrentVerticalResolution)
"@
            }
        }
    } catch {
        Add-Result "Graphics Card" "Not OK" "Unable to get GPU information. This might indicate a driver problem."
    }
}

function CheckDiskSpace {
    Write-Host "`n=== Checking Available Disk Space ===" -ForegroundColor Cyan
    $drives = Get-PSDrive -PSProvider FileSystem
    foreach ($drive in $drives) {
        $used = [math]::Round($drive.Used / 1GB, 2)
        $free = [math]::Round($drive.Free / 1GB, 2)
        $total = $used + $free
        $percentFree = [math]::Round(($free / $total) * 100, 1)
        
        if ($percentFree -lt 10) {
            Add-Result "Drive $($drive.Name)" "Not OK" "Your drive is almost full ($percentFree% free space). Free up space by removing unnecessary files or use Disk Cleanup."
        } else {
            Add-Result "Drive $($drive.Name)" "OK" "You have $free GB free out of $total GB ($percentFree% free space), which is sufficient."
        }
    }
}

function CheckNetwork {
    Write-Host "`n=== Checking Internet Connection ===" -ForegroundColor Cyan
    try {
        $sites = @("google.com", "1.1.1.1", "8.8.8.8")
        $connected = $false
        
        foreach ($site in $sites) {
            if (Test-Connection -ComputerName $site -Count 1 -Quiet -ErrorAction Stop -TimeoutSeconds 2) {
                $connected = $true
                break
            }
        }
        
        if ($connected) {
            Add-Result "Internet Connection" "OK" "Votre connexion internet fonctionne correctement."
        } else {
            Add-Result "Internet Connection" "Not OK" "Connexion instable détectée. Vérifiez la qualité de votre signal WiFi."
        }
    } catch {
        Add-Result "Internet Connection" "Not OK" "Impossible de tester la connexion internet. Vérifiez votre connexion WiFi ou câble réseau."
    }
}

function FinalizeHTML {
    $scoreColor = if ($script:globalScore -gt 70) { "green" } else { "red" }
    $htmlContent += @"
    <script>
        document.getElementById('globalScore').innerHTML = '<h2>Overall System Health Score: <span style="color: $scoreColor">$script:globalScore/100</span></h2>';
        
        // Create chart
        const ctx = document.getElementById('resultsChart').getContext('2d');
        new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Health Score', 'Issues'],
                datasets: [{
                    data: [$script:globalScore, $(100-$script:globalScore)],
                    backgroundColor: ['#4CAF50', '#f44336']
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'System Health Overview'
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    $htmlPath = Join-Path $OutputPath "PC_Health_Check_Results_${timestamp}.html"
    $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
    Write-Host "`nHTML report saved to: $htmlPath" -ForegroundColor Green
}

function GenerateRecommendations {
    Write-Host "`n=== Generating Recommendations ===" -ForegroundColor Cyan
    $recommendations = @()
    
    $criticalIssues = $script:checkResults | Where-Object { $_.status -eq "Not OK" }
    foreach ($issue in $criticalIssues) {
        $recommendation = switch -Wildcard ($issue.name) {
            "*RAM*" { "Consider upgrading your RAM to improve system performance" }
            "*Disk Space*" { "Run Disk Cleanup or uninstall unnecessary programs" }
            "*Temperature*" { "Clean your computer's vents and ensure proper ventilation" }
            "*Antivirus*" { "Install or update your antivirus software" }
            "*CPU*" { "Check running applications in Task Manager for high CPU usage" }
            "*Network*" { "Check your internet connection and router settings" }
            "*GPU*" { "Update your graphics drivers" }
            "*Battery*" { "Consider replacing your battery" }
            default { "Check and address the issue with $($issue.name)" }
        }
        $recommendations += $recommendation
    }
    
    if ($recommendations.Count -gt 0) {
        Add-Result "Recommendations" "INFO" ($recommendations -join "`n")
    }
}

$checks = @(
    ${function:CheckDiskHealth},
    ${function:CheckSMART},
    ${function:CheckBatteryHealth},
    ${function:CheckRAM},
    ${function:CheckCPU},
    ${function:CheckTemperature},
    ${function:CheckGPU},
    ${function:CheckDiskSpace},
    ${function:CheckNetwork}
)

if ($QuickScan) {
    $checks = $checks | Select-Object -First 5
}

foreach ($check in $checks) {
    SafeExecute $check.Name $check
}

if (-not $NoHTML) {
    FinalizeHTML
}

$scoreColor = if ($script:globalScore -gt 70) { "Green" } else { "Red" }
Write-Host "`n=== Health Check Completed ===" -ForegroundColor Green
Write-Host "Overall System Health Score: $script:globalScore/100" -ForegroundColor $scoreColor

GenerateRecommendations

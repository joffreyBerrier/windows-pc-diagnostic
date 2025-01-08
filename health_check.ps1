# Check if the script is running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator!" -ForegroundColor Red
    exit
}

Write-Host "=== Starting PC Diagnostics ===" -ForegroundColor Green

# Function to display results clearly
function Show-Result($testName, $status, $details = "") {
    $color = if ($status -eq "OK") { "Green" } else { "Red" }
    Write-Host "$testName : $status" -ForegroundColor $color
    if ($details) { Write-Host "  -> $details" -ForegroundColor Yellow }
}

# Disk health check
Write-Host "`n=== Checking Disks ===" -ForegroundColor Cyan
$disks = Get-PhysicalDisk
foreach ($disk in $disks) {
    $status = if ($disk.HealthStatus -eq "Healthy") { "OK" } else { "Not OK" }
    Show-Result "Disk $($disk.DeviceId)" $status "Status: $($disk.HealthStatus)"
}

# SMART status check
Write-Host "`n=== Checking Disk SMART Status ===" -ForegroundColor Cyan
$smartDisks = Get-CimInstance MSFT_Disk | Where-Object { $_.OperationalStatus -ne "OK" }
if ($smartDisks.Count -eq 0) {
    Show-Result "SMART Status" "OK"
} else {
    Show-Result "SMART Status" "Not OK" "Issues detected on some disks."
}

# Battery health check
Write-Host "`n=== Checking Battery ===" -ForegroundColor Cyan
$batteryReport = "$env:USERPROFILE\battery-report.html"
powercfg /batteryreport > $batteryReport
if (Test-Path $batteryReport) {
    Show-Result "Battery Status" "OK" "Report generated: $batteryReport"
} else {
    Show-Result "Battery Status" "Not OK" "Unable to generate the report."
}

# RAM check
Write-Host "`n=== Checking Memory (RAM) ===" -ForegroundColor Cyan
$ram = Get-WmiObject Win32_PhysicalMemory
$totalRam = ($ram | Measure-Object -Property Capacity -Sum).Sum / 1GB
if ($totalRam -lt 4) {
    Show-Result "RAM" "Not OK" "Insufficient RAM: $([math]::Round($totalRam, 2)) GB detected."
} else {
    Show-Result "RAM" "OK" "$([math]::Round($totalRam, 2)) GB detected."
}

# CPU check
Write-Host "`n=== Checking CPU ===" -ForegroundColor Cyan
$cpu = Get-CimInstance Win32_Processor
if ($cpu.LoadPercentage -lt 80) {
    Show-Result "CPU" "OK" "Current load: $($cpu.LoadPercentage)%"
} else {
    Show-Result "CPU" "Not OK" "High usage detected: $($cpu.LoadPercentage)%"
}

# Temperature check (if available)
Write-Host "`n=== Checking Temperatures ===" -ForegroundColor Cyan
$temp = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" | Select-Object CurrentTemperature
if ($temp) {
    $tempC = ($temp.CurrentTemperature - 2732) / 10
    if ($tempC -lt 85) {
        Show-Result "Temperature" "OK" "$([math]::Round($tempC, 1)) °C detected."
    } else {
        Show-Result "Temperature" "Not OK" "Overheating detected: $([math]::Round($tempC, 1)) °C."
    }
} else {
    Show-Result "Temperature" "Not OK" "Unable to read temperatures."
}

# System file check
Write-Host "`n=== Checking System Files ===" -ForegroundColor Cyan
$sfcOutput = sfc /scannow
if ($sfcOutput -match "No integrity violations") {
    Show-Result "System File Check" "OK"
} else {
    Show-Result "System File Check" "Not OK" "Issues detected with system files."
}

Write-Host "`n=== Diagnostics Completed ===" -ForegroundColor Green
# PC Health Check Script

A powerful PowerShell script for Windows PC diagnostics. Generates a detailed HTML report with system health score, performance metrics, and personalized recommendations.

[Version française ci-dessous](#french)

## Example Report

```
=== Starting Complete PC Health Check ===

CPU : OK
  -> Average CPU usage: 23% (Current speed: 2800 MHz - 70% of max 4000 MHz)
  -> Intel Core i7-12700K, 12 cores

Memory (RAM) : OK
  -> Your computer has 32 GB of RAM, which is sufficient for normal use
  -> Current usage: 45% (14.4 GB used)

Graphics Card NVIDIA GeForce RTX 3060 : OK
  -> GPU is working properly:
     - Current Load: 15%
     - Dedicated Memory: 6 GB
     - Driver Version: 31.0.15.3598
     - Current Resolution: 1920x1080

Drive C: : OK
  -> 234 GB free out of 500 GB (46.8% free space)
  -> Health Status: Healthy
  -> SMART Status: OK

Drive D: : OK
  -> 789 GB free out of 1000 GB (78.9% free space)
  -> Health Status: Healthy
  -> SMART Status: OK

Disk Performance : OK
  -> Write Speed: 156.22 MB/s
  -> Read Speed: 312.45 MB/s
  -> Performance is within expected range

Temperature : OK
  -> CPU: 45°C (Normal range)
  -> GPU: 52°C (Normal range)
  -> System: 38°C (Normal range)

Battery : OK
  -> Capacity: 92% of original
  -> Estimated runtime: 4 hours 15 minutes
  -> Charging status: Plugged in
  -> Wear level: Normal

Network : OK
  -> Internet Connection: Connected
  -> Speed: 100 Mbps
  -> Latency: 12ms to google.com

Windows Updates : OK
  -> System is up to date
  -> Last update: 2024-01-20
  -> No pending updates

Antivirus (Windows Defender) : OK
  -> Status: Enabled and up to date
  -> Real-time protection: Active
  -> Last scan: Today at 08:00

Firewall : OK
  -> Status: Enabled
  -> All profiles (Domain, Private, Public) active
  -> No suspicious rules detected

Health Evolution : OK
  -> Score improved by 5 points since last check (2024-01-20 15:30:22)
  -> Consistent performance over last 30 days

Recommendations:
  -> Optional: Consider updating GPU drivers (current version is 2 months old)
  -> Regular: Run disk cleanup to maintain free space
  -> Info: All critical systems are performing well

Overall System Health Score: 95/100
```

## 🔧 Features

- **Interactive Menu**: Choose between different types of checks
- **System Health Score**: Overall rating from 0 to 100
- **Visual Reports**: Charts and graphs in HTML output
- **Performance Testing**:
  - Disk read/write speeds
  - CPU load analysis
  - Memory usage patterns
- **Historical Tracking**:
  - Compare with previous checks
  - Track system health evolution
- **Smart Recommendations**:
  - Personalized improvement suggestions
  - Action items for issues
- **Hardware Checks**:
  - Hard Drive (SMART status)
  - Battery health
  - Memory (RAM)
  - Processor (CPU)
  - Graphics Card (GPU)
  - Temperature sensors
- **System Checks**:
  - Network connectivity
  - Windows updates
  - Disk space
- **Security**:
  - Antivirus status
  - Firewall configuration

## 🔧 Prerequisites

- Windows 10 or 11
- PowerShell (pre-installed on Windows 10/11)
- Administrator rights

## 📋 Usage

1. **Open PowerShell as administrator**
   - `Win + X` then "Windows PowerShell (Admin)"

2. **Allow execution (if needed)**
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

3. **Run the script**
   Basic usage (interactive menu):
   ```powershell
   .\health_check.ps1
   ```

   Available options:
   ```powershell
   # Quick scan (only essential checks)
   .\health_check.ps1 -QuickScan

   # Export results to JSON (for history tracking)
   .\health_check.ps1 -ExportJSON

   # Custom output location
   .\health_check.ps1 -OutputPath "C:\Reports"

   # No HTML report (console only)
   .\health_check.ps1 -NoHTML
   ```

4. **Menu Options**
   - Run Full Check: Complete system analysis
   - Run Quick Check: Essential checks only
   - Performance Test: Disk and system performance
   - Security Check: Antivirus and firewall
   - View Previous Reports: Compare with history

5. **View results**
   - In PowerShell console (real-time)
   - In the HTML report (includes charts)
   - In JSON format (if -ExportJSON was used)
   - Historical comparison (if previous reports exist)

## ⚠️ Limitations

- Temperature sensors may not work on all systems
- Battery tests only work on devices with a battery
- Some drives may not provide detailed SMART data
- GPU usage monitoring may not be available on all systems
- Performance tests might vary based on system load

## 📝 License

MIT License
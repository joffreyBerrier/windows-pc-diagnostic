# Windows PC Diagnostic Script

A simple PowerShell script to perform basic diagnostics on a Windows PC. The script checks the health of critical components, including the disk, battery, memory (RAM), processor (CPU), and system files, and provides clear, user-friendly results indicating whether each component is functioning properly.

## Features

- **Disk Health**: Checks the physical and SMART status of all connected disks.
- **Battery Health**: Generates a detailed battery report (if applicable).
- **RAM Check**: Verifies the amount of installed memory and its sufficiency.
- **CPU Usage**: Monitors current CPU load.
- **Temperature**: Reads hardware temperature sensors (if available).
- **System File Check**: Validates the integrity of Windows system files.
- **Clear Results**: Displays results as `OK` or `Not OK` with explanations for any detected issues.

## Prerequisites

- Windows 10 or Windows 11.
- PowerShell 5.1 or later (pre-installed on Windows 10 and above).
- Administrator privileges to execute the script.

## How to Use

1. **Download the Script**  
Clone this repository or download the `.ps1` script file:
```bash
git clone https://github.com/your-username/windows-pc-diagnostic.git
```

2.	Run PowerShell as Administrator
Open PowerShell with administrator privileges:
* Press Win + S, type PowerShell, right-click, and select Run as Administrator.

3.	Allow Script Execution (if necessary)
If PowerShell script execution is restricted, allow it temporarily:
```bash
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

4.	Run the Script
Navigate to the folder containing the script and execute it:
```bash
.\health_check.ps1
```

5.	View Results
The script will display clear results for each diagnostic check directly in the PowerShell terminal.
```bash
=== Starting PC Diagnostics ===

=== Checking Disks ===
Disk 0 : OK
  -> Status: Healthy

=== Checking Disk SMART Status ===
SMART Status : OK

=== Checking Battery ===
Battery Status : OK
  -> Report generated: C:\Users\YourName\battery-report.html

=== Checking Memory (RAM) ===
RAM : OK
  -> 16 GB detected.

=== Checking CPU ===
CPU : OK
  -> Current load: 12%

=== Checking Temperatures ===
Temperature : OK
  -> 45.3 °C detected.

=== Checking System Files ===
System File Check : OK

=== Diagnostics Completed ===
```

Limitations
* Temperature Sensors: May not work on all systems, depending on hardware and driver support.
* Battery Checks: Only available on laptops or devices with batteries.
* Disk SMART: Some disks may not provide detailed SMART data.

Contributing

Feel free to contribute to this project by opening issues or submitting pull requests. Contributions for additional checks or performance improvements are welcome!

License
This project is licensed under the MIT License. See the LICENSE file for details.
---

### Instructions for Use

1. Save this Markdown content into a file named `README.md`.
2. Place it in the root directory of your GitHub repository.
3. Commit and push the changes to include the README file on GitHub.

Let me know if you need further adjustments!
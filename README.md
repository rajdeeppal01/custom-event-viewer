Amen – PowerShell Event Log Viewer
This is a lightweight, custom-built Windows Event Log viewer developed using PowerShell and .NET WinForms. It is designed for quick and effective log triage in SOC, forensic, or Red Team environments.

Features
- GUI interface for Windows Event Logs
- Filter by:
  - Log level (Information, Warning, Error, Critical)
  - Event ID
  - Date range
  - Message keywords
- Multi-log source support (Application, System, Security, etc.)
- CSV export of filtered logs
- Paging support for large datasets
- No installation needed – portable `.ps1` script

How to Run
1. Open PowerShell **as Administrator**
2. Run:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope Process
   ./amen.ps1

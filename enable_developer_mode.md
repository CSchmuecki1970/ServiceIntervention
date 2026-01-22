# Enable Developer Mode for Flutter

## Problem
Flutter requires symbolic link support to build apps with plugins. On Windows, this requires Developer Mode to be enabled.

## Solution

### Method 1: Using Settings UI (Recommended)
1. The Windows Settings window should have opened automatically
2. If not, run: `start ms-settings:developers`
3. In the Settings window, find **"Developer Mode"**
4. Toggle the switch to **ON**
5. You may see a warning dialog - click **Yes** to confirm
6. Wait for Windows to enable Developer Mode (may take a minute)

### Method 2: Using PowerShell (Administrator Required)
Run PowerShell as Administrator and execute:

```powershell
# Enable Developer Mode
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowAllTrustedApps -Value 1
```

### Verify Developer Mode is Enabled
Run this command to check:

```powershell
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" | Select-Object AllowDevelopmentWithoutDevLicense, AllowAllTrustedApps
```

Both values should be `1` if Developer Mode is enabled.

### After Enabling
1. Close and reopen your terminal/IDE
2. Try building your Flutter app again:
   ```powershell
   flutter build windows
   # or
   flutter run
   ```

## Notes
- Developer Mode allows apps to run in developer mode without a developer license
- It also enables symbolic link creation without administrator privileges
- This is safe to enable and commonly used by developers
- You may need to restart your terminal after enabling

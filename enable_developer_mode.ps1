# Enable Developer Mode for Flutter
# This script enables Developer Mode which is required for Flutter plugin symlinks

Write-Host "Flutter Developer Mode Enabler" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To enable Developer Mode:" -ForegroundColor Yellow
    Write-Host "1. Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor White
    Write-Host "2. Navigate to this directory" -ForegroundColor White
    Write-Host "3. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "OR use the Settings UI method:" -ForegroundColor Yellow
    Write-Host "   Run: start ms-settings:developers" -ForegroundColor White
    Write-Host "   Then toggle Developer Mode ON" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "Checking current Developer Mode status..." -ForegroundColor Yellow

try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
    $current = Get-ItemProperty -Path $regPath -ErrorAction Stop
    
    Write-Host "Current Status:" -ForegroundColor Cyan
    Write-Host "  AllowDevelopmentWithoutDevLicense: $($current.AllowDevelopmentWithoutDevLicense)" -ForegroundColor $(if ($current.AllowDevelopmentWithoutDevLicense -eq 1) { "Green" } else { "Yellow" })
    Write-Host "  AllowAllTrustedApps: $($current.AllowAllTrustedApps)" -ForegroundColor $(if ($current.AllowAllTrustedApps -eq 1) { "Green" } else { "Yellow" })
    Write-Host ""
    
    if ($current.AllowDevelopmentWithoutDevLicense -eq 1 -and $current.AllowAllTrustedApps -eq 1) {
        Write-Host "Developer Mode is already enabled!" -ForegroundColor Green
        Write-Host "You should be able to build Flutter apps with plugins now." -ForegroundColor Green
        exit 0
    }
} catch {
    Write-Host "Registry key not found - Developer Mode is disabled" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Enabling Developer Mode..." -ForegroundColor Yellow

try {
    # Create the registry key if it doesn't exist
    if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Force | Out-Null
    }
    
    # Enable Developer Mode
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowDevelopmentWithoutDevLicense -Value 1 -ErrorAction Stop
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name AllowAllTrustedApps -Value 1 -ErrorAction Stop
    
    Write-Host ""
    Write-Host "SUCCESS: Developer Mode has been enabled!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Close and reopen your terminal/IDE" -ForegroundColor White
    Write-Host "2. Try building your Flutter app again:" -ForegroundColor White
    Write-Host "   flutter build windows" -ForegroundColor Gray
    Write-Host "   or" -ForegroundColor Gray
    Write-Host "   flutter run" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to enable Developer Mode" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Use Settings UI" -ForegroundColor Yellow
    Write-Host "Run: start ms-settings:developers" -ForegroundColor White
    Write-Host "Then toggle Developer Mode ON manually" -ForegroundColor White
    exit 1
}

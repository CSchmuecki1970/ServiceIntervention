# Fix Flutter Doctor Path Encoding Issue
# This script helps resolve the Flutter doctor crash caused by special characters in username

Write-Host "Flutter Doctor Path Encoding Fix" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check current Flutter installation
$currentFlutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if ($currentFlutter) {
    $flutterDir = Split-Path (Split-Path $currentFlutter)
    Write-Host "Current Flutter location: $flutterDir" -ForegroundColor Yellow
    Write-Host ""
    
    # Check if path contains special characters
    if ($flutterDir -match '[^\x00-\x7F]') {
        Write-Host "WARNING: Flutter is installed in a path with special characters." -ForegroundColor Red
        Write-Host "This can cause 'flutter doctor' to crash with encoding errors." -ForegroundColor Red
        Write-Host ""
        
        Write-Host "SOLUTIONS:" -ForegroundColor Green
        Write-Host ""
        Write-Host "Option 1: Move Flutter to a path without special characters (RECOMMENDED)" -ForegroundColor Cyan
        Write-Host "  1. Move the Flutter folder from:" -ForegroundColor White
        Write-Host "     $flutterDir" -ForegroundColor Gray
        Write-Host "  2. To one of these locations:" -ForegroundColor White
        Write-Host "     - C:\flutter" -ForegroundColor Gray
        Write-Host "     - C:\tools\flutter" -ForegroundColor Gray
        Write-Host "     - C:\dev\flutter" -ForegroundColor Gray
        Write-Host "  3. Update your PATH environment variable:" -ForegroundColor White
        Write-Host "     [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') -replace [regex]::Escape('$flutterDir\bin'), 'C:\flutter\bin', 'User')" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "Option 2: Use Flutter without 'flutter doctor'" -ForegroundColor Cyan
        Write-Host "  Flutter commands work fine, only 'flutter doctor' crashes." -ForegroundColor White
        Write-Host "  You can still use:" -ForegroundColor White
        Write-Host "    - flutter --version" -ForegroundColor Gray
        Write-Host "    - flutter run" -ForegroundColor Gray
        Write-Host "    - flutter build" -ForegroundColor Gray
        Write-Host "    - flutter pub get" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "Option 3: Report the issue to Flutter team" -ForegroundColor Cyan
        Write-Host "  This is a known issue: https://github.com/flutter/flutter/issues" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "Flutter path looks good - no special characters detected." -ForegroundColor Green
    }
} else {
    Write-Host "Flutter not found in PATH. Please install Flutter first." -ForegroundColor Red
}

Write-Host ""
Write-Host "Current Flutter Doctor Status:" -ForegroundColor Cyan
flutter doctor 2>&1 | Select-Object -First 20

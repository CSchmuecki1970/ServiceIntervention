# Navigate to project root
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Get dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Cyan
flutter pub get

# Generate Hive adapters
Write-Host "Generating Hive adapters..." -ForegroundColor Cyan
flutter pub run build_runner build --delete-conflicting-outputs

Write-Host "Done! You can now run your Flutter app." -ForegroundColor Green

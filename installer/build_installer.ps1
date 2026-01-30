# Build Windows installer using Inno Setup
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
Set-Location $repoRoot

Write-Host "Building Windows release..." -ForegroundColor Cyan
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter build failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

$isccPath = $env:INNO_SETUP_PATH
if ($isccPath) {
    if (Test-Path $isccPath -PathType Container) {
        $isccPath = Join-Path $isccPath "ISCC.exe"
    }
} else {
    $isccPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
}

if (-not (Test-Path $isccPath)) {
    Write-Host "ISCC.exe not found at: $isccPath" -ForegroundColor Red
    Write-Host "Set INNO_SETUP_PATH to your Inno Setup folder or ISCC.exe path." -ForegroundColor Yellow
    exit 1
}

$issFile = Join-Path $scriptDir "ServiceIntervention.iss"
Write-Host "Building installer..." -ForegroundColor Cyan
& $isccPath $issFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "Inno Setup compilation failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Installer created in installer\output" -ForegroundColor Green

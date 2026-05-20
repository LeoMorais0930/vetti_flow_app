# VETTI Flow - Deployment Script
$FlutterProjectDir = "C:\Users\Leonardo Morais\Desktop\vetti_flow_app"
$ApiProjectDir = "C:\Users\Leonardo Morais\Desktop\VettiFlow.Api"
$TargetDir = "$ApiProjectDir\wwwroot\gestor"

Write-Host "--- Starting Deploy to VETTI Flow Server ---" -ForegroundColor Cyan

# 1. Build Flutter Web
Write-Host "Step 1: Building Flutter Web..." -ForegroundColor Yellow
Set-Location $FlutterProjectDir
flutter build web --release --base-href "/gestor/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Exiting." -ForegroundColor Red
    exit 1
}

# 2. Prepare Target Directory
Write-Host "Step 2: Copying files to API wwwroot..." -ForegroundColor Yellow
if (!(Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir
} else {
    Remove-Item -Recurse -Force "$TargetDir\*"
}

Copy-Item -Recurse -Force "build\web\*" $TargetDir

# 3. Restart API (Optional - Assumes running via dotnet run or similar)
Write-Host "Step 3: Attempting to restart API..." -ForegroundColor Yellow
$ApiProcess = Get-Process "VettiFlow.Api" -ErrorAction SilentlyContinue
if ($ApiProcess) {
    Stop-Process -Name "VettiFlow.Api" -Force
    Write-Host "API process stopped." -ForegroundColor Gray
}

# Start API in a new window
Write-Host "Starting API..." -ForegroundColor Green
Set-Location $ApiProjectDir
Start-Process "dotnet" -ArgumentList "run" -WindowStyle Normal

Write-Host "--- Deployment Complete! ---" -ForegroundColor Cyan
Write-Host "Access at: http://10.36.0.4:5000/gestor/" -ForegroundColor White

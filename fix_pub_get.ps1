# Fix flutter pub get stuck issue
# Run this script to clear cache and retry

Write-Host "=== Fixing flutter pub get ===" -ForegroundColor Cyan
Write-Host ""

# Navigate to project
Set-Location "c:\Users\kevin\OneDrive\Desktop\Code\Aris Esthetician App"

# Step 1: Clean Flutter
Write-Host "Step 1: Cleaning Flutter..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: flutter clean had issues" -ForegroundColor Yellow
}

# Step 2: Remove lock files
Write-Host "Step 2: Removing lock files..." -ForegroundColor Yellow
Remove-Item -Path "pubspec.lock" -ErrorAction SilentlyContinue
Remove-Item -Path ".packages" -ErrorAction SilentlyContinue
if (Test-Path ".dart_tool") {
    Remove-Item -Path ".dart_tool" -Recurse -ErrorAction SilentlyContinue
}
Write-Host "✓ Lock files removed" -ForegroundColor Green

# Step 3: Repair pub cache
Write-Host "Step 3: Repairing pub cache..." -ForegroundColor Yellow
flutter pub cache repair
Write-Host "✓ Cache repair completed" -ForegroundColor Green

# Step 4: Try pub get with verbose
Write-Host ""
Write-Host "Step 4: Getting dependencies (verbose mode)..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Cyan
flutter pub get --verbose

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Dependencies installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. flutter pub run build_runner build --delete-conflicting-outputs" -ForegroundColor White
    Write-Host "2. flutterfire configure --project=ari-s-esthetician-app" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "✗ Failed to install dependencies" -ForegroundColor Red
    Write-Host "Check the verbose output above for errors" -ForegroundColor Yellow
    Write-Host "See TROUBLESHOOTING.md for more solutions" -ForegroundColor Yellow
}

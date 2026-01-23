# Setup Script for Ari's Esthetician App
# Run this script to set up the project

Write-Host "=== Ari's Esthetician App Setup ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Install dependencies
Write-Host "Step 1: Installing Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to install dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Step 2: Generate model files
Write-Host "Step 2: Generating model files..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to generate model files" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Model files generated" -ForegroundColor Green
Write-Host ""

# Step 3: Configure Firebase
Write-Host "Step 3: Configuring Firebase..." -ForegroundColor Yellow
Write-Host "Please run: flutterfire configure --project=ari-s-esthetician-app" -ForegroundColor Cyan
Write-Host ""

# Step 4: Deploy Firestore rules
Write-Host "Step 4: Deploy Firestore rules..." -ForegroundColor Yellow
Write-Host "Please run: firebase deploy --only firestore" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: flutterfire configure --project=ari-s-esthetician-app" -ForegroundColor White
Write-Host "2. Run: firebase deploy --only firestore" -ForegroundColor White
Write-Host "3. Create admin user (see scripts/create_admin_user.md)" -ForegroundColor White

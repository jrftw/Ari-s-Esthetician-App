# Firebase Setup Script
# Run this script to set up Firebase for your Flutter app

# Add npm to PATH for this session
$env:Path += ";$env:APPDATA\npm"

Write-Host "=== Firebase Setup ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify Firebase CLI
Write-Host "Step 1: Verifying Firebase CLI..." -ForegroundColor Yellow
firebase --version
Write-Host ""

# Step 2: Login to Firebase
Write-Host "Step 2: Logging in to Firebase..." -ForegroundColor Yellow
Write-Host "A browser window will open - please sign in with your Google account" -ForegroundColor Cyan
firebase login
Write-Host ""

# Step 3: Verify project access
Write-Host "Step 3: Verifying project access..." -ForegroundColor Yellow
firebase projects:list
Write-Host ""

# Step 4: Set default project
Write-Host "Step 4: Setting default project..." -ForegroundColor Yellow
firebase use ari-s-esthetician-app
Write-Host ""

# Step 5: Install FlutterFire CLI (if needed)
Write-Host "Step 5: Installing FlutterFire CLI..." -ForegroundColor Yellow
dart pub global activate flutterfire_cli
Write-Host ""

# Step 6: Configure Flutter app
Write-Host "Step 6: Configuring Flutter app..." -ForegroundColor Yellow
Write-Host "When prompted, select: Web, Android, iOS" -ForegroundColor Cyan
flutterfire configure --project=ari-s-esthetician-app
Write-Host ""

# Step 7: Deploy Firestore rules
Write-Host "Step 7: Deploying Firestore rules..." -ForegroundColor Yellow
firebase deploy --only firestore
Write-Host ""

Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Test the app with: flutter run -d chrome" -ForegroundColor Yellow

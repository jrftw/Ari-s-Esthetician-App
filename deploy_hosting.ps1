# Filename: deploy_hosting.ps1
# Purpose: Build Flutter web app and deploy to Firebase Hosting
# Author: Kevin Doyle Jr. / Infinitum Imagery LLC
# Last Modified: 2026-01-30
# Dependencies: Flutter, Firebase CLI, Git (optional, for commit hash)
# Platform Compatibility: Windows PowerShell
#
# When run from a git repo, the current short commit hash is passed into the app
# so the deployed version displays it next to the version (e.g. 1.0.0 Build 3 abc1234).

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Flutter Web App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get short commit hash for version display (empty if not in git or error)
$commitHash = ""
try {
    $commitHash = git rev-parse --short HEAD 2>$null
    if ($commitHash) {
        Write-Host "Commit hash for this build: $commitHash" -ForegroundColor Gray
    }
} catch {
    # Not in git or git unavailable; build without hash
}

# Build Flutter web app with optional commit hash for deployed version display
flutter build web --release --dart-define=COMMIT_HASH=$commitHash

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deploying to Firebase Hosting" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Add npm global directory to PATH if not already present
$npmGlobalPath = "$env:APPDATA\npm"
if ($env:Path -notlike "*$npmGlobalPath*") {
    $env:Path += ";$npmGlobalPath"
}

# Check if Firebase CLI is installed
$firebaseCmd = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseCmd) {
    Write-Host "❌ Firebase CLI is not installed or not in PATH!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To install Firebase CLI, run:" -ForegroundColor Yellow
    Write-Host "  npm install -g firebase-tools" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Then login to Firebase:" -ForegroundColor Yellow
    Write-Host "  firebase login" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

# Deploy to Firebase Hosting
firebase deploy --only hosting

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Firebase deployment failed!" -ForegroundColor Red
    exit 1
}

# MARK: - Update Firestore app_version/latest (so app forces this deployed version except in dev)
try {
    $versionLine = (Get-Content pubspec.yaml | Select-String "^version:").Line
    if ($versionLine -match "version:\s*([\d.]+)\+(\d+)") {
        $ver = $Matches[1]
        $build = $Matches[2]
        Write-Host ""
        Write-Host "Updating Firestore app_version/latest to $ver (Build $build)..." -ForegroundColor Gray
        node scripts/update_app_version_firestore.js $ver $build 2>&1 | Out-Host
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Version forcing updated: clients will be required to use this build (except in development)" -ForegroundColor Green
        } else {
            Write-Host "⚠ Could not update app_version in Firestore (set GOOGLE_APPLICATION_CREDENTIALS or run script manually)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "⚠ Skipped updating app_version in Firestore: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "Your app is live at:" -ForegroundColor Green
Write-Host "  https://ari-s-esthetician-app.web.app" -ForegroundColor Yellow
Write-Host "  https://ari-s-esthetician-app.firebaseapp.com" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

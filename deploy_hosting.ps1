# Filename: deploy_hosting.ps1
# Purpose: Build Flutter web app and deploy to Firebase Hosting
# Author: Kevin Doyle Jr. / Infinitum Imagery LLC
# Last Modified: 2025-01-22
# Dependencies: Flutter, Firebase CLI
# Platform Compatibility: Windows PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Flutter Web App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Build Flutter web app
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter build failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deploying to Firebase Hosting" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Deploy to Firebase Hosting
firebase deploy --only hosting

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Firebase deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "Your app is live at:" -ForegroundColor Green
Write-Host "  https://ari-s-esthetician-app.web.app" -ForegroundColor Yellow
Write-Host "  https://ari-s-esthetician-app.firebaseapp.com" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

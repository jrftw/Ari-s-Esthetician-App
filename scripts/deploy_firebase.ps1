# Filename: deploy_firebase.ps1
# Purpose: Comprehensive Firebase deployment script that handles indexes, rules, storage, and initial documents
# Author: Kevin Doyle Jr. / Infinitum Imagery LLC
# Last Modified: 2026-01-22
# Dependencies: Firebase CLI, Node.js, Firebase Admin SDK
# Platform Compatibility: Windows PowerShell
#
# Usage:
#   .\scripts\deploy_firebase.ps1
#   .\scripts\deploy_firebase.ps1 -SkipInitialization
#   .\scripts\deploy_firebase.ps1 -OnlyRules
#   .\scripts\deploy_firebase.ps1 -OnlyInitialization

# MARK: - Parameters
param(
    [switch]$SkipInitialization,
    [switch]$OnlyRules,
    [switch]$OnlyInitialization
)

# MARK: - Configuration
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ProjectId = "ari-s-esthetician-app"

# MARK: - Helper Functions
function Write-Step {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Yellow
}

# MARK: - Check Prerequisites
function Test-Prerequisites {
    Write-Step "Checking Prerequisites"
    
    # Check Firebase CLI
    try {
        $firebaseVersion = firebase --version 2>&1
        Write-Success "Firebase CLI installed: $firebaseVersion"
    } catch {
        Write-Error "Firebase CLI not found. Install with: npm install -g firebase-tools"
        exit 1
    }
    
    # Check Node.js
    try {
        $nodeVersion = node --version 2>&1
        Write-Success "Node.js installed: $nodeVersion"
    } catch {
        Write-Error "Node.js not found. Please install Node.js"
        exit 1
    }
    
    # Check if logged in to Firebase
    try {
        $firebaseUser = firebase login:list 2>&1
        if ($firebaseUser -match $ProjectId) {
            Write-Success "Firebase CLI is logged in"
        } else {
            Write-Info "Firebase CLI may not be logged in. Run: firebase login"
        }
    } catch {
        Write-Info "Could not verify Firebase login status"
    }
    
    # Check Firebase Admin SDK
    $packageJsonPath = Join-Path $ProjectRoot "package.json"
    if (Test-Path $packageJsonPath) {
        $packageJson = Get-Content $packageJsonPath | ConvertFrom-Json
        if ($packageJson.dependencies.'firebase-admin' -or $packageJson.devDependencies.'firebase-admin') {
            Write-Success "Firebase Admin SDK found in package.json"
        } else {
            Write-Info "Firebase Admin SDK not found. Installing..."
            Set-Location $ProjectRoot
            npm install firebase-admin --save-dev
            Write-Success "Firebase Admin SDK installed"
        }
    } else {
        Write-Info "package.json not found. Creating..."
        Set-Location $ProjectRoot
        npm init -y
        npm install firebase-admin --save-dev
        Write-Success "package.json created and Firebase Admin SDK installed"
    }
}

# MARK: - Deploy Firestore Rules and Indexes
function Deploy-FirestoreRules {
    Write-Step "Deploying Firestore Rules and Indexes"
    
    Set-Location $ProjectRoot
    
    try {
        Write-Info "Deploying Firestore rules and indexes..."
        firebase deploy --only firestore --project $ProjectId
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Firestore rules and indexes deployed successfully"
        } else {
            Write-Error "Failed to deploy Firestore rules and indexes"
            exit 1
        }
    } catch {
        Write-Error "Error deploying Firestore: $_"
        exit 1
    }
}

# MARK: - Deploy Storage Rules
function Deploy-StorageRules {
    Write-Step "Deploying Storage Rules"
    
    Set-Location $ProjectRoot
    
    try {
        Write-Info "Deploying Storage rules..."
        firebase deploy --only storage --project $ProjectId
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Storage rules deployed successfully"
        } else {
            Write-Error "Failed to deploy Storage rules"
            exit 1
        }
    } catch {
        Write-Error "Error deploying Storage: $_"
        exit 1
    }
}

# MARK: - Initialize Firestore Documents
function Initialize-FirestoreDocuments {
    Write-Step "Initializing Firestore Documents"
    
    Set-Location $ProjectRoot
    
    # Check for service account credentials
    if (-not $env:GOOGLE_APPLICATION_CREDENTIALS) {
        Write-Info "GOOGLE_APPLICATION_CREDENTIALS not set"
        Write-Info "You can set it with:"
        Write-Host "  `$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\path\to\serviceAccountKey.json'" -ForegroundColor Yellow
        Write-Info "Or use Application Default Credentials (gcloud auth application-default login)"
    }
    
    try {
        Write-Info "Running Firestore initialization script..."
        node "$ScriptDir\initialize_firestore.js"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Firestore documents initialized successfully"
        } else {
            Write-Error "Failed to initialize Firestore documents"
            Write-Info "You can run this manually later with: node scripts\initialize_firestore.js"
        }
    } catch {
        Write-Error "Error initializing Firestore documents: $_"
        Write-Info "You can run this manually later with: node scripts\initialize_firestore.js"
    }
}

# MARK: - Main Deployment Function
function Start-Deployment {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  Firebase Deployment Script" -ForegroundColor Cyan
    Write-Host "  Project: $ProjectId" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Check prerequisites
    Test-Prerequisites
    
    # Determine what to deploy
    if ($OnlyRules) {
        # Deploy only rules and indexes
        Deploy-FirestoreRules
        Deploy-StorageRules
    } elseif ($OnlyInitialization) {
        # Only initialize documents
        Initialize-FirestoreDocuments
    } else {
        # Full deployment
        Deploy-FirestoreRules
        Deploy-StorageRules
        
        if (-not $SkipInitialization) {
            Initialize-FirestoreDocuments
        } else {
            Write-Info "Skipping document initialization (use -SkipInitialization=false to include)"
        }
    }
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Deployment Complete!" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  ✓ Firestore rules deployed" -ForegroundColor Green
    Write-Host "  ✓ Firestore indexes deployed" -ForegroundColor Green
    Write-Host "  ✓ Storage rules deployed" -ForegroundColor Green
    if (-not $SkipInitialization) {
        Write-Host "  ✓ Default documents initialized" -ForegroundColor Green
    }
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Verify rules in Firebase Console" -ForegroundColor White
    Write-Host "  2. Check indexes are building (may take a few minutes)" -ForegroundColor White
    Write-Host "  3. Update business settings in admin dashboard" -ForegroundColor White
    if (-not $SkipInitialization) {
        Write-Host "  4. Create admin user: node scripts\create_admin_user.js <email> <password>" -ForegroundColor White
    }
}

# MARK: - Main Execution
try {
    Start-Deployment
} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

# Suggestions For Features and Additions Later:
# - Add rollback functionality
# - Add dry-run mode
# - Add deployment verification checks
# - Add email notifications on deployment
# - Add deployment history logging

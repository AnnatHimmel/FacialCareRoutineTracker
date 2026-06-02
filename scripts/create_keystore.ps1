<#
.SYNOPSIS
  One-time setup: generates a release keystore and writes android/key.properties.

.DESCRIPTION
  Run this ONCE before the first Play Store release.
  Keep the generated .jks file and key.properties OUTSIDE version control
  (both are already in android/.gitignore).

  Prerequisites:
    - Java JDK installed (keytool must be on PATH)
    - Run from the repo root: .\scripts\create_keystore.ps1
#>

param(
    [string]$KeystorePath = "android\release.keystore",
    [string]$KeyAlias     = "skincare_release"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$keystoreFullPath = Join-Path $repoRoot $KeystorePath
$keyPropertiesPath = Join-Path $repoRoot "android\key.properties"

# ── Guard: don't overwrite an existing keystore ───────────────────────────────
if (Test-Path $keystoreFullPath) {
    Write-Error "Keystore already exists at '$keystoreFullPath'. Delete it first if you really want to regenerate."
    exit 1
}

if (Test-Path $keyPropertiesPath) {
    Write-Warning "key.properties already exists. It will be overwritten."
}

# ── Collect passwords interactively ──────────────────────────────────────────
Write-Host ""
Write-Host "=== Skincare Tracker — Release Keystore Setup ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "You will be prompted for two passwords:"
Write-Host "  • Store password  — protects the keystore file itself"
Write-Host "  • Key password    — protects this specific signing key"
Write-Host ""
Write-Host "Store both passwords in a password manager. Losing them means"
Write-Host "you cannot update the app on existing user devices." -ForegroundColor Yellow
Write-Host ""

$storePass = Read-Host "Enter store password (min 6 chars)" -AsSecureString
$storePassConfirm = Read-Host "Confirm store password" -AsSecureString
$keyPass = Read-Host "Enter key password (min 6 chars)" -AsSecureString
$keyPassConfirm = Read-Host "Confirm key password" -AsSecureString

function SecureToPlain([System.Security.SecureString]$s) {
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($s)
    try { return [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ptr) }
}

$storePlain = SecureToPlain $storePass
$storeConfirmPlain = SecureToPlain $storePassConfirm
$keyPlain = SecureToPlain $keyPass
$keyConfirmPlain = SecureToPlain $keyPassConfirm

if ($storePlain -ne $storeConfirmPlain) { Write-Error "Store passwords do not match."; exit 1 }
if ($keyPlain -ne $keyConfirmPlain)     { Write-Error "Key passwords do not match.";   exit 1 }
if ($storePlain.Length -lt 6)           { Write-Error "Store password must be at least 6 characters."; exit 1 }
if ($keyPlain.Length -lt 6)             { Write-Error "Key password must be at least 6 characters.";   exit 1 }

# ── Collect distinguished name fields ────────────────────────────────────────
Write-Host ""
$cn = Read-Host "Your name or organization (e.g. 'Anna Sh')"
$ou = Read-Host "Organizational unit (e.g. 'Mobile')"
$o  = Read-Host "Organization (e.g. 'Skincare Tracker')"
$l  = Read-Host "City"
$st = Read-Host "State / Province"
$c  = Read-Host "2-letter country code (e.g. IL)"

$dname = "CN=$cn, OU=$ou, O=$o, L=$l, ST=$st, C=$c"

# ── Run keytool ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Generating keystore..." -ForegroundColor Cyan

$keytoolArgs = @(
    "-genkeypair"
    "-v"
    "-keystore", $keystoreFullPath
    "-alias", $KeyAlias
    "-keyalg", "RSA"
    "-keysize", "2048"
    "-validity", "10000"
    "-storepass", $storePlain
    "-keypass", $keyPlain
    "-dname", $dname
)

& keytool $keytoolArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "keytool failed (exit $LASTEXITCODE). Is the JDK on your PATH?"
    exit 1
}

# ── Write key.properties ──────────────────────────────────────────────────────
# Use a forward-slash path (Gradle runs on JVM and handles both separators,
# but forward slashes are safest across platforms).
$gradlePath = $keystoreFullPath.Replace('\', '/')

@"
storePassword=$storePlain
keyPassword=$keyPlain
keyAlias=$KeyAlias
storeFile=$gradlePath
"@ | Set-Content $keyPropertiesPath -Encoding utf8

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host "  Keystore : $keystoreFullPath"
Write-Host "  Config   : $keyPropertiesPath"
Write-Host ""
Write-Host "IMPORTANT — back up these two files to secure off-repo storage." -ForegroundColor Yellow
Write-Host "They are in .gitignore and will never be committed."

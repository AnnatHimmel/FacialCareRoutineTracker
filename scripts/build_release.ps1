<#
.SYNOPSIS
  Build a signed release AAB ready for Play Store upload.

.DESCRIPTION
  1. Verifies android/key.properties exists (run create_keystore.ps1 first).
  2. Bumps the build number (versionCode) in pubspec.yaml — required to be
     strictly increasing for every Play Store submission.
  3. Runs flutter build appbundle --release.
  4. Prints the output path and a reminder of the next steps.

  Run from the repo root:
      .\scripts\build_release.ps1

  Optional flags:
      -SkipVersionBump   Keep current version/build number (e.g. for a retry).
      -Clean             Run `flutter clean` before building.
#>

param(
    [switch]$SkipVersionBump,
    [switch]$Clean
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot        = Split-Path $PSScriptRoot -Parent
$keyPropertiesPath = Join-Path $repoRoot "android\key.properties"
$pubspecPath       = Join-Path $repoRoot "pubspec.yaml"

# ── 1. Pre-flight checks ──────────────────────────────────────────────────────
if (-not (Test-Path $keyPropertiesPath)) {
    Write-Error @"
android/key.properties not found.
Run the one-time setup first:
    .\scripts\create_keystore.ps1
"@
    exit 1
}

if (-not (Test-Path $pubspecPath)) {
    Write-Error "pubspec.yaml not found. Are you running from the repo root?"
    exit 1
}

# Verify keytool / Java are available (needed by Gradle, not called directly
# here, but a missing JDK is a common cause of silent build failures).
if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    Write-Warning "keytool not found on PATH — make sure a JDK is installed."
}

# ── 2. Parse and bump pubspec version ────────────────────────────────────────
$pubspec = Get-Content $pubspecPath -Raw

# version line format:  version: 1.2.3+45
if ($pubspec -notmatch 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    Write-Error "Could not parse version line in pubspec.yaml. Expected format: version: X.Y.Z+N"
    exit 1
}

$semver     = $Matches[1]           # e.g. "1.0.0"
$buildNum   = [int]$Matches[2]      # e.g. 1

if ($SkipVersionBump) {
    $newBuildNum = $buildNum
    Write-Host "Skipping version bump — keeping $semver+$buildNum" -ForegroundColor Yellow
} else {
    $newBuildNum = $buildNum + 1
    $newVersion  = "$semver+$newBuildNum"
    $pubspec     = $pubspec -replace "version:\s*$([regex]::Escape($semver))\+$buildNum", "version: $newVersion"
    Set-Content $pubspecPath $pubspec -Encoding utf8 -NoNewline
    Write-Host "Version bumped: $semver+$buildNum  →  $newVersion" -ForegroundColor Cyan
}

$displayVersion = "$semver+$newBuildNum"

# ── 3. Optional clean ─────────────────────────────────────────────────────────
if ($Clean) {
    Write-Host ""
    Write-Host "Running flutter clean..." -ForegroundColor Cyan
    Push-Location $repoRoot
    flutter clean
    if ($LASTEXITCODE -ne 0) { Write-Error "flutter clean failed."; exit 1 }
    Pop-Location
}

# ── 4. Build the AAB ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Building release AAB ($displayVersion)..." -ForegroundColor Cyan
Write-Host ""

Push-Location $repoRoot
flutter build appbundle --release --dart-define-from-file=credentials.json
$buildExit = $LASTEXITCODE
Pop-Location

if ($buildExit -ne 0) {
    # Roll back the version bump so re-running works cleanly.
    if (-not $SkipVersionBump -and $newBuildNum -ne $buildNum) {
        $pubspec = Get-Content $pubspecPath -Raw
        $pubspec = $pubspec -replace "version:\s*$([regex]::Escape($semver))\+$newBuildNum", "version: $semver+$buildNum"
        Set-Content $pubspecPath $pubspec -Encoding utf8 -NoNewline
        Write-Warning "Build failed — version rolled back to $semver+$buildNum."
    }
    Write-Error "flutter build appbundle failed (exit $buildExit)."
    exit 1
}

# ── 5. Report output ──────────────────────────────────────────────────────────
$aabPath = Join-Path $repoRoot "build\app\outputs\bundle\release\app-release.aab"

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  BUILD SUCCEEDED  —  $displayVersion" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  AAB:  $aabPath"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Commit the pubspec.yaml version bump."
Write-Host "  2. Tag the commit:  git tag v$displayVersion"
Write-Host "  3. Upload $aabPath to Play Console."
Write-Host "     (Production > Create new release > Upload)"
Write-Host ""
Write-Host "Reminder: the build number ($newBuildNum) must never be reused."
Write-Host "Each Play Store upload requires a strictly higher versionCode." -ForegroundColor Yellow

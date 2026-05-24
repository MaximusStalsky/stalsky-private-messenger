param(
    [string]$WebUrl = "http://127.0.0.1:8080",
    [string]$ApiUrl = "http://127.0.0.1:8080/api/health",
    [switch]$RunPackageChecks
)

$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "== $Title =="
}

function Test-Url {
    param(
        [string]$Name,
        [string]$Url
    )

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 5 -UseBasicParsing
        Write-Host "[ok] $Name responded with HTTP $($response.StatusCode): $Url"
    }
    catch {
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 5 -UseBasicParsing
            Write-Host "[ok] $Name responded with HTTP $($response.StatusCode): $Url"
        }
        catch {
            Write-Host "[warn] $Name did not respond at $Url"
            Write-Host "       $($_.Exception.Message)"
        }
    }
}

function Get-PackageManager {
    param([string]$Directory)

    if (Test-Path (Join-Path $Directory "pnpm-lock.yaml")) { return "pnpm" }
    if (Test-Path (Join-Path $Directory "package-lock.json")) { return "npm" }
    if (Test-Path (Join-Path $Directory "yarn.lock")) { return "yarn" }
    return "npm"
}

function Get-PackageScripts {
    param([string]$PackageJsonPath)

    try {
        $package = Get-Content -Raw -Path $PackageJsonPath | ConvertFrom-Json
        if ($null -eq $package.scripts) { return @() }
        return $package.scripts.PSObject.Properties.Name
    }
    catch {
        Write-Host "[warn] Could not parse $PackageJsonPath"
        return @()
    }
}

function Invoke-PackageScriptIfPresent {
    param(
        [string]$Directory,
        [string]$ScriptName
    )

    $packageJson = Join-Path $Directory "package.json"
    if (-not (Test-Path $packageJson)) { return }

    $scripts = Get-PackageScripts -PackageJsonPath $packageJson
    if ($scripts -notcontains $ScriptName) { return }

    $manager = Get-PackageManager -Directory $Directory
    Write-Host "[run] $ScriptName in $Directory using $manager"

    Push-Location $Directory
    try {
        if ($manager -eq "pnpm") {
            & pnpm run $ScriptName
        }
        elseif ($manager -eq "yarn") {
            & yarn $ScriptName
        }
        else {
            & npm run $ScriptName
        }
    }
    finally {
        Pop-Location
    }
}

$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")

Write-Section "Project Folders"
foreach ($folder in @("server", "apps", "docs", "scripts\qa")) {
    $path = Join-Path $root $folder
    if (Test-Path $path) {
        Write-Host "[ok] $folder exists"
    }
    else {
        Write-Host "[warn] $folder is missing"
    }
}

Write-Section "Package Scripts"
$packageDirs = @()
$serverPackage = Join-Path $root "server\package.json"
if (Test-Path $serverPackage) {
    $packageDirs += (Split-Path $serverPackage -Parent)
}

$appsDir = Join-Path $root "apps"
if (Test-Path $appsDir) {
    $packageDirs += Get-ChildItem -Path $appsDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName "package.json") } |
        ForEach-Object { $_.FullName }
}

$flutterApp = Join-Path $root "apps\messenger_app\pubspec.yaml"
if (Test-Path $flutterApp) {
    Write-Host "[info] Flutter app found: apps\messenger_app"
}

if ($packageDirs.Count -eq 0) {
    Write-Host "[info] No package.json files found in server/ or direct apps/ children."
}
else {
    foreach ($dir in $packageDirs) {
        $scripts = Get-PackageScripts -PackageJsonPath (Join-Path $dir "package.json")
        if ($scripts.Count -eq 0) {
            Write-Host "[info] $dir has no package scripts."
        }
        else {
            Write-Host "[info] $dir scripts: $($scripts -join ', ')"
        }
    }
}

if ($RunPackageChecks) {
    Write-Section "Package Checks"
    foreach ($dir in $packageDirs) {
        Invoke-PackageScriptIfPresent -Directory $dir -ScriptName "lint"
        Invoke-PackageScriptIfPresent -Directory $dir -ScriptName "test"
    }
}
else {
    Write-Section "Package Checks"
    Write-Host "[skip] Add -RunPackageChecks to run available lint and test scripts."
}

Write-Section "URL Checks"
Test-Url -Name "Web app" -Url $WebUrl
Test-Url -Name "API server" -Url $ApiUrl

Write-Section "Flutter Checks"
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutter) {
    $localFlutter = "C:\Users\rdzio\Tools\flutter\bin\flutter.bat"
    if (Test-Path $localFlutter) {
        Write-Host "[info] Flutter found at $localFlutter; add C:\Users\rdzio\Tools\flutter\bin to PATH."
    }
    else {
        Write-Host "[warn] Flutter was not found."
    }
}
else {
    Write-Host "[ok] Flutter available at $($flutter.Source)"
}

Write-Section "Manual QA"
Write-Host "Use docs\qa-checklist.md for the prototype checklist."

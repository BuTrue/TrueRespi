#requires -Version 5.1
<#
.SYNOPSIS
    Install TrueRespi from the command line (Windows 10/11 x64).

.DESCRIPTION
    Downloads the official NSIS installer, verifies its SHA256 against the
    release checksum file, then runs a silent per-user install.
    The command line tools `truerespi.exe` (CLI) and `truerespi-mcp.exe`
    (MCP stdio server) are installed under <InstallDir>\bin; add that folder
    to PATH yourself if you want them available from any terminal.

.PARAMETER Version
    Release tag without the leading "v" (default: latest release).

.PARAMETER InstallDir
    Optional install directory. Defaults to the installer's per-user location,
    %LOCALAPPDATA%\TrueRespi.

.PARAMETER Uninstall
    Run the uninstaller from InstallDir instead of installing.

.PARAMETER Quiet
    Suppress progress messages.

.EXAMPLE
    irm https://raw.githubusercontent.com/BuTrue/TrueRespi/main/install.ps1 | iex

.EXAMPLE
    .\install.ps1 -Version 0.1.2 -InstallDir D:\Apps\TrueRespi
#>
[CmdletBinding()]
param(
    [string]$Version = "latest",
    [string]$InstallDir = "",
    [switch]$Uninstall,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$Repo = "BuTrue/TrueRespi"

function Write-Step([string]$Message) {
    if (-not $Quiet) { Write-Host "==> $Message" -ForegroundColor Cyan }
}

function Resolve-Version([string]$Requested) {
    if ($Requested -and $Requested -ne "latest") {
        return $Requested.TrimStart("v", "V")
    }
    # `main/VERSION` is updated as part of every release and is not subject to
    # the unauthenticated GitHub API rate limit.
    try {
        $text = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$Repo/main/VERSION" `
            -UseBasicParsing -TimeoutSec 30).Content
        if ($text -is [byte[]]) { $text = [System.Text.Encoding]::UTF8.GetString($text) }
        $value = ($text -split "\s+")[0].Trim().TrimStart("v", "V")
        if ($value -match "^\d+\.\d+\.\d+") { return $value }
    } catch {
        # Fall through to the API below.
    }
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" `
        -Headers @{ "User-Agent" = "TrueRespi-Installer" } -UseBasicParsing
    if (-not $release.tag_name) {
        throw "Could not resolve the latest release. Pass -Version explicitly."
    }
    return $release.tag_name.TrimStart("v", "V")
}

function Get-InstallDir([string]$Explicit) {
    if ($Explicit) { return [System.IO.Path]::GetFullPath($Explicit) }
    return Join-Path $env:LOCALAPPDATA "TrueRespi"
}

$targetDir = Get-InstallDir $InstallDir

if ($Uninstall) {
    $uninstaller = Join-Path $targetDir "uninstall.exe"
    if (-not (Test-Path $uninstaller)) {
        throw "Uninstaller not found: $uninstaller"
    }
    Write-Step "Uninstalling TrueRespi from $targetDir"
    $process = Start-Process -FilePath $uninstaller -ArgumentList "/S" -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Uninstall failed with exit code $($process.ExitCode)." }
    Write-Step "TrueRespi uninstalled."
    return
}

$resolved = Resolve-Version $Version
$asset = "TrueRespi-$resolved-Setup.exe"
$base = "https://github.com/$Repo/releases/download/v$resolved"
$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) $asset

Write-Step "Installing TrueRespi $resolved"
Write-Step "Downloading $asset"
Invoke-WebRequest -Uri "$base/$asset" -OutFile $tempFile -UseBasicParsing

Write-Step "Verifying SHA256"
$sums = (Invoke-WebRequest -Uri "$base/SHA256SUMS.txt" -UseBasicParsing).Content
if ($sums -is [byte[]]) { $sums = [System.Text.Encoding]::UTF8.GetString($sums) }
$expected = ($sums -split "\s+")[0].Trim().ToLowerInvariant()
$actual = (Get-FileHash -Path $tempFile -Algorithm SHA256).Hash.ToLowerInvariant()
if ($expected -ne $actual) {
    throw "SHA256 mismatch: expected $expected, got $actual. The download was discarded."
}

# NSIS: /S runs the installer silently. /D=<dir> must be the last argument and
# must not be quoted; without it the installer uses its default per-user dir.
$arguments = @("/S")
if ($InstallDir) { $arguments += "/D=$targetDir" }

Write-Step "Running silent installer"
$process = Start-Process -FilePath $tempFile -ArgumentList $arguments -PassThru -Wait
if ($process.ExitCode -ne 0) { throw "Installer failed with exit code $($process.ExitCode)." }
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

$cli = Join-Path $targetDir "bin\truerespi.exe"
$mcp = Join-Path $targetDir "bin\truerespi-mcp.exe"
if (-not (Test-Path $cli)) {
    # An earlier version may already be installed in a custom directory.
    $roots = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        $entry = Get-ChildItem $root -ErrorAction SilentlyContinue |
            ForEach-Object { Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue } |
            Where-Object { $_.DisplayName -like "TrueRespi*" } |
            Select-Object -First 1
        if ($entry -and $entry.InstallLocation) {
            $candidate = $entry.InstallLocation.TrimEnd("\")
            $candidateCli = Join-Path $candidate "bin\truerespi.exe"
            if (Test-Path $candidateCli) {
                $targetDir = $candidate
                $cli = $candidateCli
                $mcp = Join-Path $candidate "bin\truerespi-mcp.exe"
                break
            }
        }
    }
}
if (-not (Test-Path $cli)) {
    throw "Install finished but $cli is missing. Check the installer log in %TEMP%."
}

Write-Step "Installed to $targetDir"
if (-not $Quiet) {
    Write-Host ""
    Write-Host "Command line tools: $targetDir\bin" -ForegroundColor Green
    Write-Host "Add that folder to PATH, then try:"
    Write-Host "  truerespi --version"
    Write-Host "  truerespi list `"D:\your-data`" --recursive --ext mkt --json"
    Write-Host "  truerespi crop `"D:\your-data`" -o `"D:\export`" --every 3600 --format txt --recursive"
    Write-Host ""
    Write-Host "MCP server: $mcp"
}

#requires -Version 5.1
<#
.SYNOPSIS
    Install TrueRespi from the command line (Windows 10/11 x64).

.DESCRIPTION
    Downloads the official Inno Setup installer, verifies its SHA256 against
    the release checksum file, then runs a silent per-user install.
    The installer adds both `truerespi.exe` (CLI) and `truerespi-mcp.exe`
    (MCP stdio server) to the current user's PATH.

.PARAMETER Version
    Release tag without the leading "v" (default: latest release).

.PARAMETER InstallDir
    Optional install directory. Defaults to the installer's per-user location,
    %LOCALAPPDATA%\Programs\TrueRespi.

.PARAMETER Uninstall
    Run the uninstaller from InstallDir instead of installing.

.PARAMETER Quiet
    Suppress progress messages.

.EXAMPLE
    irm https://raw.githubusercontent.com/BuTrue/TrueRespi/main/install.ps1 | iex

.EXAMPLE
    .\install.ps1 -Version 0.1.1 -InstallDir D:\Apps\TrueRespi
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
    return Join-Path $env:LOCALAPPDATA "Programs\TrueRespi"
}

$targetDir = Get-InstallDir $InstallDir

if ($Uninstall) {
    $uninstaller = Join-Path $targetDir "unins000.exe"
    if (-not (Test-Path $uninstaller)) {
        throw "Uninstaller not found: $uninstaller"
    }
    Write-Step "Uninstalling TrueRespi from $targetDir"
    $process = Start-Process -FilePath $uninstaller `
        -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" `
        -PassThru -Wait
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

$arguments = @("/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART")
if ($InstallDir) { $arguments += "/DIR=`"$targetDir`"" }

Write-Step "Running silent installer"
$process = Start-Process -FilePath $tempFile -ArgumentList $arguments -PassThru -Wait
if ($process.ExitCode -ne 0) { throw "Installer failed with exit code $($process.ExitCode)." }
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

$cli = Join-Path $targetDir "bin\truerespi.exe"
$mcp = Join-Path $targetDir "bin\truerespi-mcp.exe"
if (-not (Test-Path $cli)) {
    # Overwrite installs may reuse a custom directory chosen earlier.
    $uninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{A1B2C3D4-6E7F-4A8B-9C0D-1E2F3A4B5C6D}_is1"
    if (Test-Path $uninstallKey) {
        $location = (Get-ItemProperty -Path $uninstallKey -ErrorAction SilentlyContinue).InstallLocation
        if ($location) {
            $targetDir = $location.TrimEnd("\")
            $cli = Join-Path $targetDir "bin\truerespi.exe"
            $mcp = Join-Path $targetDir "bin\truerespi-mcp.exe"
        }
    }
}
if (-not (Test-Path $cli)) {
    throw "Install finished but $cli is missing. Check the installer log in %TEMP%."
}

Write-Step "Installed to $targetDir"
if (-not $Quiet) {
    Write-Host ""
    Write-Host "Open a new terminal, then try:" -ForegroundColor Green
    Write-Host "  truerespi --version"
    Write-Host "  truerespi list `"D:\your-data`" --recursive --ext mkt --json"
    Write-Host "  truerespi crop `"D:\your-data`" -o `"D:\export`" --every 3600 --format txt --recursive"
    Write-Host ""
    Write-Host "MCP server: $mcp"
}

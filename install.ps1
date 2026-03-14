# SessionCast CLI Installer for Windows
# Usage: irm https://raw.githubusercontent.com/sessioncast/sessioncast-cli-release/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$ReleaseRepo = "sessioncast/sessioncast-cli-release"
$InstallDir = "$env:USERPROFILE\.sessioncast\bin"

# Colors
function Write-Info { Write-Host "➜ $args" -ForegroundColor Blue }
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Err { Write-Host "✗ $args" -ForegroundColor Red; exit 1 }

# Detect architecture
$Arch = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { Write-Err "Only 64-bit Windows is supported" }

# Get latest version
Write-Info "Checking latest version..."
$LatestRelease = Invoke-RestMethod "https://api.github.com/repos/$ReleaseRepo/releases/latest"
$Version = $LatestRelease.tag_name
Write-Info "Version: $Version"

# Download
$ArchiveName = "sessioncast-$Arch-windows.zip"
$DownloadUrl = "https://github.com/$ReleaseRepo/releases/download/$Version/$ArchiveName"
$DownloadPath = "$env:TEMP\sessioncast.zip"

Write-Info "Downloading $ArchiveName..."
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadPath -UseBasicParsing
} catch {
    Write-Err "Download failed: $_"
}

# Extract
Write-Info "Extracting..."
$ExtractPath = "$env:TEMP\sessioncast-extract"
if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
Expand-Archive -Path $DownloadPath -DestinationPath $ExtractPath -Force

# Install
Write-Info "Installing..."
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Move-Item "$ExtractPath\sessioncast.exe" "$InstallDir\sessioncast.exe" -Force

# Cleanup
Remove-Item $DownloadPath -Force
Remove-Item $ExtractPath -Recurse -Force

# Setup PATH
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($CurrentPath -notlike "*$InstallDir*") {
    Write-Info "Adding to PATH..."
    [Environment]::SetEnvironmentVariable("PATH", "$CurrentPath;$InstallDir", "User")
    $env:PATH += ";$InstallDir"
}

Write-Success "Installation complete!"
Write-Host ""

# Install dependencies automatically
Write-Info "Installing dependencies..."
& "$InstallDir\sessioncast.exe" deps install
Write-Host ""

Write-Host "  Run: " -NoNewline
Write-Host "sessioncast" -ForegroundColor Green
Write-Host ""

# Output PATH for immediate use
Write-Output "export PATH=`"`$env:PATH;$InstallDir`""

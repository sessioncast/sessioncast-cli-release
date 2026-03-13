# SessionCast CLI Release Binaries

This repository contains release binaries for [SessionCast CLI](https://github.com/sessioncast/sessioncast-cli).

## Installation

### macOS / Linux

```bash
curl -sL https://github.com/sessioncast/sessioncast-cli-release/releases/latest/download/sessioncast-$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]').tar.gz | sudo tar xz -C /usr/local/bin
```

### Windows (PowerShell)

```powershell
# Download and extract
Invoke-WebRequest -Uri "https://github.com/sessioncast/sessioncast-cli-release/releases/latest/download/sessioncast-x86_64-windows.zip" -OutFile "$env:TEMP\sessioncast.zip"
Expand-Archive -Path "$env:TEMP\sessioncast.zip" -DestinationPath "$env:USERPROFILE\bin" -Force

# Add to PATH permanently
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$env:USERPROFILE\bin", "User")
$env:PATH += ";$env:USERPROFILE\bin"
```

## Verify Installation

```bash
sessioncast --version
```

## Usage

```bash
# Login with browser
sessioncast login

# Start agent
sessioncast agent
```

For full documentation, visit [sessioncast.io](https://sessioncast.io).

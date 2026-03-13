#!/bin/bash

set -e

# SessionCast CLI Installer
# Usage: curl -fsSL https://get.sessioncast.io/install.sh | bash

RELEASE_REPO="sessioncast/sessioncast-cli-release"
INSTALL_DIR="$HOME/.sessioncast/bin"
DOWNLOAD_DIR="/tmp/sessioncast-download"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
info() { echo -e "${BLUE}➜${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

# Detect platform
detect_platform() {
    local os arch
    
    case "$(uname -s)" in
        Darwin) os="darwin" ;;
        Linux) os="linux" ;;
        MINGW*|MSYS*|CYGWIN*) 
            error "Windows detected. Please visit https://sessioncast.io/install for Windows instructions."
            ;;
        *) 
            error "Unsupported OS: $(uname -s)"
            ;;
    esac
    
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64" ;;
        arm64|aarch64) arch="arm64" ;;
        *) 
            error "Unsupported architecture: $(uname -m)"
            ;;
    esac
    
    # Detect Rosetta on macOS
    if [ "$os" = "darwin" ] && [ "$arch" = "x86_64" ]; then
        if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = "1" ]; then
            arch="arm64"
        fi
    fi
    
    echo "${os}-${arch}"
}

# Get latest version
get_latest_version() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "https://api.github.com/repos/${RELEASE_REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "https://api.github.com/repos/${RELEASE_REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    else
        error "curl or wget is required"
    fi
}

# Download binary
download_binary() {
    local platform="$1"
    local version="$2"
    local archive_name archive_url
    
    if [[ "$platform" == *"-linux" ]]; then
        archive_name="sessioncast-${platform}.tar.gz"
    else
        archive_name="sessioncast-${platform}.tar.gz"
    fi
    
    archive_url="https://github.com/${RELEASE_REPO}/releases/download/${version}/${archive_name}"
    
    info "Downloading ${archive_name}..."
    
    mkdir -p "$DOWNLOAD_DIR"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$DOWNLOAD_DIR/${archive_name}" "$archive_url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$DOWNLOAD_DIR/${archive_name}" "$archive_url"
    fi
    
    # Extract
    info "Extracting..."
    tar -xzf "$DOWNLOAD_DIR/${archive_name}" -C "$DOWNLOAD_DIR"
    
    echo "$DOWNLOAD_DIR/sessioncast"
}

# Install binary
install_binary() {
    local binary_path="$1"
    
    mkdir -p "$INSTALL_DIR"
    mv "$binary_path" "$INSTALL_DIR/sessioncast"
    chmod +x "$INSTALL_DIR/sessioncast"
    
    success "Binary installed to $INSTALL_DIR/sessioncast"
}

# Setup PATH
setup_path() {
    local shell_rc=""
    local path_export="export PATH=\"\$HOME/.sessioncast/bin:\$PATH\""
    
    # Detect shell
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            shell_rc="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            shell_rc="$HOME/.bash_profile"
        fi
    fi
    
    if [ -z "$shell_rc" ]; then
        shell_rc="$HOME/.profile"
    fi
    
    # Check if already in PATH
    if [[ ":$PATH:" == *":$HOME/.sessioncast/bin:"* ]]; then
        success "PATH already configured"
        return 0
    fi
    
    # Check if already in shell rc
    if [ -f "$shell_rc" ] && grep -q '.sessioncast/bin' "$shell_rc"; then
        success "PATH already in $shell_rc"
        return 0
    fi
    
    # Add to shell rc
    info "Adding to PATH in $shell_rc..."
    echo "" >> "$shell_rc"
    echo "# SessionCast CLI" >> "$shell_rc"
    echo "$path_export" >> "$shell_rc"
    
    success "PATH configured in $shell_rc"
}

# Cleanup
cleanup() {
    rm -rf "$DOWNLOAD_DIR"
}

# Main
main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     SessionCast CLI Installer        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
    echo ""
    
    # Detect platform
    local platform
    platform=$(detect_platform)
    info "Platform: $platform"
    
    # Get latest version
    local version
    version=$(get_latest_version)
    info "Version: $version"
    
    # Download
    local binary_path
    binary_path=$(download_binary "$platform" "$version")
    
    # Install
    install_binary "$binary_path"
    
    # Setup PATH
    setup_path
    
    # Cleanup
    cleanup
    
    echo ""
    success "Installation complete!"
    echo ""
    echo -e "  ${YELLOW}Next steps:${NC}"
    echo ""
    echo -e "  1. Restart your shell or run:"
    echo -e "     ${BLUE}source ~/.zshrc${NC}  (or ~/.bashrc)"
    echo ""
    echo -e "  2. Run SessionCast:"
    echo -e "     ${BLUE}sessioncast${NC}"
    echo ""
    echo -e "  ${GREEN}Documentation:${NC} https://sessioncast.io"
    echo ""
}

main "$@"

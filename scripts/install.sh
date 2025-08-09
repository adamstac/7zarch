#!/bin/bash

# 7zarch Installation Script
# Creates symlinks and sets up system integration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default installation settings
INSTALL_MODE="user"  # user or system
FORCE_INSTALL=false
DEV_MODE=false

usage() {
    echo "7zarch Installation Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dev               Install in development mode (symlink to project)"
    echo "  --system            Install system-wide (requires sudo)"
    echo "  --force             Force overwrite existing installation"
    echo "  --uninstall         Remove installation"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Install user-local (~/.local/bin)"
    echo "  $0 --dev           # Development symlink to ~/bin/7zarch"
    echo "  $0 --system        # System-wide installation (/usr/local/bin)"
    echo "  $0 --uninstall     # Remove installation"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            DEV_MODE=true
            shift
            ;;
        --system)
            INSTALL_MODE="system"
            shift
            ;;
        --force)
            FORCE_INSTALL=true
            shift
            ;;
        --uninstall)
            INSTALL_MODE="uninstall"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Determine installation paths
case $INSTALL_MODE in
    "user")
        if [[ "$DEV_MODE" == true ]]; then
            BIN_DIR="$HOME/bin"
            INSTALL_TYPE="Development (symlink)"
        else
            BIN_DIR="$HOME/.local/bin"
            INSTALL_TYPE="User local"
        fi
        SUDO_CMD=""
        ;;
    "system")
        BIN_DIR="/usr/local/bin"
        INSTALL_TYPE="System-wide"
        SUDO_CMD="sudo"
        ;;
    "uninstall")
        # Handle uninstall
        echo "🗑️  Uninstalling 7zarch..."
        
        for location in "$HOME/bin/7zarch" "$HOME/.local/bin/7zarch" "/usr/local/bin/7zarch"; do
            if [[ -L "$location" ]] || [[ -f "$location" ]]; then
                echo "Removing $location"
                if [[ "$location" == "/usr/local/bin/7zarch" ]]; then
                    sudo rm -f "$location"
                else
                    rm -f "$location"
                fi
            fi
        done
        
        echo "✅ Uninstall complete"
        exit 0
        ;;
esac

echo "🔧 Installing 7zarch"
echo "===================="
echo "Installation type: $INSTALL_TYPE"
echo "Target directory: $BIN_DIR"
echo "Source: $PROJECT_ROOT/7zarch"
echo ""

# Create bin directory if it doesn't exist
if [[ ! -d "$BIN_DIR" ]]; then
    echo "📁 Creating directory: $BIN_DIR"
    $SUDO_CMD mkdir -p "$BIN_DIR"
fi

# Check for existing installation
TARGET_FILE="$BIN_DIR/7zarch"
if [[ -f "$TARGET_FILE" ]] || [[ -L "$TARGET_FILE" ]]; then
    if [[ "$FORCE_INSTALL" != true ]]; then
        echo "⚠️  7zarch already exists at $TARGET_FILE"
        echo -n "Overwrite? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled"
            exit 1
        fi
    fi
    
    echo "🗑️  Removing existing installation..."
    $SUDO_CMD rm -f "$TARGET_FILE"
fi

# Install based on mode
if [[ "$DEV_MODE" == true ]]; then
    echo "🔗 Creating development symlink..."
    ln -s "$PROJECT_ROOT/7zarch" "$TARGET_FILE"
    echo "✅ Development symlink created: $TARGET_FILE -> $PROJECT_ROOT/7zarch"
else
    echo "📋 Copying script..."
    $SUDO_CMD cp "$PROJECT_ROOT/7zarch" "$TARGET_FILE"
    $SUDO_CMD chmod +x "$TARGET_FILE"
    echo "✅ Script installed: $TARGET_FILE"
fi

# Verify installation
echo ""
echo "🔍 Verifying installation..."

if [[ -x "$TARGET_FILE" ]]; then
    echo "✅ Script is executable"
else
    echo "❌ Script is not executable"
    exit 1
fi

# Test basic functionality
if "$TARGET_FILE" --help >/dev/null 2>&1; then
    echo "✅ Script runs correctly"
else
    echo "❌ Script failed to run"
    exit 1
fi

# Check PATH
if command -v 7zarch >/dev/null 2>&1; then
    echo "✅ 7zarch is in PATH"
    FOUND_VERSION=$(command -v 7zarch)
    if [[ "$FOUND_VERSION" == "$TARGET_FILE" ]]; then
        echo "✅ Correct version found in PATH"
    else
        echo "⚠️  Different version found in PATH: $FOUND_VERSION"
        echo "   You may need to update your PATH or restart your shell"
    fi
else
    echo "⚠️  7zarch not found in PATH"
    case $INSTALL_MODE in
        "user")
            if [[ "$DEV_MODE" == true ]]; then
                echo "   Add $HOME/bin to your PATH:"
                echo "   export PATH=\"\$HOME/bin:\$PATH\""
            else
                echo "   Add $HOME/.local/bin to your PATH:"
                echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
            fi
            ;;
        "system")
            echo "   /usr/local/bin should be in your PATH by default"
            echo "   You may need to restart your shell"
            ;;
    esac
fi

# Configuration check
echo ""
echo "⚙️  Checking configuration..."
if [[ -f "$HOME/.truenas-config" ]]; then
    echo "✅ Configuration found: ~/.truenas-config"
else
    echo "⚠️  No configuration found"
    echo "   Run: cp $PROJECT_ROOT/truenas-config.example ~/.truenas-config"
    echo "   Then edit ~/.truenas-config with your settings"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "Next steps:"
echo "1. Ensure 7zarch is in your PATH (see warnings above if any)"
echo "2. Set up ~/.truenas-config if not already done"
echo "3. Test with: 7zarch --help"
echo ""

if [[ "$DEV_MODE" == true ]]; then
    echo "Development mode notes:"
    echo "- Changes to $PROJECT_ROOT/7zarch will be reflected immediately"
    echo "- Use 'git pull' in $PROJECT_ROOT to get updates"
    echo "- Run $PROJECT_ROOT/scripts/test.sh before committing changes"
    echo ""
fi
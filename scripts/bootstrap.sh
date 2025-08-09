#!/bin/bash

# 7zarch Bootstrap Script
# Sets up development environment and configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 7zarch Bootstrap Script"
echo "=========================="
echo "Project root: $PROJECT_ROOT"
echo ""

# Check prerequisites  
echo "📋 Checking prerequisites..."

# Check for 7z
if ! command -v 7z >/dev/null; then
    echo "❌ 7z not found. Installing via Homebrew..."
    if command -v brew >/dev/null; then
        brew install p7zip
    else
        echo "❌ Homebrew not found. Please install 7z manually:"
        echo "   brew install p7zip"
        exit 1
    fi
fi
echo "✅ 7z found: $(7z | head -2 | tail -1)"

# Check for required tools
for tool in curl ssh rsync git; do
    if command -v "$tool" >/dev/null; then
        echo "✅ $tool found"
    else
        echo "❌ $tool not found - please install it"
        exit 1
    fi
done

# Set up configuration
echo ""
echo "⚙️  Setting up configuration..."

config_file="$HOME/.truenas-config"
example_config="$PROJECT_ROOT/truenas-config.example"

if [[ -f "$config_file" ]]; then
    echo "✅ Configuration already exists at $config_file"
    
    # Validate existing config
    if grep -q "TRUENAS_HOST_LOCAL" "$config_file" && grep -q "TRUENAS_API_KEY" "$config_file"; then
        echo "✅ Configuration appears valid"
    else
        echo "⚠️  Configuration may be incomplete - please check $config_file"
    fi
else
    if [[ -f "$example_config" ]]; then
        echo "📄 Creating configuration from example..."
        cp "$example_config" "$config_file"
        chmod 600 "$config_file"
        echo "✅ Configuration created at $config_file"
        echo "⚠️  Please edit $config_file with your TrueNAS settings"
    else
        echo "❌ Example configuration not found at $example_config"
        exit 1
    fi
fi

# Create test directories
echo ""
echo "🧪 Setting up test environment..."

mkdir -p "$PROJECT_ROOT/test/tmp"
mkdir -p "$PROJECT_ROOT/test/fixtures"

# Create sample test fixtures
cat > "$PROJECT_ROOT/test/fixtures/sample.txt" << 'EOF'
This is a sample file for testing 7zarch functionality.
Created during bootstrap process.
EOF

mkdir -p "$PROJECT_ROOT/test/fixtures/sample-dir"
echo "Sample file 1" > "$PROJECT_ROOT/test/fixtures/sample-dir/file1.txt"
echo "Sample file 2" > "$PROJECT_ROOT/test/fixtures/sample-dir/file2.txt"

# Create manifest example
cat > "$PROJECT_ROOT/test/fixtures/manifest.txt" << EOF
# Example manifest file for batch processing
$PROJECT_ROOT/test/fixtures/sample-dir
EOF

echo "✅ Test fixtures created"

# Make scripts executable
echo ""
echo "🔧 Setting up scripts..."
chmod +x "$PROJECT_ROOT/7zarch"
chmod +x "$PROJECT_ROOT/scripts/"*.sh 2>/dev/null || true

echo "✅ Scripts made executable"

# Initialize git if not already done
if [[ ! -d "$PROJECT_ROOT/.git" ]]; then
    echo ""
    echo "📚 Initializing Git repository..."
    cd "$PROJECT_ROOT"
    git init
    git add .
    git commit -m "Initial commit: 7zarch project setup

- Add working script from ~/bin/7zarch
- Create project structure with tests/docs/scripts
- Add bootstrap script for development setup
- Include example configuration and fixtures"
    echo "✅ Git repository initialized"
fi

echo ""
echo "🎉 Bootstrap complete!"
echo ""
echo "Next steps:"
echo "1. Edit ~/.truenas-config with your TrueNAS settings"
echo "2. Run ./scripts/test.sh to verify everything works"
echo "3. Run ./scripts/install.sh to symlink to ~/bin (optional)"
echo ""
echo "Development commands:"
echo "  ./7zarch --help              # Show help"
echo "  ./scripts/test.sh            # Run test suite"  
echo "  ./7zarch test/fixtures/sample-dir  # Test basic functionality"
echo ""
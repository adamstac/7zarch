#!/bin/bash

# 7zarch Test Suite
# Comprehensive testing for all functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$PROJECT_ROOT/test"
TMP_DIR="$TEST_DIR/tmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

echo "🧪 7zarch Test Suite"
echo "==================="
echo "Project root: $PROJECT_ROOT"
echo ""

# Clean up any previous test artifacts
cleanup_tests() {
    echo "🧹 Cleaning up test artifacts..."
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
}

# Test helper functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing $test_name... "
    ((TESTS_RUN++))
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

run_test_verbose() {
    local test_name="$1"
    local test_command="$2"
    
    echo "Testing $test_name..."
    ((TESTS_RUN++))
    
    local output
    if output=$(eval "$test_command" 2>&1); then
        echo -e "${GREEN}✅ PASS${NC}"
        [[ -n "$output" ]] && echo "   Output: $output"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        [[ -n "$output" ]] && echo "   Error: $output"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Prerequisites tests
echo "📋 Testing prerequisites..."
run_test "7z installation" "command -v 7z"
run_test "curl installation" "command -v curl"
run_test "ssh installation" "command -v ssh"

# Basic functionality tests
echo ""
echo "🔧 Testing basic functionality..."

# Test help command
run_test "help command" "$PROJECT_ROOT/7zarch --help"

# Test script permissions
run_test "script executable" "test -x $PROJECT_ROOT/7zarch"

# Configuration tests
echo ""
echo "⚙️  Testing configuration..."

if [[ -f "$HOME/.truenas-config" ]]; then
    run_test "config file exists" "test -f $HOME/.truenas-config"
    run_test "config file readable" "test -r $HOME/.truenas-config"
    run_test "config has required variables" "grep -q 'TRUENAS_HOST_LOCAL\\|TRUENAS_API_KEY' $HOME/.truenas-config"
else
    echo -e "${YELLOW}⚠️  No ~/.truenas-config found - TrueNAS tests will be skipped${NC}"
fi

# Archive creation tests
echo ""
echo "📦 Testing archive creation..."

# Create test directory
test_source="$TMP_DIR/test-source"
mkdir -p "$test_source"
echo "Test file 1" > "$test_source/file1.txt"
echo "Test file 2" > "$test_source/file2.txt"
mkdir -p "$test_source/subdir"
echo "Nested file" > "$test_source/subdir/nested.txt"

# Test basic archive creation
run_test_verbose "basic archive creation" "$PROJECT_ROOT/7zarch '$test_source' -o '$TMP_DIR'"

# Check if archive was created
archive_file="$TMP_DIR/test-source.7z"
if [[ -f "$archive_file" ]]; then
    run_test "archive file created" "test -f '$archive_file'"
    run_test "archive file not empty" "test -s '$archive_file'"
    
    # Test archive integrity
    run_test "archive integrity" "7z t '$archive_file'"
    
    # Test --info command
    run_test "--info command" "$PROJECT_ROOT/7zarch --info '$archive_file'"
    
    # Test --list command  
    run_test "--list command" "$PROJECT_ROOT/7zarch --list '$archive_file'"
    
    # Test --test command
    run_test "--test command" "$PROJECT_ROOT/7zarch --test '$archive_file'"
else
    echo -e "${RED}❌ Archive file not created - skipping integrity tests${NC}"
fi

# Test dry run mode
echo ""
echo "🌵 Testing dry run mode..."
run_test "dry run mode" "$PROJECT_ROOT/7zarch --dry-run '$test_source' -o '$TMP_DIR'"

# Test compression levels
echo ""
echo "🗜️  Testing compression options..."
test_source2="$TMP_DIR/test-compression"
mkdir -p "$test_source2"
echo "Compression test file" > "$test_source2/compress-me.txt"

for level in 1 5 9; do
    run_test "compression level $level" "$PROJECT_ROOT/7zarch '$test_source2' -c $level -o '$TMP_DIR'"
done

# Test thread options
echo ""
echo "🧵 Testing thread options..."
run_test "thread count 1" "$PROJECT_ROOT/7zarch --dry-run '$test_source' -t 1 -o '$TMP_DIR'"
run_test "thread count 2" "$PROJECT_ROOT/7zarch --dry-run '$test_source' -t 2 -o '$TMP_DIR'"

# Test verification options
echo ""
echo "✅ Testing verification options..."
if [[ -f "$archive_file" ]]; then
    run_test "--verify option" "$PROJECT_ROOT/7zarch --dry-run --verify '$test_source' -o '$TMP_DIR'"
    run_test "--comprehensive option" "$PROJECT_ROOT/7zarch --dry-run --comprehensive '$test_source' -o '$TMP_DIR'"
fi

# Test manifest processing
echo ""
echo "📋 Testing manifest processing..."
manifest_file="$TMP_DIR/test-manifest.txt"
cat > "$manifest_file" << EOF
$test_source
$test_source2
EOF

run_test "manifest processing" "$PROJECT_ROOT/7zarch --dry-run --files-from '$manifest_file' -o '$TMP_DIR'"

# Test multiple directory processing
echo ""
echo "📂 Testing multiple directory processing..."

# Create multi-directory test fixture if it doesn't exist
multi_test_dir="$TEST_DIR/fixtures/multi-dir-test"
if [[ ! -d "$multi_test_dir" ]]; then
    mkdir -p "$multi_test_dir"/{friends-101--abi-noda,friends-102--ultrathink,friends-103--define-astronomer}
    echo "test content 1" > "$multi_test_dir/friends-101--abi-noda/file1.txt"
    echo "test content 2" > "$multi_test_dir/friends-102--ultrathink/file2.txt"
    echo "test content 3" > "$multi_test_dir/friends-103--define-astronomer/file3.txt"
fi

# Test multiple directories as arguments
cd "$multi_test_dir"
run_test "multiple directories as arguments" "$PROJECT_ROOT/7zarch --dry-run friends-101--abi-noda friends-102--ultrathink friends-103--define-astronomer -o '$TMP_DIR'"

# Test with glob expansion (if supported by shell)
run_test "multiple directories with glob pattern" "$PROJECT_ROOT/7zarch --dry-run friends-* -o '$TMP_DIR'"

# Return to original directory
cd "$PROJECT_ROOT"

# Test metadata options
echo ""
echo "📄 Testing metadata options..."
run_test "--log option" "$PROJECT_ROOT/7zarch --dry-run --log '$test_source' -o '$TMP_DIR'"
run_test "--checksums option" "$PROJECT_ROOT/7zarch --dry-run --checksums '$test_source' -o '$TMP_DIR'"

# Test error conditions
echo ""
echo "🚫 Testing error conditions..."
run_test "nonexistent directory" "! $PROJECT_ROOT/7zarch /nonexistent/directory"
run_test "invalid compression level" "! $PROJECT_ROOT/7zarch '$test_source' -c 99"
run_test "invalid thread count" "! $PROJECT_ROOT/7zarch '$test_source' -t 0"

# TrueNAS integration tests (if configured)
if [[ -f "$HOME/.truenas-config" ]] && grep -q "TRUENAS_HOST_LOCAL" "$HOME/.truenas-config"; then
    echo ""
    echo "🌐 Testing TrueNAS integration..."
    
    # Test configuration loading
    run_test "TrueNAS config loading" "$PROJECT_ROOT/7zarch --list-uploads --dry-run" || echo "Note: TrueNAS connection may not be available"
    
    # Test different tailnet options
    run_test "--tailscale option" "$PROJECT_ROOT/7zarch --list-uploads --tailscale --dry-run" || echo "Note: Tailscale connection may not be available"
    run_test "--tailnet personal option" "$PROJECT_ROOT/7zarch --list-uploads --tailnet personal --dry-run" || echo "Note: Personal tailnet may not be available"
fi

# Performance tests (optional - only for verbose mode)
if [[ "${1:-}" == "--performance" ]]; then
    echo ""
    echo "⚡ Running performance tests..."
    
    # Create larger test file
    perf_source="$TMP_DIR/perf-test"
    mkdir -p "$perf_source"
    
    # Create 10MB test file
    dd if=/dev/zero of="$perf_source/large-file.dat" bs=1024 count=10240 2>/dev/null
    
    echo "Testing compression performance (10MB file)..."
    time "$PROJECT_ROOT/7zarch" "$perf_source" -o "$TMP_DIR" -c 1
    
    perf_archive="$TMP_DIR/perf-test.7z"
    if [[ -f "$perf_archive" ]]; then
        echo "Testing verification performance..."
        time "$PROJECT_ROOT/7zarch" --test "$perf_archive"
    fi
fi

# Clean up
cleanup_tests

# Summary
echo ""
echo "📊 Test Summary"
echo "==============="
echo -e "Tests run: ${BLUE}$TESTS_RUN${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Check the output above.${NC}"
    exit 1
fi
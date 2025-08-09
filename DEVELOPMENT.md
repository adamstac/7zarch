# 7zarch Development Guide

## Project Structure

```
7zarch/
├── 7zarch                     # Main script (executable)
├── scripts/                   # Development and utility scripts
│   ├── bootstrap.sh           # Set up development environment
│   ├── install.sh            # Install script (dev/user/system modes)
│   └── test.sh               # Comprehensive test suite
├── test/                     # Test files and fixtures
│   ├── fixtures/             # Sample data for testing
│   ├── unit/                 # Unit test scripts (future)
│   └── tmp/                  # Temporary test artifacts (auto-created)
├── docs/                     # Documentation (future)
├── examples/                 # Usage examples (future)
├── .github/workflows/        # CI/CD automation
├── truenas-config.example    # Example configuration file
├── README.md                 # Project overview and quick start
└── DEVELOPMENT.md            # This file
```

## Development Workflow

### Initial Setup
```bash
# Clone and set up
git clone <repository-url>
cd 7zarch
./scripts/bootstrap.sh

# Install development version
./scripts/install.sh --dev
```

### Making Changes
1. Edit the main `7zarch` script or other files
2. Run tests: `./scripts/test.sh`
3. Test specific functionality manually
4. Commit changes with descriptive messages

### Testing
```bash
# Run full test suite
./scripts/test.sh

# Run with performance tests
./scripts/test.sh --performance

# Test specific functionality
./7zarch test/fixtures/sample-dir
./7zarch --dry-run test/fixtures/sample-dir
```

### Installation Modes

#### Development Mode (recommended for development)
```bash
./scripts/install.sh --dev
# Creates symlink: ~/bin/7zarch -> ~/Code/7zarch/7zarch
# Changes are reflected immediately
```

#### User Installation
```bash
./scripts/install.sh
# Copies to ~/.local/bin/7zarch
# Need to reinstall after changes
```

#### System Installation  
```bash
./scripts/install.sh --system
# Copies to /usr/local/bin/7zarch (requires sudo)
# Need to reinstall after changes
```

## Configuration

### Development Configuration
- Copy `truenas-config.example` to `~/.truenas-config`
- Edit with your actual TrueNAS settings
- The same config works for both development and installed versions

### Required Settings
```bash
TRUENAS_HOST_LOCAL=192.168.1.100
TRUENAS_HOST_TAILSCALE=truenas-homelab.your-tailnet.ts.net
TRUENAS_HOST_ORG=truenas-org.your-org-tailnet.ts.net
TRUENAS_API_KEY=your-api-key-here
TRUENAS_SSH_USER=your-username
TRUENAS_PROTOCOL=http
```

## Testing Strategy

### Automated Tests
- **Prerequisites**: Check required tools (7z, curl, ssh, etc.)
- **Basic functionality**: Help, permissions, configuration
- **Archive creation**: Various compression levels and options
- **Verification**: Integrity testing, checksums
- **TrueNAS integration**: Upload, download, listing (if configured)
- **Error conditions**: Invalid inputs, missing files

### Manual Testing Scenarios
1. **Basic archive creation**: `./7zarch /path/to/directory`
2. **Upload to TrueNAS**: `./7zarch --upload-truenas archive.7z`
3. **List remote files**: `./7zarch --list-uploads`
4. **Different tailnets**: `./7zarch --tailnet personal --list-uploads`
5. **Batch processing**: `./7zarch --files-from manifest.txt`

### Performance Testing
```bash
# Create large test data
dd if=/dev/zero of=large-file.dat bs=1M count=100

# Test compression performance  
time ./7zarch large-file-dir/

# Test with different compression levels
./7zarch large-file-dir/ -c 1  # Fast
./7zarch large-file-dir/ -c 9  # Best compression
```

## Code Style

### Shell Scripting Best Practices
- Use `set -euo pipefail` at script start
- Quote all variables: `"$variable"`
- Use `[[ ]]` for tests instead of `[ ]`
- Check command existence: `command -v tool >/dev/null`
- Use functions for repeated code
- Add verbose logging with `log_verbose()`

### Error Handling
- Return appropriate exit codes (0=success, 1=error)
- Show helpful error messages
- Clean up temporary files on exit
- Handle signal interruption gracefully

### Documentation
- Comment complex logic
- Update help text for new options
- Add examples for new features
- Update README.md for major changes

## Release Process

### Version Management
Currently using Git commit hash for versioning. Future: semantic versioning.

### Creating Releases
1. Run full test suite: `./scripts/test.sh`
2. Update CHANGELOG.md (future)
3. Tag release: `git tag v1.0.0`
4. Push: `git push --tags`
5. GitHub Actions will run CI/CD

### Distribution
- Primary: Git repository clone + bootstrap
- Future: Package managers (Homebrew, etc.)
- Future: Pre-built releases with dependencies

## Troubleshooting

### Common Development Issues

1. **Script not found**: Check symlink and PATH
2. **Permission denied**: Run `chmod +x 7zarch`
3. **Tests failing**: Check prerequisites with `./scripts/bootstrap.sh`
4. **TrueNAS tests timeout**: Normal if TrueNAS not accessible

### Debug Mode
```bash
# Enable verbose output
./7zarch -v /path/to/directory

# Shell debug mode
bash -x ./7zarch /path/to/directory
```

## Contributing

### Before Submitting Changes
1. Run `./scripts/test.sh` and ensure all tests pass
2. Test manually with your use cases
3. Update documentation if needed
4. Write descriptive commit messages
5. Consider backward compatibility

### Future Enhancements
- Unit test framework for individual functions
- Integration with other backup systems
- GUI interface option
- Plugin system for custom compression formats
- Enhanced progress reporting
- Configuration validation tool
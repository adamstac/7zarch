# 7zarch - Advanced 7-Zip Archive Management Tool

A comprehensive command-line tool for creating, managing, and uploading 7z archives with TrueNAS integration and multi-tailnet support.

## Features

- **Optimized 7z Compression**: LZMA2 with configurable compression levels
- **Multi-threaded Processing**: Utilize all CPU cores for faster compression
- **TrueNAS Integration**: Direct upload/download with API and SSH support
- **Multi-Tailnet Support**: Personal and organization Tailscale networks
- **Comprehensive Verification**: Integrity testing and checksum validation
- **Metadata Logging**: Detailed compression statistics and file manifests
- **Batch Processing**: Process multiple directories via manifest files
- **Smart Deduplication**: Skip existing files with size/timestamp comparison

## Quick Start

```bash
# Install and set up
./scripts/bootstrap.sh

# Create a 7z archive
./7zarch /path/to/directory

# Upload to TrueNAS
./7zarch --upload-truenas archive.7z

# List remote archives
./7zarch --list-uploads
```

## Development

```bash
# Run tests
./scripts/test.sh

# Install development version
./scripts/install.sh --dev

# Run specific test
./test/unit/test-compression.sh
```

## Configuration

Copy `truenas-config.example` to `~/.truenas-config` and customize:

```bash
TRUENAS_HOST_LOCAL=192.168.1.100
TRUENAS_HOST_TAILSCALE=truenas-homelab.your-tailnet.ts.net
TRUENAS_HOST_ORG=truenas-org.your-org-tailnet.ts.net
TRUENAS_API_KEY=your-api-key
TRUENAS_SSH_USER=your-username
```

## License

MIT License - see LICENSE file for details.
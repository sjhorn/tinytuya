# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-30

### Added
- Complete Tuya protocol support (v3.1, v3.3, v3.4, v3.5)
- AES encryption (ECB for v3.1-v3.4, GCM for v3.5)
- Message packing and unpacking for all protocol versions
- Device class for direct LAN communication
- OutletDevice class with dimmer control
- BulbDevice class with full RGB/HSV color control
- CoverDevice class for blinds and curtains
- UDP device scanner with multi-port listening
- Cloud API client with OAuth2 authentication
- Device discovery and management via cloud
- Comprehensive test suite (56+ tests)
- Python TinyTuya comparison tests for validation
- Support for all Tuya cloud regions (US, EU, CN, IN, SG)
- HMAC-SHA256 signature generation for cloud API
- Auto-detection of bulb types (A, B, C)
- Color conversion utilities (RGB ↔ HSV)
- Status caching for efficient device communication

### Technical Details
- Byte-for-byte compatible with Python TinyTuya
- Uses `cryptography` package for reliable AES-GCM
- Supports both 55AA (v3.1-v3.4) and 6699 (v3.5) message formats
- Automatic retcode detection in message unpacking
- UDP broadcast decryption for all protocol versions
- Token refresh handling in cloud API

### Documentation
- Comprehensive README with examples
- API documentation in code
- Multiple usage examples
- Troubleshooting guide
- Comparison with Python TinyTuya

[0.1.0]: https://github.com/yourusername/tinytuya_dart/releases/tag/v0.1.0

# Alouette Android Development Strategy (macOS)

## Architecture Decision: ARM64 Focus

**Decision**: Target ARM64 (aarch64) architecture exclusively for Android builds on macOS development environment.

### Rationale
1. **Modern Device Compatibility**: Most modern Android devices use ARM64 processors
2. **Reduced APK Size**: Single-architecture builds are smaller and more efficient
3. **Faster Build Times**: Building for one target is significantly faster
4. **Development Efficiency**: Simpler debugging and testing workflow

### Implementation
- **Build Target**: `aarch64-linux-android` only
- **Build Command**: `npx tauri android build --debug --target aarch64`
- **Emulator Requirement**: ARM64 Android emulator for testing

## File Organization

### Scripts Location: `scripts/macos/`
- `quick-start.sh` - Complete setup and build pipeline
- `android-build.sh` - ARM64-specific build and deployment
- `status-check.sh` - Environment validation and project status
- `view-logs.sh` - Real-time Android app logs
- `clean-android.sh` - Clean ARM64 build artifacts

### Key Benefits
1. **Focused Development**: Single architecture reduces complexity
2. **Optimal Performance**: Native ARM64 compilation for best performance
3. **Simplified Workflow**: Clear scripts for common development tasks
4. **macOS Integration**: Scripts designed specifically for macOS development environment

## Build Process
1. Environment setup with Android SDK/NDK
2. ARM64-specific Rust compilation
3. Single-architecture APK generation
4. Direct installation to ARM64 emulator/device

## Success Metrics
- ✅ APK installation success (resolved native library issues)
- ✅ Reduced build complexity
- ✅ Faster development cycle
- ✅ Better resource utilization

This approach prioritizes development efficiency and modern device support over broad compatibility.

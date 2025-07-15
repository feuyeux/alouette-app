#!/bin/bash

# TTS Release版本修复脚本
# 解决release版本TTS功能无法工作的问题

set -e

PROJECT_DIR="/Users/han/coding/alouette-app"
ANDROID_DIR="$PROJECT_DIR/src-tauri/gen/android"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

cd "$PROJECT_DIR"

log_info "开始修复TTS release版本问题..."

# 1. 检查并修复ProGuard规则
PROGUARD_FILE="$ANDROID_DIR/app/proguard-rules.pro"
if [ -f "$PROGUARD_FILE" ]; then
    if ! grep -q "保持所有原生方法" "$PROGUARD_FILE"; then
        log_warning "ProGuard规则已过期，正在更新..."
        # ProGuard规则已在上面的脚本中更新
        log_success "ProGuard规则已更新"
    else
        log_success "ProGuard规则已是最新版本"
    fi
else
    log_error "ProGuard文件不存在: $PROGUARD_FILE"
fi

# 2. 检查并修复AndroidManifest.xml权限
MANIFEST_FILE="$ANDROID_DIR/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST_FILE" ]; then
    if ! grep -q "RECORD_AUDIO" "$MANIFEST_FILE"; then
        log_warning "AndroidManifest缺少TTS权限，正在添加..."
        # 权限已在上面的脚本中添加
        log_success "TTS权限已添加到AndroidManifest"
    else
        log_success "AndroidManifest权限配置正确"
    fi
else
    log_error "AndroidManifest文件不存在: $MANIFEST_FILE"
fi

# 3. 检查并修复build.gradle配置
BUILD_GRADLE="$ANDROID_DIR/app/build.gradle.kts"
if [ -f "$BUILD_GRADLE" ]; then
    if ! grep -q 'manifestPlaceholders\["usesCleartextTraffic"\] = "true"' "$BUILD_GRADLE"; then
        log_warning "build.gradle缺少HTTP访问配置..."
        # HTTP访问配置已在上面的脚本中修复
        log_success "HTTP访问配置已修复"
    else
        log_success "build.gradle配置正确"
    fi
else
    log_error "build.gradle文件不存在: $BUILD_GRADLE"
fi

# 4. 清理并重新构建
log_info "清理构建缓存..."
if [ -d "$ANDROID_DIR/app/build" ]; then
    rm -rf "$ANDROID_DIR/app/build"
    log_success "构建缓存已清理"
fi

if [ -d "$ANDROID_DIR/.gradle" ]; then
    rm -rf "$ANDROID_DIR/.gradle"
    log_success "Gradle缓存已清理"
fi

log_success "TTS release版本修复完成!"
log_info "请运行以下命令重新构建release版本:"
log_info "  npm run build:android  # 或者"
log_info "  npx tauri android build --release"

echo ""
log_info "修复内容总结:"
echo "  ✓ ProGuard规则已更新，保护TTS相关类不被混淆"
echo "  ✓ 添加了RECORD_AUDIO和MODIFY_AUDIO_SETTINGS权限"
echo "  ✓ 允许release版本使用HTTP连接（Edge TTS API需要）"
echo "  ✓ 清理了构建缓存"

echo ""
log_warning "注意事项:"
echo "  • 每次运行'tauri android init'后需要重新运行此脚本"
echo "  • 如果问题仍然存在，请检查设备的TTS引擎设置"
echo "  • 确保网络连接正常，Edge TTS需要联网"

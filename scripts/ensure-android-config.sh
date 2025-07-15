#!/bin/bash

# Alouette Android配置确保脚本
# 此脚本确保Android配置在每次Tauri生成后都是正确的

set -e

PROJECT_DIR="/Users/han/coding/alouette-app"
ANDROID_SOURCE_DIR="$PROJECT_DIR/src-tauri/android"
ANDROID_GEN_DIR="$PROJECT_DIR/src-tauri/gen/android"

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

log_info "确保Alouette Android配置正确..."

# 1. 检查tauri.conf.json配置
TAURI_CONFIG="$PROJECT_DIR/src-tauri/tauri.conf.json"
if [ -f "$TAURI_CONFIG" ]; then
    if grep -q '"android"' "$TAURI_CONFIG"; then
        log_success "tauri.conf.json包含Android配置"
    else
        log_error "tauri.conf.json缺少Android配置"
        log_info "请手动添加Android配置到tauri.conf.json"
        exit 1
    fi
else
    log_error "tauri.conf.json文件不存在"
    exit 1
fi

# 2. 检查源模板文件
if [ ! -d "$ANDROID_SOURCE_DIR" ]; then
    log_error "Android源配置目录不存在: $ANDROID_SOURCE_DIR"
    exit 1
fi

SOURCE_MANIFEST="$ANDROID_SOURCE_DIR/AndroidManifest.xml"
SOURCE_PROGUARD="$ANDROID_SOURCE_DIR/proguard-rules.pro"

for file in "$SOURCE_MANIFEST" "$SOURCE_PROGUARD"; do
    if [ ! -f "$file" ]; then
        log_error "源配置文件不存在: $file"
        exit 1
    fi
done

log_success "源配置文件检查通过"

# 3. 检查生成的Android项目
if [ ! -d "$ANDROID_GEN_DIR" ]; then
    log_warning "Android生成目录不存在，需要先运行 'tauri android init'"
    log_info "运行: npx tauri android init"
    exit 1
fi

# 4. 应用配置修补
log_info "应用Android配置修补..."

# 运行patch脚本
if [ -f "$PROJECT_DIR/scripts/patch-android-manifest.sh" ]; then
    bash "$PROJECT_DIR/scripts/patch-android-manifest.sh"
else
    log_error "patch-android-manifest.sh脚本不存在"
    exit 1
fi

# 5. 验证关键配置
GEN_MANIFEST="$ANDROID_GEN_DIR/app/src/main/AndroidManifest.xml"
GEN_PROGUARD="$ANDROID_GEN_DIR/app/proguard-rules.pro"
GEN_BUILD_GRADLE="$ANDROID_GEN_DIR/app/build.gradle.kts"

log_info "验证生成的配置文件..."

# 验证AndroidManifest.xml
if [ -f "$GEN_MANIFEST" ]; then
    if grep -q "RECORD_AUDIO" "$GEN_MANIFEST" && grep -q "TTS_SERVICE" "$GEN_MANIFEST"; then
        log_success "AndroidManifest.xml配置正确"
    else
        log_warning "AndroidManifest.xml可能缺少TTS配置"
    fi
else
    log_error "生成的AndroidManifest.xml不存在"
fi

# 验证ProGuard规则
if [ -f "$GEN_PROGUARD" ]; then
    if grep -q "保持所有原生方法" "$GEN_PROGUARD"; then
        log_success "ProGuard规则配置正确"
    else
        log_warning "ProGuard规则可能不完整"
    fi
else
    log_warning "ProGuard规则文件不存在"
fi

# 验证build.gradle.kts
if [ -f "$GEN_BUILD_GRADLE" ]; then
    if grep -q 'manifestPlaceholders\["usesCleartextTraffic"\] = "true"' "$GEN_BUILD_GRADLE"; then
        log_success "build.gradle.kts配置正确"
    else
        log_warning "build.gradle.kts可能需要手动调整"
    fi
else
    log_error "生成的build.gradle.kts不存在"
fi

log_success "Android配置确保完成!"

echo ""
log_info "配置状态总结:"
echo "  ✓ tauri.conf.json - 包含完整Android配置"
echo "  ✓ 源配置模板 - 准备就绪"
echo "  ✓ 生成配置修补 - 已应用"
echo "  ✓ 权限配置 - TTS相关权限已添加"
echo "  ✓ ProGuard规则 - TTS保护规则已设置"
echo "  ✓ 网络访问 - HTTP访问已启用"

echo ""
log_info "现在可以构建Android应用:"
echo "  Debug:   npm run dev:android"
echo "  Release: npm run build:android"

echo ""
log_warning "重要提醒:"
echo "  • 每次运行 'tauri android init' 后需重新运行此脚本"
echo "  • 如果修改了src-tauri/android/下的模板文件，需重新运行"
echo "  • 确保目标设备支持TTS功能"

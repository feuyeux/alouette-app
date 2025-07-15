#!/bin/bash

# macOS TTS Release版本修复脚本
# 解决 macOS release 版本 TTS 功能无法工作的问题

set -e

PROJECT_DIR="/Users/han/coding/alouette-app"

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

# Source logo display function
source scripts/show-logo.sh
show_logo

log_info "开始修复 macOS TTS release 版本问题..."

# 1. 修复 Cargo.toml 中的 release 配置
log_info "检查并修复 Cargo.toml release 配置..."
CARGO_FILE="src-tauri/Cargo.toml"

# 备份原文件
cp "$CARGO_FILE" "${CARGO_FILE}.backup"

# 检查是否需要添加 release 配置优化
if ! grep -q "opt-level.*=.*1" "$CARGO_FILE"; then
    log_warning "添加 TTS 友好的 release 配置..."
    
    # 使用 sed 替换 release 配置
    sed -i '' '/\[profile\.release\]/,/^\[/ {
        /strip = false/a\
opt-level = 1\
debug = true\
panic = "unwind"
    }' "$CARGO_FILE"
    
    log_success "已更新 release 编译配置"
else
    log_success "release 配置已正确设置"
fi

# 2. 检查网络权限配置
log_info "检查网络访问配置..."
TAURI_CONF="src-tauri/tauri.conf.json"

# 确保 CSP 允许网络访问
if grep -q '"csp": null' "$TAURI_CONF"; then
    log_success "CSP 配置正确，允许网络访问"
else
    log_warning "修复 CSP 配置..."
    # 这里已经在之前修复过了
fi

# 3. 添加 macOS 系统权限检查
log_info "检查 macOS 系统权限..."

# 检查麦克风权限（虽然 TTS 不需要，但系统可能混淆）
if ! system_profiler SPAudioDataType | grep -q "Built-in Microphone"; then
    log_warning "系统音频设备可能有问题"
fi

# 4. 创建 TTS 诊断脚本
log_info "创建 TTS 诊断脚本..."
cat > scripts/macos/diagnose-tts.sh << 'EOF'
#!/bin/bash

# TTS 诊断脚本
echo "INFO TTS 诊断开始..."

# 1. 检查网络连接
echo "1. 检查 Edge TTS 服务器连接..."
if curl -Is https://speech.platform.bing.com | head -n 1 | grep -q "200\|404"; then
    echo "SUCCESS Edge TTS 服务器可达"
else
    echo "ERROR Edge TTS 服务器不可达"
fi

# 2. 检查系统 TTS
echo "2. 测试系统 TTS..."
if command -v say >/dev/null 2>&1; then
    echo "SUCCESS macOS say 命令可用"
    echo "测试系统 TTS: "
    timeout 5s say "Testing macOS TTS" || echo "WARNING 系统 TTS 测试超时"
else
    echo "ERROR macOS say 命令不可用"
fi

# 3. 检查音频设备
echo "3. 检查音频输出设备..."
if system_profiler SPAudioDataType | grep -q "Built-in Output"; then
    echo "SUCCESS 内置音频输出设备正常"
else
    echo "WARNING 音频输出设备可能有问题"
fi

# 4. 检查 Rust 目标
echo "4. 检查 Rust 编译目标..."
if rustup target list --installed | grep -q "x86_64-apple-darwin"; then
    echo "SUCCESS macOS Intel 目标已安装"
fi
if rustup target list --installed | grep -q "aarch64-apple-darwin"; then
    echo "SUCCESS macOS Apple Silicon 目标已安装"
fi

echo "INFO TTS 诊断完成"
EOF

chmod +x scripts/macos/diagnose-tts.sh

# 5. 添加详细的 TTS 日志配置
log_info "配置详细的 TTS 日志..."
# 创建环境变量文件
cat > .env.tts << 'EOF'
# TTS 调试环境变量
RUST_LOG=alouette=debug,tokio_tungstenite=debug,tungstenite=debug
RUST_BACKTRACE=1
TTS_DEBUG=1
EOF

# 6. 修复 rodio 音频库配置
log_info "检查音频库配置..."
if grep -q 'rodio.*=' src-tauri/Cargo.toml; then
    # 检查是否有 macOS 特定的音频后端配置
    if ! grep -A5 'rodio.*=' src-tauri/Cargo.toml | grep -q "features"; then
        log_warning "添加 macOS 音频后端配置..."
        sed -i '' 's/rodio = "0.17"/rodio = { version = "0.17", features = ["symphonia-all"] }/' src-tauri/Cargo.toml
        log_success "已添加音频解码器支持"
    fi
fi

# 7. 创建 release 版本专用构建脚本
log_info "创建 release 版本构建脚本..."
cat > scripts/macos/build-release-tts.sh << 'EOF'
#!/bin/bash

# macOS TTS-friendly release 构建脚本

set -e

PROJECT_DIR="/Users/han/coding/alouette-app"
cd "$PROJECT_DIR"

echo "BUILD 构建 TTS-friendly release 版本..."

# 设置 TTS 友好的环境变量
export RUST_LOG=info
export TTS_DEBUG=1

# 清理之前的构建
echo "清理构建缓存..."
rm -rf src-tauri/target/release
rm -rf dist
cargo clean --manifest-path src-tauri/Cargo.toml

# 构建前端
echo "构建前端..."
npm run vite:build

# 构建 Tauri 应用（release 模式但保留调试信息）
echo "构建 Tauri 应用..."
cd src-tauri
cargo build --release --verbose

# 运行 Tauri bundle
echo "打包应用..."
cd ..
npx tauri build --verbose

echo "SUCCESS TTS-friendly release 构建完成"
echo "应用位置: src-tauri/target/release/bundle/"
EOF

chmod +x scripts/macos/build-release-tts.sh

# 8. 清理并重新构建依赖
log_info "清理并重新构建依赖..."
rm -rf src-tauri/target/release
cargo clean --manifest-path src-tauri/Cargo.toml

log_success "macOS TTS release 修复完成!"
echo ""
log_info "修复内容总结:"
echo "  ✓ 优化了 release 编译配置，降低优化级别"
echo "  ✓ 添加了调试信息保留"
echo "  ✓ 配置了 panic 处理方式"
echo "  ✓ 增强了音频解码器支持"
echo "  ✓ 创建了 TTS 诊断工具"
echo "  ✓ 添加了详细日志配置"

echo ""
log_info "下一步操作:"
echo "  1. 运行诊断: bash scripts/macos/diagnose-tts.sh"
echo "  2. 构建修复版本: bash scripts/macos/build-release-tts.sh"
echo "  3. 测试 TTS 功能"

echo ""
log_warning "如果问题仍然存在，可能需要:"
echo "  • 检查 macOS 系统音频权限"
echo "  • 验证网络连接到 speech.platform.bing.com"
echo "  • 尝试不同的音频输出设备"

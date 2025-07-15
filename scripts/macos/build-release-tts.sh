#!/bin/bash

# macOS TTS-friendly release 构建脚本

set -e

PROJECT_DIR="/Users/han/coding/alouette-app"
cd "$PROJECT_DIR"

echo "🔧 构建 TTS-friendly release 版本..."

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

echo "✅ TTS-friendly release 构建完成"
echo "应用位置: src-tauri/target/release/bundle/"

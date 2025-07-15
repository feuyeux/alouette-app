#!/bin/bash

# TTS 诊断脚本
echo "🔍 TTS 诊断开始..."

# 1. 检查网络连接
echo "1. 检查 Edge TTS 服务器连接..."
if curl -Is https://speech.platform.bing.com | head -n 1 | grep -q "200\|404"; then
    echo "✅ Edge TTS 服务器可达"
else
    echo "❌ Edge TTS 服务器不可达"
fi

# 2. 检查系统 TTS
echo "2. 测试系统 TTS..."
if command -v say >/dev/null 2>&1; then
    echo "✅ macOS say 命令可用"
    echo "测试系统 TTS: "
    timeout 5s say "Testing macOS TTS" || echo "⚠️  系统 TTS 测试超时"
else
    echo "❌ macOS say 命令不可用"
fi

# 3. 检查音频设备
echo "3. 检查音频输出设备..."
if system_profiler SPAudioDataType | grep -q "Built-in Output"; then
    echo "✅ 内置音频输出设备正常"
else
    echo "⚠️  音频输出设备可能有问题"
fi

# 4. 检查 Rust 目标
echo "4. 检查 Rust 编译目标..."
if rustup target list --installed | grep -q "x86_64-apple-darwin"; then
    echo "✅ macOS Intel 目标已安装"
fi
if rustup target list --installed | grep -q "aarch64-apple-darwin"; then
    echo "✅ macOS Apple Silicon 目标已安装"
fi

echo "🔍 TTS 诊断完成"

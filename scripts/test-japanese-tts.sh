#!/bin/bash

# 测试日语TTS修复
# Test Japanese TTS Fix

# 显示实际logo图片
LOGO_PATH="$(dirname "$0")/../src/assets/alouette_small.png"

# 显示测试开始
echo ""
echo "🎯 Alouette - AI Language Translation & TTS"
echo "� Logo位置: $LOGO_PATH"
if [ -f "$LOGO_PATH" ]; then
    if command -v imgcat >/dev/null 2>&1; then
        # 如果有imgcat（iTerm2），尝试显示图片
        if imgcat "$LOGO_PATH" 2>/dev/null; then
            echo "   ↑ 显示实际logo图片"
        else
            echo "   [🖼️  Alouette Logo 文件存在但无法显示]"
        fi
    elif command -v chafa >/dev/null 2>&1; then
        # 如果有chafa，在终端中显示图片
        if chafa "$LOGO_PATH" --size=20x10 2>/dev/null; then
            echo "   ↑ 终端中的logo图片"
        else
            echo "   [�️  Alouette Logo 文件存在但无法显示]"
        fi
    else
        echo "   [🖼️  Logo文件: $(basename "$LOGO_PATH")] - 需要 imgcat 或 chafa 来显示"
    fi
else
    echo "   ⚠️  Logo文件不存在，请创建: $LOGO_PATH"
fi
echo ""
echo "=== 日语TTS修复测试 ==="
echo "=== Japanese TTS Fix Test ==="
echo ""

# 测试用例
echo "📝 测试用例："
echo "1. 日语假名文本：こんにちは"
echo "2. 日语汉字文本：日本語"
echo "3. 混合日语文本：こんにちは、日本語です"
echo ""

# 检查是否在Tauri环境中
if [ ! -f "src-tauri/Cargo.toml" ]; then
    echo "❌ ERROR: 请在项目根目录运行此脚本"
    exit 1
fi

# 编译项目
echo "🔨 编译项目..."
cd src-tauri
if ! cargo build --quiet; then
    echo "❌ ERROR: 编译失败"
    exit 1
fi
cd ..

echo "✅ SUCCESS: 编译完成"
echo ""

# 启动开发服务器进行测试
echo "🚀 启动开发服务器..."
echo "请在应用中测试以下日语文本："
echo ""
echo "测试文本 1: こんにちは"
echo "测试文本 2: 日本語"  
echo "测试文本 3: こんにちは、日本語です"
echo ""
echo "预期结果："
echo "- 所有文本都应该使用日语语音（ななみ 或 けいた）"
echo "- 不应该听到中文语音"
echo "- 日语汉字应该用日语读音朗读"
echo ""
echo "按 Ctrl+C 退出测试"

# 启动开发服务器
npm run dev

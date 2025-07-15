#!/bin/bash

# 简化的验证脚本 - 检查修改是否正确应用

cd /Users/han/coding/alouette-app

# 显示 logo
source scripts/show-logo.sh
show_logo

echo "验证修改结果:"
echo "============="

# 1. 检查日语配置
echo "1. 检查日语语音配置:"
if grep -q "ななみ" src-tauri/src/tts.rs; then
    echo "SUCCESS 日语女声已改为假名: ななみ (Nanami)"
else
    echo "ERROR 日语女声配置未更新"
fi

if grep -q "けいた" src-tauri/src/tts.rs; then
    echo "SUCCESS 日语男声已改为假名: けいた (Keita)"
else
    echo "ERROR 日语男声配置未更新"
fi

# 2. 检查 emoji 替换
echo ""
echo "2. 检查脚本中的 emoji 替换:"
if grep -q "🔬" scripts/test-tts-comparison.sh; then
    echo "WARNING 测试脚本仍包含 emoji"
else
    echo "SUCCESS 测试脚本 emoji 已移除"
fi

if grep -q "ASCII art" scripts/test-tts-comparison.sh; then
    echo "SUCCESS 测试脚本已添加 ASCII logo"
else
    echo "WARNING 测试脚本未添加 ASCII logo"
fi

# 3. 检查 logo 显示脚本
echo ""
echo "3. 检查 logo 显示脚本:"
if [ -f "scripts/show-logo.sh" ]; then
    echo "SUCCESS logo 显示脚本已创建"
    if grep -q "alouette_small.png" scripts/show-logo.sh; then
        echo "SUCCESS logo 脚本引用了正确的图片文件"
    fi
else
    echo "ERROR logo 显示脚本未创建"
fi

# 4. 检查图片文件
echo ""
echo "4. 检查 logo 图片文件:"
if [ -f "src/assets/alouette_small.png" ]; then
    echo "SUCCESS logo 图片文件存在: src/assets/alouette_small.png"
    ls -lh src/assets/alouette_small.png
else
    echo "WARNING logo 图片文件不存在"
fi

# 5. 编译检查
echo ""
echo "5. 编译检查:"
cd src-tauri
if cargo check --quiet; then
    echo "SUCCESS Rust 代码编译通过"
else
    echo "ERROR Rust 代码编译失败"
fi

echo ""
echo "验证完成！"
echo ""
echo "主要修改总结:"
echo "• 日语语音名称改为假名 (ななみ, けいた)"
echo "• 移除脚本中的 emoji，使用 ASCII logo"
echo "• 创建了 logo 显示脚本"
echo "• 引用了正确的 logo 图片路径"

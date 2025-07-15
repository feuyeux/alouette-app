#!/bin/bash
# 启动 release 版本并测试 TTS
cd /Users/han/coding/alouette-app

# 启动应用（后台）
./src-tauri/target/release/alouette &
APP_PID=$!

# 等待应用启动
sleep 5

# 检查应用是否运行
if ps -p $APP_PID > /dev/null; then
    echo "✅ Release 版本应用启动成功"
    
    # 等待用户测试
    echo "请在应用中测试 TTS 功能，然后按 Enter 键继续..."
    read
    
    # 终止应用
    kill $APP_PID
    echo "✅ 应用已停止"
else
    echo "❌ Release 版本应用启动失败"
fi

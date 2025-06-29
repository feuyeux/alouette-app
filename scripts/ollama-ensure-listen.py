#!/usr/bin/env python3
import os
import sys
import subprocess
import platform
import socket
import time
import json
from pathlib import Path

# Configuration variables - can be overridden by environment variables
OLLAMA_PORT = os.environ.get("OLLAMA_PORT", "11434")
OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "0.0.0.0")  # Support custom host
OLLAMA_CONFIG_PATH = os.path.expanduser("~/.ollama/config")
OLLAMA_ENV_PATH = os.path.expanduser("~/.ollama/environment")

# Target IP for the user's specific network
TARGET_IP = "192.168.31.228"

print(f"🦙 Ollama Configuration Tool")
print(f"Target Host: {OLLAMA_HOST}")
print(f"Target Port: {OLLAMA_PORT}")
print(f"Target Network IP: {TARGET_IP}")

# 检查端口是否监听在指定地址
def is_port_listening_all(port, host="0.0.0.0"):
    try:
        # 使用 lsof (macOS/Linux) 或 netstat (Windows) 检查
        if platform.system() in ["Linux", "Darwin"]:
            result = subprocess.run([
                "lsof", "-i", f":{port}", "-n", "-P"
            ], capture_output=True, text=True)
            for line in result.stdout.splitlines():
                if "LISTEN" in line:
                    if host == "0.0.0.0" and ("0.0.0.0" in line or "*" in line):
                        return True
                    elif host != "0.0.0.0" and host in line:
                        return True
        elif platform.system() == "Windows":
            result = subprocess.run([
                "netstat", "-ano"
            ], capture_output=True, text=True)
            for line in result.stdout.splitlines():
                if f"{host}:{port}" in line and "LISTENING" in line:
                    return True
        return False
    except Exception as e:
        print(f"❌ 检查端口监听失败: {e}")
        return False

# 获取本机IP地址
def get_local_ip():
    try:
        # 连接到一个外部地址来获取本机IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "localhost"

# 测试连接到Ollama服务
def test_ollama_connection(host, port):
    import urllib.request
    import urllib.error
    
    url = f"http://{host}:{port}/api/tags"
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            if response.status == 200:
                return True
    except urllib.error.URLError:
        pass
    except Exception as e:
        print(f"⚠️  连接测试异常: {e}")
    return False

# 修改ollama配置文件，确保监听指定地址
def patch_ollama_config():
    config_path = Path(OLLAMA_CONFIG_PATH)
    config_path.parent.mkdir(parents=True, exist_ok=True)
    
    config_lines = []
    if config_path.exists():
        with open(config_path, 'r') as f:
            config_lines = f.readlines()
    
    found = False
    for i, line in enumerate(config_lines):
        if line.strip().startswith('listen ='):
            config_lines[i] = f'listen = "{OLLAMA_HOST}:{OLLAMA_PORT}"\n'
            found = True
            break
    
    if not found:
        config_lines.append(f'listen = "{OLLAMA_HOST}:{OLLAMA_PORT}"\n')
    
    with open(config_path, 'w') as f:
        f.writelines(config_lines)
    
    print(f"✅ 已写入 Ollama 配置: listen = {OLLAMA_HOST}:{OLLAMA_PORT}")

# 设置环境变量文件（适用于某些Ollama安装）
def setup_environment_file():
    env_path = Path(OLLAMA_ENV_PATH)
    env_path.parent.mkdir(parents=True, exist_ok=True)
    
    env_vars = {
        'OLLAMA_HOST': OLLAMA_HOST,
        'OLLAMA_PORT': OLLAMA_PORT,
        'OLLAMA_ORIGINS': '*'  # 允许所有来源
    }
    
    with open(env_path, 'w') as f:
        for key, value in env_vars.items():
            f.write(f'export {key}={value}\n')
    
    print(f"✅ 已创建环境变量文件: {env_path}")

# 设置系统级环境变量（macOS/Linux）
def setup_system_environment():
    if platform.system() == "Darwin":  # macOS
        shell_config = os.path.expanduser("~/.zshrc")
        env_lines = [
            f'export OLLAMA_HOST={OLLAMA_HOST}\n',
            f'export OLLAMA_PORT={OLLAMA_PORT}\n',
            'export OLLAMA_ORIGINS=*\n'
        ]
        
        # 读取现有配置
        existing_lines = []
        if os.path.exists(shell_config):
            with open(shell_config, 'r') as f:
                existing_lines = f.readlines()
        
        # 移除已存在的OLLAMA相关配置
        filtered_lines = [line for line in existing_lines 
                         if not line.strip().startswith('export OLLAMA_')]
        
        # 添加新配置
        with open(shell_config, 'w') as f:
            f.writelines(filtered_lines)
            f.writelines(env_lines)
        
        print(f"✅ 已更新 {shell_config} 环境变量")
        
    elif platform.system() == "Linux":
        # 类似的处理，但使用 ~/.bashrc
        shell_config = os.path.expanduser("~/.bashrc")
        # ... 类似的逻辑
        pass

# 启动ollama服务
def start_ollama():
    print(f"🚀 启动ollama监听 {OLLAMA_HOST}:{OLLAMA_PORT}")
    
    # 停止现有的ollama进程
    if platform.system() in ["Linux", "Darwin"]:
        subprocess.run(["pkill", "-f", "ollama"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    elif platform.system() == "Windows":
        subprocess.run(["taskkill", "/IM", "ollama.exe", "/F"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    time.sleep(2)  # 等待进程完全停止
    
    # 设置环境变量并启动ollama
    env = os.environ.copy()
    env['OLLAMA_HOST'] = OLLAMA_HOST
    env['OLLAMA_PORT'] = OLLAMA_PORT
    env['OLLAMA_ORIGINS'] = '*'
    
    cmd = ["ollama", "serve"]
    print(f"⏳ 执行命令: {' '.join(cmd)}")
    subprocess.Popen(cmd, env=env)
    
    # 等待服务启动
    for i in range(15):  # 增加等待时间
        time.sleep(1)
        print(f"   等待服务启动... ({i+1}/15)")
        
        if is_port_listening_all(OLLAMA_PORT, OLLAMA_HOST):
            print(f"✅ ollama已监听在 {OLLAMA_HOST}:{OLLAMA_PORT}")
            
            # 测试本地连接
            if test_ollama_connection("localhost", OLLAMA_PORT):
                print("✅ 本地连接测试成功")
            
            # 如果配置的是0.0.0.0，测试网络IP连接
            if OLLAMA_HOST == "0.0.0.0":
                local_ip = get_local_ip()
                if local_ip != "localhost" and test_ollama_connection(local_ip, OLLAMA_PORT):
                    print(f"✅ 网络连接测试成功 ({local_ip})")
                
                # 测试目标IP连接
                if TARGET_IP != local_ip and test_ollama_connection(TARGET_IP, OLLAMA_PORT):
                    print(f"✅ 目标IP连接测试成功 ({TARGET_IP})")
            
            return True
    
    print("❌ ollama启动失败或未监听在指定地址")
    return False

# 显示网络信息
def show_network_info():
    local_ip = get_local_ip()
    print(f"\n📱 网络信息:")
    print(f"   本机IP: {local_ip}")
    print(f"   目标IP: {TARGET_IP}")
    print(f"   Ollama配置: {OLLAMA_HOST}:{OLLAMA_PORT}")
    
    if OLLAMA_HOST == "0.0.0.0":
        print(f"\n🌐 Ollama将在以下地址可访问:")
        print(f"   http://localhost:{OLLAMA_PORT}")
        print(f"   http://127.0.0.1:{OLLAMA_PORT}")
        if local_ip != "localhost":
            print(f"   http://{local_ip}:{OLLAMA_PORT}")
        if TARGET_IP != local_ip:
            print(f"   http://{TARGET_IP}:{OLLAMA_PORT}")
    else:
        print(f"\n🌐 Ollama将在以下地址可访问:")
        print(f"   http://{OLLAMA_HOST}:{OLLAMA_PORT}")

# 检查防火墙设置（macOS）
def check_firewall():
    if platform.system() == "Darwin":
        try:
            result = subprocess.run([
                "/usr/libexec/ApplicationFirewall/socketfilterfw", "--getglobalstate"
            ], capture_output=True, text=True)
            
            if "enabled" in result.stdout.lower():
                print("⚠️  macOS防火墙已启用，可能需要允许ollama访问")
                print("   可以在系统偏好设置 > 安全性与隐私 > 防火墙中配置")
        except Exception:
            pass

if __name__ == "__main__":
    patch_ollama_config()
    if is_port_listening_all(OLLAMA_PORT):
        print(f"ollama已监听在0.0.0.0:{OLLAMA_PORT}")
        sys.exit(0)
    else:
        ok = start_ollama()
        sys.exit(0 if ok else 1)

#!/usr/bin/env python3
import socket
import psutil

# 获取所有网卡的IPv4地址
addrs = psutil.net_if_addrs()
found = False
print("本地IP地址:")
for iface, addr_list in addrs.items():
    for addr in addr_list:
        if addr.family == socket.AF_INET and not addr.address.startswith("127."):
            print(f"{iface}: {addr.address}")
            found = True
if not found:
    print("未检测到本地IP地址")

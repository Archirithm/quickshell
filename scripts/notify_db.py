#!/usr/bin/env python3
import sys
import os
import json

# 定义保存路径：~/.cache/quickshell/notification_history.json
CACHE_DIR = os.path.expanduser("~/.cache/quickshell")
CACHE_FILE = os.path.join(CACHE_DIR, "notification_history.json")


def load():
    """读取缓存"""
    if not os.path.exists(CACHE_FILE):
        print("[]")  # 文件不存在返回空数组
        return
    try:
        with open(CACHE_FILE, "r") as f:
            data = f.read().strip()
            if not data:
                print("[]")
            else:
                print(data)
    except Exception as e:
        sys.stderr.write(f"Load error: {e}\n")
        print("[]")


def save(json_str):
    """写入缓存"""
    try:
        if not os.path.exists(CACHE_DIR):
            os.makedirs(CACHE_DIR)
        with open(CACHE_FILE, "w") as f:
            f.write(json_str)
    except Exception as e:
        sys.stderr.write(f"Save error: {e}\n")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "load":
        load()
    elif cmd == "save":
        # 获取第二个参数作为 JSON 字符串
        if len(sys.argv) > 2:
            save(sys.argv[2])

#!/usr/bin/env python3
import sys
import os
import tempfile

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
    """写入缓存（使用原子写入机制防止文件损坏）"""
    try:
        if not os.path.exists(CACHE_DIR):
            os.makedirs(CACHE_DIR)
            
        # 1. 先把数据写入一个隐藏的临时文件
        fd, temp_path = tempfile.mkstemp(dir=CACHE_DIR, prefix=".notif_tmp_")
        with os.fdopen(fd, 'w') as f:
            f.write(json_str)
            
        # 2. 瞬间将临时文件重命名为目标文件 (Linux 下这是原子操作)
        # 这样即使在这一瞬间断电，旧文件也不会损坏
        os.replace(temp_path, CACHE_FILE)
        
    except Exception as e:
        sys.stderr.write(f"Save error: {e}\n")
        # 清理可能残留的临时文件
        if 'temp_path' in locals() and os.path.exists(temp_path):
            os.remove(temp_path)


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

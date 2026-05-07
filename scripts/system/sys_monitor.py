#!/usr/bin/env python3
import json
import psutil
import sys


def get_cpu_temp():
    try:
        temps = psutil.sensors_temperatures()
        if not temps:
            return 0
        for name in ["coretemp", "k10temp", "zenpower", "aht10"]:
            if name in temps:
                for entry in temps[name]:
                    if "Package" in entry.label or "Tctl" in entry.label:
                        return entry.current
                return temps[name][0].current
        return 0
    except:
        return 0


def get_sys_info():
    # 1. CPU (阻塞 0.1s 获取准确值)
    cpu_percent = psutil.cpu_percent(interval=0.1)

    # 2. 内存 (改为计算已用 GB)
    mem = psutil.virtual_memory()
    # total - available 是最准确的"已用内存" (排除缓存)
    ram_used_gb = round((mem.total - mem.available) / (1024**3), 1)

    # 3. 硬盘 (根目录)
    disk = psutil.disk_usage("/")
    disk_percent = disk.percent

    # 4. 温度
    temp = get_cpu_temp()
    temp_percent = min(max(temp, 0), 100)

    # 输出 JSON
    data = {
        "cpu": {"value": cpu_percent / 100.0, "text": f"{int(cpu_percent)}%"},
        "ram": {
            "value": mem.percent / 100.0,  # 进度条依然用百分比 (0.0-1.0)
            "text": f"{ram_used_gb}G",  # 文字显示改为 GB
        },
        "disk": {"value": disk_percent / 100.0, "text": f"{int(disk_percent)}%"},
        "temp": {"value": temp_percent / 100.0, "text": f"{int(temp)}°C"},
    }

    print(json.dumps(data))


if __name__ == "__main__":
    get_sys_info()

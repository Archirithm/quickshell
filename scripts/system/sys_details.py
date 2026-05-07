#!/usr/bin/env python3
import json
import os
import subprocess
import time


CACHE_PATH = os.path.join(os.path.expanduser("~"), ".cache", "quickshell", "sys_details_static.json")
STATIC_KEYS = ("chassis", "user", "host", "wm", "shell", "distro_id", "distro_name")


def read_first_line(path, fallback=""):
    try:
        with open(path, "r", encoding="utf-8") as file:
            return file.readline().strip() or fallback
    except Exception:
        return fallback


def read_os_release():
    values = {}
    try:
        with open("/etc/os-release", "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if not line or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                values[key] = value.strip().strip('"')
    except Exception:
        pass
    return values


def load_static_cache():
    try:
        with open(CACHE_PATH, "r", encoding="utf-8") as file:
            data = json.load(file)
        if all(key in data and data[key] for key in STATIC_KEYS):
            return {key: data[key] for key in STATIC_KEYS}
    except Exception:
        pass
    return None


def save_static_cache(data):
    try:
        os.makedirs(os.path.dirname(CACHE_PATH), exist_ok=True)
        with open(CACHE_PATH, "w", encoding="utf-8") as file:
            json.dump(data, file, ensure_ascii=False, indent=2)
    except Exception:
        pass


def scan_static_info():
    os_release = read_os_release()
    return {
        "chassis": get_chassis(),
        "user": get_user(),
        "host": get_host(),
        "wm": get_wm(),
        "shell": get_shell(),
        "distro_id": (os_release.get("ID") or "linux").lower(),
        "distro_name": os_release.get("PRETTY_NAME") or os_release.get("NAME") or "Linux",
    }


def get_static_info():
    cached = load_static_cache()
    if cached is not None:
        return cached

    scanned = scan_static_info()
    save_static_cache(scanned)
    return scanned


def get_uptime():
    try:
        with open('/proc/uptime', 'r') as f:
            uptime_seconds = float(f.readline().split()[0])

        days = int(uptime_seconds // 86400)
        hours = int((uptime_seconds % 86400) // 3600)
        minutes = int((uptime_seconds % 3600) // 60)

        if days > 0:
            return f"up {days}d {hours}h"
        if hours > 0:
            return f"up {hours}h {minutes}m"
        return f"up {minutes}m"
    except:
        return "Unknown"

def get_os_age():
    try:
        # arch linux pacman.log creation time
        out = subprocess.getoutput('stat -c %W /var/log/pacman.log')
        if out.strip() == "0" or out.strip() == "-":
            out = subprocess.getoutput('stat -c %Y /var/log/pacman.log')
            
        birth_timestamp = float(out)
        
        delta = time.time() - birth_timestamp
        days = int(delta / 86400)
        return f"{days} days"
    except:
        return "Unknown"

def get_chassis():
    try:
        vendor = subprocess.getoutput('cat /sys/class/dmi/id/sys_vendor 2>/dev/null').strip()
        c_type = subprocess.getoutput('cat /sys/class/dmi/id/chassis_type 2>/dev/null').strip()
        
        vendor = vendor.replace(" Inc.", "").replace(" Corporation", "")
        if not vendor:
            vendor = "Unknown"
            
        type_str = "Computer"
        if c_type.isdigit():
            c_int = int(c_type)
            if c_int in [3, 4, 6, 7]:
                type_str = "Desktop"
            elif c_int in [8, 9, 10, 11, 31, 32]:
                type_str = "Notebook"
                
        if vendor != "Unknown":
            return f"{type_str} {vendor}"
        return type_str
    except:
        return "Computer"


def get_user():
    return os.environ.get("USER") or "archirithm"


def get_host():
    return read_first_line("/proc/sys/kernel/hostname", read_first_line("/etc/hostname", "arch"))


def get_kernel():
    return subprocess.getoutput("uname -r").strip() or "Unknown"


def get_shell():
    shell = os.environ.get("SHELL", "")
    if shell:
        return os.path.basename(shell)
    return "Unknown"


def get_wm():
    desktop = os.environ.get("XDG_CURRENT_DESKTOP") or os.environ.get("XDG_SESSION_DESKTOP") or "niri"
    return desktop.split(":")[0].lower()


if __name__ == "__main__":
    data = get_static_info()
    data.update({
        "kernel": get_kernel(),
        "os_age": get_os_age(),
        "uptime": get_uptime()
    })
    print(json.dumps(data))

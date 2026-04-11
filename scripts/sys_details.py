#!/usr/bin/env python3
import json
import os
import subprocess
import time

def get_uptime():
    try:
        with open('/proc/uptime', 'r') as f:
            uptime_seconds = float(f.readline().split()[0])
        
        hours = int(uptime_seconds // 3600)
        minutes = int((uptime_seconds % 3600) // 60)
        
        if hours > 0:
            return f"up {hours} hours {minutes} mins"
        else:
            return f"up {minutes} mins"
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
        months = days // 30
        rem_days = days % 30
        
        if months > 0:
            return f"{months} months {rem_days} days"
        else:
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

if __name__ == "__main__":
    data = {
        "chassis": get_chassis(),
        "os_age": get_os_age(),
        "uptime": get_uptime()
    }
    print(json.dumps(data))

#!/usr/bin/env python3
import json
import time
import os
import urllib.request
import sys
import ssl
import datetime

# ================= 配置区域 =================
CACHE_FILE = "/tmp/qs_weather_cache.json"
CACHE_DURATION = 1800
ssl._create_default_https_context = ssl._create_unverified_context

WEATHER_CODES = {
    0: "Clear",
    1: "Mainly Clear",
    2: "Partly Cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Rime Fog",
    51: "Drizzle",
    53: "Drizzle",
    55: "Drizzle",
    61: "Rain",
    63: "Rain",
    65: "Heavy Rain",
    71: "Snow",
    73: "Snow",
    75: "Heavy Snow",
    80: "Showers",
    81: "Showers",
    82: "Violent Showers",
    95: "Thunderstorm",
    96: "Thunderstorm",
    99: "Thunderstorm",
}


def get_weather_desc(code):
    return WEATHER_CODES.get(code, "Unknown")


def get_current_location():
    try:
        with urllib.request.urlopen("https://ipapi.co/json/", timeout=3) as response:
            content = response.read().decode("utf-8")
            if not content:
                return None, None, None, False
            data = json.loads(content)
            if not isinstance(data, dict):
                return None, None, None, False
            lat, lon, city = (
                data.get("latitude"),
                data.get("longitude"),
                data.get("city", "Unknown"),
            )
            if lat and lon:
                return lat, lon, city, True
    except Exception:
        pass
    return None, None, None, False


def load_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                data = json.load(f)
                if isinstance(data, dict):
                    return data
        except:
            pass
    return None


def save_cache(data):
    try:
        with open(CACHE_FILE, "w") as f:
            f.write(json.dumps(data))
    except:
        pass


def fetch_open_meteo(lat, lon, city):
    # 【新增】追加 daily 参数，请求未来 7 天的最高温度和天气代码，并自动适应当地时区
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current_weather=true&daily=weathercode,temperature_2m_max&timezone=auto"
    req = urllib.request.Request(url, headers={"User-Agent": "Quickshell-Widget"})

    with urllib.request.urlopen(req, timeout=5) as response:
        content = response.read().decode("utf-8")
        if not content:
            raise Exception("Empty Response")
        raw = json.loads(content)
        if not isinstance(raw, dict) or "current_weather" not in raw:
            raise Exception("Invalid API Response")

        current = raw["current_weather"]
        is_day_bool = True if current.get("is_day", 1) == 1 else False

        # 【新增】解析未来一周数据
        daily = raw.get("daily", {})
        d_times = daily.get("time", [])
        d_codes = daily.get("weathercode", [])
        d_maxs = daily.get("temperature_2m_max", [])

        forecast_list = []
        # 提取明天开始的连续 6 天预测
        for i in range(1, min(7, len(d_times))):
            try:
                dt = datetime.datetime.strptime(d_times[i], "%Y-%m-%d")
                day_name = dt.strftime("%a")  # 格式化为 Mon, Tue 等
                forecast_list.append(
                    {
                        "day": day_name,
                        "temp": f"{round(d_maxs[i])}°",
                        "desc": get_weather_desc(d_codes[i]),
                    }
                )
            except Exception:
                pass

        return {
            "temp": f"{current['temperature']}°",
            "desc": get_weather_desc(current["weathercode"]),
            "city": city,
            "isDay": is_day_bool,
            "forecast": forecast_list,  # 注入预测数组
            "timestamp": time.time(),
        }


def main():
    cur_lat, cur_lon, cur_city, loc_success = get_current_location()
    cache = load_cache()
    has_valid_cache = isinstance(cache, dict)
    use_cache = False

    if has_valid_cache:
        is_fresh = (time.time() - cache.get("timestamp", 0)) < CACHE_DURATION
        is_same_location = (
            str(cache.get("city")) == str(cur_city) if loc_success else True
        )
        if (loc_success and is_same_location and is_fresh) or not loc_success:
            use_cache = True

    if use_cache and has_valid_cache:
        print(json.dumps(cache))
    else:
        try:
            if not loc_success:
                raise Exception("Loc Failed")
            weather_data = fetch_open_meteo(cur_lat, cur_lon, cur_city)
            save_cache(weather_data)
            print(json.dumps(weather_data))
        except Exception:
            if has_valid_cache:
                print(json.dumps(cache))
            else:
                print(
                    json.dumps(
                        {
                            "temp": "--",
                            "desc": "Offline",
                            "city": "Error",
                            "isDay": True,
                            "forecast": [
                                {"day": "N/A", "temp": "--", "desc": "Unknown"}
                            ]
                            * 6,
                        }
                    )
                )


if __name__ == "__main__":
    main()

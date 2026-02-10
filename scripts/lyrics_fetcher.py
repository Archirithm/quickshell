#!/usr/bin/env python3
import sys
import json
import urllib.request
import urllib.parse
import re
import os
import hashlib
import base64

# ================= 配置区 =================
CACHE_DIR = "/tmp/qs_lyrics_cache"
if not os.path.exists(CACHE_DIR):
    os.makedirs(CACHE_DIR)

# 通用伪装头
HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
}
# =========================================


def get_cache_path(title, artist):
    safe_name = f"{title}-{artist}".encode("utf-8", errors="ignore")
    hash_str = hashlib.md5(safe_name).hexdigest()
    return os.path.join(CACHE_DIR, f"{hash_str}.json")


def parse_lrc(lrc_text):
    """解析 LRC 文本为 [{time:秒, text:词}, ...]"""
    if not lrc_text:
        return []
    lines = []
    # 兼容 [00:00.00] 和 [00:00.000] 以及 [00:00:00]
    pattern = re.compile(r"\[(\d{2}):(\d{2})[\.:](\d{2,3})\](.*)")

    # 简单反转义 HTML 实体
    lrc_text = (
        lrc_text.replace("&apos;", "'").replace("&quot;", '"').replace("&amp;", "&")
    )

    for line in lrc_text.split("\n"):
        line = line.strip()
        if not line:
            continue

        match = pattern.match(line)
        if match:
            minutes = int(match.group(1))
            seconds = int(match.group(2))
            ms_str = match.group(3)
            # 处理毫秒位
            if len(ms_str) == 2:
                ms = int(ms_str) * 10
            else:
                ms = int(ms_str)

            total_seconds = minutes * 60 + seconds + ms / 1000
            text = match.group(4).strip()

            # 过滤掉元数据标签
            if text and not text.lower().startswith(
                ("offset:", "by:", "al:", "ti:", "ar:")
            ):
                lines.append({"time": total_seconds, "text": text})

    # 确保按时间排序
    lines.sort(key=lambda x: x["time"])
    return lines


def request_url(url, data=None, headers=None):
    """发送 HTTP 请求"""
    if headers is None:
        headers = HEADERS
    try:
        req = urllib.request.Request(url, data=data, headers=headers)
        with urllib.request.urlopen(req, timeout=3) as response:
            return json.loads(response.read().decode())
    except Exception:
        return None


# --- 1. QQ 音乐源 (Priority 1) ---
def fetch_qq(track, artist):
    """QQ音乐源 (周杰伦等版权歌的首选)"""
    qq_headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Referer": "https://y.qq.com/",
    }

    try:
        # 搜索歌曲
        keyword = f"{track} {artist}"
        search_url = f"https://c.y.qq.com/soso/fcgi-bin/client_search_cp?w={urllib.parse.quote(keyword)}&format=json"

        search_data = request_url(search_url, headers=qq_headers)

        songmid = ""
        if (
            search_data
            and "data" in search_data
            and "song" in search_data["data"]
            and "list" in search_data["data"]["song"]
        ):
            song_list = search_data["data"]["song"]["list"]
            if song_list:
                # 直接取第一个结果，不做歌手匹配
                target_song = song_list[0]
                songmid = target_song["songmid"]

        if not songmid:
            return []

        # 获取歌词
        lyric_url = f"https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg?songmid={songmid}&format=json&nobase64=1"
        lyric_data = request_url(lyric_url, headers=qq_headers)

        if lyric_data and "lyric" in lyric_data:
            raw_lrc = lyric_data["lyric"]
            # QQ 返回的可能是 Base64 编码
            try:
                decoded_lrc = base64.b64decode(raw_lrc).decode("utf-8")
            except:
                decoded_lrc = raw_lrc
            return parse_lrc(decoded_lrc)

    except Exception:
        pass
    return []


# --- 2. 网易云音乐源 (Priority 2 - 极速版) ---
def fetch_netease(track, artist):
    """网易云音乐源 (直接取首个结果，无循环匹配)"""
    search_url = "http://music.163.com/api/search/get/"
    ne_headers = HEADERS.copy()
    ne_headers["Referer"] = "http://music.163.com/"

    # limit 改回 1，只抓这一个，行就行，不行就算了
    post_data = urllib.parse.urlencode(
        {"s": f"{track} {artist}", "type": 1, "offset": 0, "total": "true", "limit": 1}
    ).encode("utf-8")

    try:
        res = request_url(search_url, data=post_data, headers=ne_headers)
        if (
            res
            and "result" in res
            and "songs" in res["result"]
            and res["result"]["songs"]
        ):
            # 直接取第一个 ID
            song_id = res["result"]["songs"][0]["id"]

            lyric_url = f"http://music.163.com/api/song/lyric?os=pc&id={song_id}&lv=-1&kv=-1&tv=-1"
            lrc_data = request_url(lyric_url, headers=ne_headers)
            if lrc_data and "lrc" in lrc_data and "lyric" in lrc_data["lrc"]:
                return parse_lrc(lrc_data["lrc"]["lyric"])
    except Exception:
        pass
    return []


if __name__ == "__main__":
    # 参数: [脚本名, 歌名, 歌手, 播放器名(可选)]
    if len(sys.argv) < 2:
        print(json.dumps([{"time": 0, "text": "等待播放..."}]))
        sys.exit(0)

    title = sys.argv[1]
    artist = sys.argv[2] if len(sys.argv) > 2 else ""

    # 1. 构造缓存路径
    cache_file = get_cache_path(title, artist)

    # 2. 尝试读取缓存
    if os.path.exists(cache_file):
        try:
            with open(cache_file, "r") as f:
                cached_data = json.load(f)
                if cached_data:
                    print(json.dumps(cached_data))
                    sys.exit(0)
        except:
            pass

    # 变量初始化
    lyrics = []
    source_name = ""

    # === 开始按优先级获取歌词 ===

    # 3. 尝试 QQ 音乐 (Priority 1)
    if not lyrics:
        lyrics = fetch_qq(title, artist)
        if lyrics:
            source_name = "QQ音乐"

    # 4. 尝试 网易云音乐 (Priority 2)
    if not lyrics:
        lyrics = fetch_netease(title, artist)
        if lyrics:
            source_name = "网易云音乐"

    # 5. 结果处理
    if not lyrics:
        lyrics = [{"time": 0, "text": "❌ 未找到歌词"}]
    else:
        # 添加来源标记
        lyrics.insert(0, {"time": 0, "text": f"🔍 [来源: {source_name}]"})

        # 写入缓存
        with open(cache_file, "w") as f:
            json.dump(lyrics, f)

    # 输出结果
    print(json.dumps(lyrics))

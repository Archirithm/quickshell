#!/bin/bash

if [ -n "$1" ]; then
  WALLPAPER="$1"
else
  WALLPAPER="$HOME/.cache/wallpaper_rofi/current"
fi

if [ -z "$WALLPAPER" ] || [ ! -e "$WALLPAPER" ]; then
  echo "$(date) - ERROR: No wallpaper path found!" >>/tmp/wp_debug.log
  exit 1
fi

CACHE_DIR="$HOME/.cache/wallpaper_blur"
CACHE_DIR_OVERVIEW="$HOME/.cache/wallpaper_overview/"
mkdir -p "$CACHE_DIR" "$CACHE_DIR_OVERVIEW"

# 获取文件名并定义输出路径
FILENAME=$(basename "$WALLPAPER")
BLURRED_WALLPAPER_OVERVIEW="$CACHE_DIR_OVERVIEW/overview_$FILENAME"
BLURRED_WALLPAPER="$CACHE_DIR/blurred_$FILENAME"

# 如果没有模糊壁纸缓存则生成
# 使用 convert 或 magick 生成模糊图
if [ ! -f "$BLURRED_WALLPAPER" ] || [ ! -f "$BLURRED_WALLPAPER_OVERVIEW" ]; then
  magick "$WALLPAPER" -blur 0x15 -fill black -colorize 40% "$BLURRED_WALLPAPER_OVERVIEW"
  magick "$WALLPAPER" -blur 0x30 "$BLURRED_WALLPAPER"
fi

# ============================================================
# 核心保存逻辑 (已修复软链接穿透覆盖的致命 Bug)
# ============================================================
CACHE_ROFI="$HOME/.cache/wallpaper_rofi"
mkdir -p "$CACHE_ROFI"

rm -f "$CACHE_ROFI/current"
rm -f "$CACHE_ROFI/blurred"
rm -f "$CACHE_DIR_OVERVIEW/current"

ln -sf "$WALLPAPER" "$CACHE_ROFI/current"
ln -sf "$BLURRED_WALLPAPER" "$CACHE_ROFI/blurred"
ln -sf "$BLURRED_WALLPAPER_OVERVIEW" "$CACHE_DIR_OVERVIEW/current"

echo "$(date) - Done: Safely linked $FILENAME" >>/tmp/wp_debug.log

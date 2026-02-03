#!/bin/bash

# 1. 优先使用传入的参数
if [ -n "$1" ]; then
  WALLPAPER="$1"
else
  # 只有没传参数时，才去问 swww (兜底逻辑)
  sleep 0.5
  WALLPAPER=$(swww query | head -n1 | grep -oP 'image: \K.*')
fi

# 检查一下到底有没有拿到路径
if [ -z "$WALLPAPER" ]; then
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

# 这里的 swww img 其实是多余的，因为 QML 已经切换过了
# 但保留它用于做淡入淡出的特效是可以的
swww img -n overview "$BLURRED_WALLPAPER_OVERVIEW" \
  --transition-type fade \
  --transition-duration 0.5

# ============================================================
# 核心保存逻辑
# ============================================================
CACHE_ROFI="$HOME/.cache/wallpaper_rofi"
mkdir -p "$CACHE_ROFI"

# 强制复制，记录结果
cp -f "$WALLPAPER" "$CACHE_ROFI/current" && echo "Saved current" >>/tmp/wp_debug.log || echo "Failed to save current" >>/tmp/wp_debug.log
cp -f "$BLURRED_WALLPAPER" "$CACHE_ROFI/blurred" && echo "Saved blurred" >>/tmp/wp_debug.log || echo "Failed to save blurred" >>/tmp/wp_debug.log

echo "$(date) - Done" >>/tmp/wp_debug.log

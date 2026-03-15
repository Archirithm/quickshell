#!/bin/bash

TMP_DIR="/tmp/quickshell"
# 【修改 1】：创建两个独立的音频文件夹 audio_sys 和 audio_mic
mkdir -p "$HOME/Videos/videos" "$HOME/Videos/gif" "$HOME/Music/audio_sys" "$HOME/Music/audio_mic" "$TMP_DIR"

ACTION=$1
MODE=$2

if [ "$ACTION" = "start" ]; then

  if [ "$MODE" = "audio_sys" ]; then
    # 【修改 2】：保存到 audio_sys 文件夹
    FILE_PATH="$HOME/Music/audio_sys/SYS_$(date +%Y%m%d_%H%M%S).mp3"
    SINK_MONITOR=$(pactl get-default-sink).monitor
    ffmpeg -f pulse -i "$SINK_MONITOR" -y "$FILE_PATH" >"$TMP_DIR/audio_ffmpeg.log" 2>&1 &
    echo $! >"$TMP_DIR/audio_record.pid"
    # 偷偷记录一下当前是 sys 模式，方便停止时发通知
    echo "sys" >"$TMP_DIR/audio_mode.txt"
    exit 0
  fi

  if [ "$MODE" = "audio_mic" ]; then
    # 【修改 3】：保存到 audio_mic 文件夹
    FILE_PATH="$HOME/Music/audio_mic/MIC_$(date +%Y%m%d_%H%M%S).mp3"
    ffmpeg -f pulse -i default -y "$FILE_PATH" >"$TMP_DIR/audio_ffmpeg.log" 2>&1 &
    echo $! >"$TMP_DIR/audio_record.pid"
    # 偷偷记录一下当前是 mic 模式
    echo "mic" >"$TMP_DIR/audio_mode.txt"
    exit 0
  fi

  # --- (原有录屏分支保持不变) ---
  sleep 0.4
  COORDS=$(slurp)
  if [ -z "$COORDS" ]; then
    quickshell ipc call island cancelRecord
    exit 0
  fi

  if [ "$MODE" = "gif" ]; then
    wf-recorder -g "$COORDS" -f "$TMP_DIR/record.mp4" >"$TMP_DIR/record.log" 2>&1 &
  else
    FILE_PATH="$HOME/Videos/videos/REC_$(date +%Y%m%d_%H%M%S).mp4"
    wf-recorder -g "$COORDS" -f "$FILE_PATH" >"$TMP_DIR/record.log" 2>&1 &
  fi
  echo $! >"$TMP_DIR/record.pid"

elif [ "$ACTION" = "stop" ]; then

  if [ "$MODE" = "audio" ]; then
    if [ -f "$TMP_DIR/audio_record.pid" ]; then
      kill -INT $(cat "$TMP_DIR/audio_record.pid")
      rm "$TMP_DIR/audio_record.pid"

      # 【修改 4】：智能判断并发送不同文件夹的通知
      LAST_MODE=$(cat "$TMP_DIR/audio_mode.txt" 2>/dev/null)
      if [ "$LAST_MODE" = "sys" ]; then
        notify-send "quickshell" "系统录音已保存至 ~/Music/audio_sys"
      else
        notify-send "quickshell" "麦克风录音已保存至 ~/Music/audio_mic"
      fi
    fi
    exit 0
  fi

  # --- (原有停止录屏分支保持不变) ---
  if [ -f "$TMP_DIR/record.pid" ]; then
    kill -INT $(cat "$TMP_DIR/record.pid")
    rm "$TMP_DIR/record.pid"
    while pgrep -x wf-recorder >/dev/null; do sleep 0.1; done

    if [ "$MODE" = "gif" ]; then
      notify-send "quickshell" "正在压制 GIF..."
      GIF_PATH="$HOME/Videos/gif/GIF_$(date +%Y%m%d_%H%M%S).gif"
      ffmpeg -y -i "$TMP_DIR/record.mp4" -vf "fps=15,scale=720:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$GIF_PATH" >"$TMP_DIR/ffmpeg.log" 2>&1
      rm "$TMP_DIR/record.mp4"
      notify-send "quickshell" "GIF 已保存"
    else
      notify-send "quickshell" "录屏已保存"
    fi
  fi
fi

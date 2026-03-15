#!/bin/bash
config_file="/tmp/quickshell_cava_config"

# 动态获取系统当前的默认麦克风 (Source)
MIC_SOURCE=$(pactl get-default-source)

echo "
[general]
bars = 1
framerate = 30
autosens = 1

# ================= 【核心新增：强制监听麦克风】 =================
[input]
method = pulse
source = $MIC_SOURCE
# =========================================================

[smoothing]
integral = 85
gravity = 50
noise_reduction = 0.8

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 60
channels = mono
" >$config_file

exec cava -p $config_file

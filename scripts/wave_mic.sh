#!/bin/bash
config_file="/tmp/quickshell_cava_mic_config"
MIC_SOURCE=$(pactl get-default-source)
echo "
[general]
bars = 1
framerate = 30
autosens = 0
# 【核心修复】：拉高到 120 甚至 150。
# 不用担心全是高音，前端 QML 的 1.8 次方曲线会完美吃掉底噪！
sensitivity = 120

[input]
method = pulse
source = $MIC_SOURCE

[smoothing]
integral = 70
gravity = 60
noise_reduction = 0.8

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 60
channels = mono
" >$config_file
exec cava -p $config_file

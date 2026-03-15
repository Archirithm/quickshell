#!/bin/bash
config_file="/tmp/quickshell_cava_sys_config"
echo "
[general]
bars = 1
framerate = 30
autosens = 1

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

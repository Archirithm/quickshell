pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    // 追踪音频对象变化
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // --- 核心逻辑：判断是否是耳机 ---
    property bool isHeadphone: {
        if (!Pipewire.defaultAudioSink) return false
        
        // 获取设备描述 (Description) 或 属性 (Properties)
        // 转换为小写并查找 "headphone" 关键字
        const desc = (Pipewire.defaultAudioSink.description || "").toLowerCase()
        return desc.includes("headphone")
    }

    // --- 音量与静音状态 ---
    property bool sinkMuted: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false
    property real sinkVolume: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0

    // --- 功能函数 ---
    function toggleSinkMute() {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SINK@", "toggle"])
    }

    // 音量设置 (wpctl 接受 0.0 ~ 1.0 的浮点数)
    function setSinkVolume(volume: real) {
        // 限制范围防止爆音
        let safeVol = volume
        if (safeVol > 1.0) safeVol = 1.0
        if (safeVol < 0.0) safeVol = 0.0
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_SINK@", safeVol])
    }
}

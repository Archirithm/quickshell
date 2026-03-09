pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    // ============================================================
    // 【底层追踪引擎】
    // ============================================================
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    // --- 智能设备判断 ---
    property bool isHeadphone: {
        if (!Pipewire.defaultAudioSink) return false
        const desc = (Pipewire.defaultAudioSink.description || "").toLowerCase()
        return desc.includes("headphone")
    }

    // ============================================================
    // 【扬声器 (Sink) 状态与控制】
    // ============================================================
    property bool sinkMuted: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false
    property real sinkVolume: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.volume : 0

    function toggleSinkMute() {
        if (Pipewire.defaultAudioSink) {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
        }
    }

    function setSinkVolume(volume: real) {
        let safeVol = Math.max(0.0, Math.min(1.0, volume));
        if (Pipewire.defaultAudioSink) {
            Pipewire.defaultAudioSink.audio.volume = safeVol;
            if (Pipewire.defaultAudioSink.audio.muted) {
                Pipewire.defaultAudioSink.audio.muted = false;
            }
        }
    }

    // ============================================================
    // 【麦克风 (Source) 状态与控制】(全新扩写)
    // ============================================================
    property bool sourceMuted: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio.muted : false
    property real sourceVolume: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio.volume : 0

    function toggleSourceMute() {
        if (Pipewire.defaultAudioSource) {
            Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
        }
    }

    function setSourceVolume(volume: real) {
        let safeVol = Math.max(0.0, Math.min(1.0, volume));
        if (Pipewire.defaultAudioSource) {
            Pipewire.defaultAudioSource.audio.volume = safeVol;
            if (Pipewire.defaultAudioSource.audio.muted) {
                Pipewire.defaultAudioSource.audio.muted = false;
            }
        }
    }
}

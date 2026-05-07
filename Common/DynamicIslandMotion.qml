pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property real spring: 5.0
    readonly property real mass: 3.6
    readonly property real epsilon: 0.01

    readonly property real initialDamping: 1.0
    readonly property real expandingDamping: 0.7
    readonly property real shrinkingDamping: 0.8
}

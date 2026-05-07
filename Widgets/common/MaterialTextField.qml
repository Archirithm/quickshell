import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import qs.Common

TextField {
    id: root

    Material.theme: Material.System
    Material.accent: Appearance.m3colors.m3primary
    Material.primary: Appearance.m3colors.m3primary
    Material.background: Appearance.m3colors.m3surface
    Material.foreground: Appearance.m3colors.m3onSurface
    Material.containerStyle: Material.Outlined

    implicitHeight: 56
    property bool blinkOn: true
    renderType: Text.QtRendering
    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    placeholderTextColor: Appearance.m3colors.m3outline
    clip: true
    selectByMouse: true
    wrapMode: TextEdit.Wrap

    font {
        pixelSize: 15
        hintingPreference: Font.PreferFullHinting
    }

    cursorDelegate: Rectangle {
        width: 2
        radius: 1
        color: Appearance.colors.colPrimary
        visible: root.activeFocus && root.blinkOn
    }

    onActiveFocusChanged: {
        root.blinkOn = true;
        if (activeFocus)
            cursorBlinkTimer.restart();
        else
            cursorBlinkTimer.stop();
    }

    Timer {
        id: cursorBlinkTimer
        interval: 530
        repeat: true
        running: root.activeFocus
        onTriggered: root.blinkOn = !root.blinkOn
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }
}

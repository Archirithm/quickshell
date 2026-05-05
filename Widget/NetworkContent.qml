import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material
import Quickshell
import qs.Services
import qs.config
import qs.Widget.common

WidgetPanel {
    id: root
    title: "WI-FI"
    icon: "wifi"
    closeAction: () => WidgetState.qsOpen = false

    property bool isActive: WidgetState.qsOpen && WidgetState.qsView === "network"
    property string mdFont: "Material Symbols Outlined"

    Component {
        id: elementMoveNumberAnimation

        NumberAnimation {
            duration: Appearance.animation.expressiveDefaultSpatial.duration
            easing.type: Appearance.animation.expressiveDefaultSpatial.type
            easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
        }
    }

    onIsActiveChanged: {
        if (isActive) {
            Network.enableWifi();
            Network.rescanWifi();
        }
    }

    headerTools: RowLayout {
        spacing: 12

        Rectangle {
            id: mainSwitch
            width: 44; height: 24; radius: 12 
            color: Network.wifiEnabled ? Appearance.colors.colPrimary : "transparent"
            border.width: Network.wifiEnabled ? 0 : 2
            border.color: Appearance.colors.colOutline
            Behavior on color { ColorAnimation { duration: 250 } }
            
            Rectangle { 
                width: Network.wifiEnabled ? 16 : 12
                height: Network.wifiEnabled ? 16 : 12
                radius: width / 2
                x: Network.wifiEnabled ? parent.width - width - 4 : 6
                anchors.verticalCenter: parent.verticalCenter
                color: Network.wifiEnabled ? Appearance.colors.colOnPrimary : Appearance.colors.colOutline
                
                Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } } 
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 250 } }

                Text {
                    anchors.centerIn: parent
                    text: "check"
                    font.family: root.mdFont
                    font.pixelSize: 12 // 图标等比例缩小
                    font.bold: true
                    color: Appearance.colors.colPrimary
                    opacity: Network.wifiEnabled ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
            
            MouseArea { 
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: Network.toggleWifi()
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 6

        ProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: Network.wifiScanning ? 4 : 0
            opacity: Network.wifiScanning ? 1 : 0
            indeterminate: true
            Material.accent: Appearance.colors.colPrimary

            Behavior on Layout.preferredHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        ListView {
            id: wifiList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            model: Network.friendlyWifiNetworks
            property real removeOvershoot: 20
            property bool popin: true
            property bool animateAppearance: true
            property bool animateMovement: true

            delegate: WifiNetworkItem {
                required property var modelData
                width: ListView.view.width
                wifiNetwork: modelData
            }

            add: Transition {
                animations: wifiList.animateAppearance ? [
                    elementMoveNumberAnimation.createObject(this, {
                        properties: wifiList.popin ? "opacity,scale" : "opacity",
                        from: 0,
                        to: 1,
                    }),
                ] : []
            }

            addDisplaced: Transition {
                animations: wifiList.animateAppearance ? [
                    elementMoveNumberAnimation.createObject(this, {
                        property: "y"
                    }),
                    elementMoveNumberAnimation.createObject(this, {
                        properties: wifiList.popin ? "opacity,scale" : "opacity",
                        to: 1,
                    }),
                ] : []
            }

            displaced: Transition {
                animations: wifiList.animateMovement ? [
                    elementMoveNumberAnimation.createObject(this, {
                        property: "y"
                    }),
                    elementMoveNumberAnimation.createObject(this, {
                        properties: "opacity,scale",
                        to: 1,
                    }),
                ] : []
            }

            move: Transition {
                animations: wifiList.animateMovement ? [
                    elementMoveNumberAnimation.createObject(this, {
                        property: "y"
                    }),
                    elementMoveNumberAnimation.createObject(this, {
                        properties: "opacity,scale",
                        to: 1,
                    }),
                ] : []
            }

            moveDisplaced: Transition {
                animations: wifiList.animateMovement ? [
                    elementMoveNumberAnimation.createObject(this, {
                        property: "y"
                    }),
                    elementMoveNumberAnimation.createObject(this, {
                        properties: "opacity,scale",
                        to: 1,
                    }),
                ] : []
            }

            remove: Transition {
                animations: wifiList.animateAppearance ? [
                    elementMoveNumberAnimation.createObject(this, {
                        property: "x",
                        to: wifiList.width + wifiList.removeOvershoot,
                    }),
                    elementMoveNumberAnimation.createObject(this, {
                        property: "opacity",
                        to: 0,
                    }),
                ] : []
            }

            removeDisplaced: Transition {
                animations: wifiList.animateAppearance ? [
                    elementMoveNumberAnimation.createObject(this, {
                        property: "y"
                    }),
                    elementMoveNumberAnimation.createObject(this, {
                        properties: "opacity,scale",
                        to: 1,
                    }),
                ] : []
            }
        }
    }

    component WifiNetworkItem: Rectangle {
        id: itemRoot

        required property var wifiNetwork
        readonly property bool networkActive: wifiNetwork && wifiNetwork.active
        readonly property bool networkSecure: wifiNetwork && wifiNetwork.isSecure
        readonly property bool networkAskingPassword: wifiNetwork && wifiNetwork.askingPassword
        readonly property int networkStrength: wifiNetwork ? wifiNetwork.strength : 0
        readonly property string networkSsid: wifiNetwork ? wifiNetwork.ssid : "未知网络"
        readonly property bool publicPortalShown: itemRoot.networkActive && !itemRoot.networkSecure
        readonly property real verticalPadding: 12
        readonly property real baseHeight: networkRow.implicitHeight + itemRoot.verticalPadding * 2
        readonly property real passwordPromptTargetHeight: itemRoot.networkAskingPassword ? passwordPromptContent.implicitHeight + 8 : 0
        readonly property real publicPortalTargetHeight: itemRoot.publicPortalShown ? publicPortalContent.implicitHeight + 8 : 0

        height: itemRoot.baseHeight + itemRoot.passwordPromptTargetHeight + itemRoot.publicPortalTargetHeight
        radius: 10
        clip: true
        color: {
            if (itemRoot.networkActive || itemRoot.networkAskingPassword)
                return Appearance.colors.colLayer3;
            if (mouseArea.pressed)
                return Appearance.colors.colLayer2Active;
            if (mouseArea.containsMouse)
                return Appearance.colors.colLayer2Hover;
            return "transparent";
        }
        enabled: !(Network.wifiConnectTarget === itemRoot.wifiNetwork && !itemRoot.networkActive)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on height {
            animation: elementMoveNumberAnimation.createObject(this)
        }
        Behavior on y {
            animation: elementMoveNumberAnimation.createObject(this)
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Network.connectToWifiNetwork(itemRoot.wifiNetwork)
        }

        ColumnLayout {
            id: contentColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 14
                rightMargin: 14
                topMargin: itemRoot.verticalPadding
            }
            spacing: 0

            RowLayout {
                id: networkRow

                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: itemRoot.networkStrength > 80 ? "signal_wifi_4_bar" : itemRoot.networkStrength > 60 ? "network_wifi_3_bar" : itemRoot.networkStrength > 40 ? "network_wifi_2_bar" : itemRoot.networkStrength > 20 ? "network_wifi_1_bar" : "signal_wifi_0_bar"
                    font.family: root.mdFont
                    font.pixelSize: 24
                    color: itemRoot.networkActive ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: itemRoot.networkSsid
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        font.bold: true
                        font.pixelSize: 14
                        color: itemRoot.networkActive ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2
                    }
                }

                Text {
                    visible: itemRoot.networkSecure || itemRoot.networkActive || Network.wifiConnectTarget === itemRoot.wifiNetwork
                    text: itemRoot.networkActive ? "check" : Network.wifiConnectTarget === itemRoot.wifiNetwork ? "settings_ethernet" : "lock"
                    font.family: root.mdFont
                    font.pixelSize: 22
                    color: itemRoot.networkActive ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Item {
                id: passwordPromptClip

                Layout.fillWidth: true
                Layout.preferredHeight: itemRoot.passwordPromptTargetHeight
                visible: itemRoot.networkAskingPassword || height > 0
                opacity: itemRoot.networkAskingPassword ? 1 : 0
                clip: true

                Behavior on Layout.preferredHeight {
                    animation: elementMoveNumberAnimation.createObject(this)
                }
                Behavior on height {
                    animation: elementMoveNumberAnimation.createObject(this)
                }
                Behavior on opacity {
                    animation: elementMoveNumberAnimation.createObject(this)
                }

                ColumnLayout {
                    id: passwordPromptContent

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        topMargin: 8
                    }
                    spacing: 8

                    MaterialPasswordField {
                        id: passwordField
                        Layout.fillWidth: true
                        placeholderText: "密码"
                        onAccepted: Network.changePassword(itemRoot.wifiNetwork, text)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Item { Layout.fillWidth: true }
                        ActionButton {
                            text: "取消"
                            onClicked: {
                                passwordField.text = "";
                                passwordField.focus = false;
                                itemRoot.wifiNetwork.askingPassword = false;
                            }
                        }
                        ActionButton {
                            text: "连接"
                            onClicked: Network.changePassword(itemRoot.wifiNetwork, passwordField.text)
                        }
                    }
                }
            }

            Item {
                id: publicPortalClip

                Layout.fillWidth: true
                Layout.preferredHeight: itemRoot.publicPortalTargetHeight
                visible: itemRoot.publicPortalShown || height > 0
                opacity: itemRoot.publicPortalShown ? 1 : 0
                clip: true

                Behavior on Layout.preferredHeight {
                    animation: elementMoveNumberAnimation.createObject(this)
                }
                Behavior on height {
                    animation: elementMoveNumberAnimation.createObject(this)
                }
                Behavior on opacity {
                    animation: elementMoveNumberAnimation.createObject(this)
                }

                ColumnLayout {
                    id: publicPortalContent

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        topMargin: 8
                    }

                    ActionButton {
                        Layout.fillWidth: true
                        text: "打开网络门户"
                        filled: true
                        onClicked: {
                            Network.openPublicWifiPortal();
                            WidgetState.qsOpen = false;
                        }
                    }
                }
            }
        }
    }

    component MaterialPasswordField: TextField {
        id: fieldRoot

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
        echoMode: TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData
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
            visible: fieldRoot.activeFocus && fieldRoot.blinkOn
        }

        onActiveFocusChanged: {
            fieldRoot.blinkOn = true;
            if (activeFocus)
                cursorBlinkTimer.restart();
            else
                cursorBlinkTimer.stop();
        }

        Timer {
            id: cursorBlinkTimer
            interval: 530
            repeat: true
            running: fieldRoot.activeFocus
            onTriggered: fieldRoot.blinkOn = !fieldRoot.blinkOn
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
            cursorShape: Qt.IBeamCursor
        }
    }

    component ActionButton: Rectangle {
        id: actionButton

        property alias text: label.text
        property bool filled: false
        signal clicked()

        implicitWidth: label.implicitWidth + 28
        implicitHeight: 34
        radius: height / 2
        color: filled
            ? (buttonMouse.pressed ? Appearance.colors.colLayer4Active : buttonMouse.containsMouse ? Appearance.colors.colLayer4Hover : Appearance.colors.colLayer4)
            : (buttonMouse.pressed ? Appearance.colors.colLayer3Active : buttonMouse.containsMouse ? Appearance.colors.colLayer3Hover : "transparent")

        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
            id: label
            anchors.centerIn: parent
            font.pixelSize: 12
            font.bold: true
            color: Appearance.colors.colPrimary

            Behavior on color { ColorAnimation { duration: 140 } }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actionButton.clicked()
        }
    }
}

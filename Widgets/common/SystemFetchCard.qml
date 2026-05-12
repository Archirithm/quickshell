import QtQuick
import QtQuick.Layouts
import qs.Common

Rectangle {
    id: root

    property string systemUser: ""
    property string hostName: ""
    property string chassis: ""
    property string uptime: ""
    property string osAge: ""
    property string kernelRelease: ""
    property string wmName: ""
    property string shellName: ""
    property string distroId: "linux"

    property bool compact: false
    property int cardPadding: compact ? 18 : 16
    property int logoSize: compact ? 86 : 138
    property int lineLabelWidth: compact ? 58 : 62
    property int lineHeight: compact ? 20 : 22
    property int swatchBottomGap: compact ? 8 : 12

    function distroLogo() {
        const id = root.distroId.toLowerCase();
        const logos = {
            "arch": "󰣇",
            "archlinux": "󰣇",
            "endeavouros": "",
            "manjaro": "",
            "fedora": "",
            "ubuntu": "",
            "debian": "",
            "opensuse": "",
            "nixos": "",
            "gentoo": "",
            "void": ""
        };
        return logos[id] || "";
    }

    color: Appearance.colors.colLayer3
    radius: Sizes.lockCardRadius
    clip: true

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.cardPadding
        anchors.rightMargin: root.cardPadding
        spacing: root.compact ? 18 : 24

        Item {
            Layout.preferredWidth: root.logoSize
            Layout.preferredHeight: root.logoSize
            Layout.alignment: Qt.AlignVCenter
            visible: root.width >= (root.compact ? 270 : 360)

            Text {
                anchors.centerIn: parent
                text: root.distroLogo()
                color: Appearance.colors.colPrimary
                font.family: Sizes.fontFamilyMono
                font.pixelSize: root.logoSize * 0.9
                font.bold: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.compact ? 4 : 5

            Text {
                Layout.fillWidth: true
                text: (root.systemUser || "user") + "@" + (root.hostName || "host")
                color: Appearance.colors.colPrimary
                font.family: Sizes.fontFamilyMono
                font.pixelSize: root.compact ? 15 : 18
                font.bold: true
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                Layout.topMargin: root.compact ? 1 : 3
                Layout.bottomMargin: root.compact ? 2 : 4
                radius: 1
                color: Appearance.colors.colOnSurfaceVariant
                opacity: 0.45
            }

            FetchLine {
                icon: "laptop_mac"
                label: "Chassis"
                value: root.chassis
                accent: Appearance.colors.colPrimary
            }

            FetchLine {
                icon: "schedule"
                label: "Uptime"
                value: root.uptime
                accent: Appearance.colors.colSecondary
            }

            FetchLine {
                icon: "cake"
                label: "OS Age"
                value: root.osAge
                accent: Appearance.colors.colTertiary
            }

            FetchLine {
                icon: "memory"
                label: "Kernel"
                value: root.kernelRelease
                accent: Appearance.colors.colSecondary
            }

            FetchLine {
                icon: "window"
                label: "WM"
                value: root.wmName
                accent: Appearance.colors.colPrimary
            }

            FetchLine {
                icon: "terminal"
                label: "Shell"
                value: root.shellName
                accent: Appearance.colors.colTertiary
            }

            RowLayout {
                Layout.topMargin: root.compact ? 6 : 8
                Layout.bottomMargin: root.swatchBottomGap
                spacing: 6

                Repeater {
                    model: [
                        Appearance.colors.colPrimary,
                        Appearance.colors.colSecondary,
                        Appearance.colors.colTertiary,
                        Appearance.colors.colSecondary,
                        Appearance.colors.colPrimary,
                        Appearance.colors.colTertiary
                    ]

                    Rectangle {
                        required property var modelData
                        Layout.preferredWidth: root.compact ? 20 : 24
                        Layout.preferredHeight: root.compact ? 8 : 10
                        radius: 3
                        color: modelData
                    }
                }
            }
        }
    }

    component FetchLine: RowLayout {
        id: line
        property string icon: ""
        property string label: ""
        property string value: ""
        property color accent: Appearance.colors.colPrimary

        implicitHeight: root.lineHeight
        spacing: root.compact ? 7 : 9

        Text {
            Layout.preferredWidth: 22
            text: line.icon
            font.family: "Material Symbols Outlined"
            font.pixelSize: root.compact ? 16 : 18
            color: line.accent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.preferredWidth: root.lineLabelWidth
            text: line.label + ":"
            color: line.accent
            font.family: Sizes.fontFamilyMono
            font.pixelSize: root.compact ? 11 : 12
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: line.value || "--"
            color: Appearance.colors.colOnSurface
            font.family: Sizes.fontFamilyMono
            font.pixelSize: root.compact ? 11 : 12
            elide: Text.ElideRight
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Clavis.Sysmon 1.0
import qs.Common

Rectangle {
    id: root

    readonly property string systemUser: SysmonPlugin.systemUser || "user"
    readonly property string hostName: SysmonPlugin.hostName || "host"
    readonly property string distroId: SysmonPlugin.distroId || "linux"
    readonly property int sidePadding: Sizes.lockOuterPadding * 2
    readonly property int topPadding: Sizes.lockOuterPadding
    readonly property int bottomPadding: Sizes.lockOuterPadding * 2
    readonly property int promptSize: 45
    readonly property int fetchFontSize: width >= 533 ? 20 : 17
    readonly property int headerFontSize: width >= 533 ? 20 : 17
    readonly property int lineHeight: width >= 533 ? 31 : 27
    readonly property int lineLabelWidth: width >= 533 ? 61 : 53
    readonly property int bodySpacing: Math.max(18, Math.min(32, Math.floor(bodyRow.height * 0.15)))
    readonly property int contentWidth: Math.max(0, width - sidePadding * 2)
    readonly property int logoColumnWidth: Math.max(118, Math.floor(contentWidth * 0.42))
    readonly property int infoColumnWidth: Math.max(0, contentWidth - (root.width >= 300 ? logoColumnWidth + bodySpacing : 0))

    function distroLogo() {
        const id = String(root.distroId || "").toLowerCase();
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

    function paletteModel() {
        const colors = [
            Appearance.colors.colPrimary,
            Appearance.colors.colSecondary,
            Appearance.colors.colTertiary,
            Appearance.colors.colPrimaryContainer,
            Appearance.colors.colSecondaryContainer,
            Appearance.colors.colTertiaryContainer,
            Appearance.colors.colPrimary,
            Appearance.colors.colSecondary
        ];
        const count = Math.max(0, Math.min(8, Math.floor(root.infoColumnWidth / 34)));
        return colors.slice(0, count);
    }

    color: Appearance.colors.colLayer2
    radius: Sizes.lockCardRadius
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: root.sidePadding
        anchors.rightMargin: root.sidePadding
        anchors.topMargin: root.topPadding
        anchors.bottomMargin: root.bottomPadding
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: 12

            Rectangle {
                Layout.preferredWidth: root.promptSize
                Layout.preferredHeight: root.promptSize
                color: Appearance.colors.colPrimary
                radius: Sizes.lockCardRadiusSmall

                Text {
                    anchors.centerIn: parent
                    text: ">"
                    color: Appearance.colors.colOnPrimary
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: root.headerFontSize
                    font.bold: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: "fastfetch"
                color: Appearance.colors.colOnSurface
                font.family: Sizes.fontFamilyMono
                font.pixelSize: root.headerFontSize
                font.bold: true
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        RowLayout {
            id: bodyRow

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.bodySpacing

            Item {
                Layout.preferredWidth: root.logoColumnWidth
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                visible: root.width >= 300

                Text {
                    anchors.centerIn: parent
                    text: root.distroLogo()
                    color: Appearance.colors.colPrimary
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: Math.floor(Math.min(parent.width, parent.height) * 0.94)
                    font.bold: true
                }
            }

            ColumnLayout {
                id: fetchColumn

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: root.width >= 300 ? 0 : Math.floor(root.width * 0.1)
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: root.systemUser + "@" + root.hostName
                    color: Appearance.colors.colPrimary
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: root.fetchFontSize
                    font.bold: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    Layout.topMargin: 1
                    Layout.bottomMargin: 2
                    radius: 1
                    color: Appearance.colors.colOnSurfaceVariant
                    opacity: 0.45
                }

                FetchLine {
                    icon: "desktop_windows"
                    label: "OS"
                    value: SysmonPlugin.distroName
                    accent: Appearance.colors.colPrimary
                }

                FetchLine {
                    icon: "window"
                    label: "WM"
                    value: SysmonPlugin.wmName
                    accent: Appearance.colors.colSecondary
                }

                FetchLine {
                    icon: "person"
                    label: "USER"
                    value: root.systemUser
                    accent: Appearance.colors.colTertiary
                }

                FetchLine {
                    icon: "schedule"
                    label: "UP"
                    value: SysmonPlugin.uptime
                    accent: Appearance.colors.colSecondary
                }

                FetchLine {
                    icon: "memory"
                    label: "KERN"
                    value: SysmonPlugin.kernelRelease
                    accent: Appearance.colors.colPrimary
                }

                FetchLine {
                    icon: "terminal"
                    label: "SH"
                    value: SysmonPlugin.shellName
                    accent: Appearance.colors.colTertiary
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 6
                    visible: root.height > 180
                    spacing: 8

                    Repeater {
                        model: root.paletteModel()

                        Rectangle {
                            required property var modelData
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 18
                            radius: 7
                            color: modelData
                        }
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
        spacing: 7

        Text {
            Layout.preferredWidth: 22
            text: line.icon
            color: line.accent
            font.family: "Material Symbols Outlined"
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            Layout.preferredWidth: root.lineLabelWidth
            text: line.label + ":"
            color: line.accent
            font.family: Sizes.fontFamilyMono
            font.pixelSize: root.fetchFontSize
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: line.value || "--"
            color: Appearance.colors.colOnSurface
            font.family: Sizes.fontFamilyMono
            font.pixelSize: root.fetchFontSize
            elide: Text.ElideRight
        }
    }
}

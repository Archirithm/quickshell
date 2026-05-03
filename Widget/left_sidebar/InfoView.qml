import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.Services
import qs.Widget.common
import "./notifications"

Item {
    id: root


    readonly property bool isForeground: WidgetState.leftSidebarOpen && WidgetState.leftSidebarView === "info"
    readonly property int cardRadius: 24
    readonly property int cardPadding: 16
    readonly property string materialFont: "Material Symbols Outlined"
    readonly property color fetchColorChassis: Appearance.colors.colPrimary
    readonly property color fetchColorUptime: Appearance.colors.colSecondary
    readonly property color fetchColorOsAge: Appearance.colors.colTertiary
    readonly property color fetchColorKernel: Appearance.colors.colSecondary
    readonly property color fetchColorWm: Appearance.colors.colPrimary
    readonly property color fetchColorShell: Appearance.colors.colTertiary

    property string valChassis: "Loading..."
    property string valUser: Quickshell.env("USER") || "archirithm"
    property string valHost: "arch"
    property string valWm: "niri"
    property string valKernel: "Unknown"
    property string valShell: "Unknown"
    property string valDistroId: "linux"
    property string valOsAge: "Calculating..."
    property string valUptime: "Waiting..."

    function refreshDetails() {
        if (!detailsProc.running)
            detailsProc.running = true;
    }

    function distroLogo() {
        const id = valDistroId.toLowerCase();
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

    onIsForegroundChanged: {
        if (isForeground) {
            refreshDetails();
            NotificationManager.timeoutAll();
            NotificationManager.markAllRead();
        }
    }

    Component.onCompleted: {
        if (isForeground)
            refreshDetails();
    }

    Timer {
        interval: 600000
        running: root.isForeground
        repeat: true
        onTriggered: root.refreshDetails()
    }

    Process {
        id: detailsProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/sys_details.py"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data.trim());
                    if (parsed.chassis) root.valChassis = parsed.chassis;
                    if (parsed.user) root.valUser = parsed.user;
                    if (parsed.host) root.valHost = parsed.host;
                    if (parsed.wm) root.valWm = parsed.wm;
                    if (parsed.kernel) root.valKernel = parsed.kernel;
                    if (parsed.shell) root.valShell = parsed.shell;
                    if (parsed.distro_id) root.valDistroId = parsed.distro_id;
                    if (parsed.os_age) root.valOsAge = parsed.os_age;
                    if (parsed.uptime) root.valUptime = parsed.uptime;
                } catch (error) {
                    console.log("InfoView failed to parse sys_details.py output:", error);
                }
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: false
        contentWidth: width
        contentHeight: contentColumn.implicitHeight + 2

        function wheelPage(angleDeltaY) {
            if (angleDeltaY === 0)
                return;
            const direction = angleDeltaY > 0 ? -1 : 1;
            const target = flick.contentY + direction * Math.max(120, flick.height * 0.85);
            flick.contentY = Math.max(0, Math.min(target, Math.max(0, flick.contentHeight - flick.height)));
        }

        Behavior on contentY {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                flick.wheelPage(event.angleDelta.y);
                event.accepted = true;
            }
        }

        ColumnLayout {
            id: contentColumn
            width: flick.width
            spacing: 12

            InfoCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 236

                RowLayout {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: 24

                    Item {
                        Layout.preferredWidth: 154
                        Layout.preferredHeight: 154
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: root.distroLogo()
                            color: Appearance.colors.colPrimary
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 138
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 8
                        spacing: 5

                        Text {
                            Layout.fillWidth: true
                            text: root.valUser + "@" + root.valHost
                            color: Appearance.colors.colPrimary
                            font.family: Sizes.fontFamilyMono
                            font.pixelSize: 18
                            font.bold: true
                            Layout.bottomMargin: 4
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 2
                            Layout.bottomMargin: 4
                            radius: 1
                            color: Appearance.colors.colOnSurfaceVariant
                            opacity: 0.45
                        }

                        FetchLine {
                            icon: "laptop_mac"
                            label: "Chassis"
                            value: root.valChassis
                            accent: root.fetchColorChassis
                        }

                        FetchLine {
                            icon: "schedule"
                            label: "Uptime"
                            value: root.valUptime
                            accent: root.fetchColorUptime
                        }

                        FetchLine {
                            icon: "cake"
                            label: "OS Age"
                            value: root.valOsAge
                            accent: root.fetchColorOsAge
                        }

                        FetchLine {
                            icon: "memory"
                            label: "Kernel"
                            value: root.valKernel
                            accent: root.fetchColorKernel
                        }

                        FetchLine {
                            icon: "window"
                            label: "WM"
                            value: root.valWm
                            accent: root.fetchColorWm
                        }

                        FetchLine {
                            icon: "terminal"
                            label: "Shell"
                            value: root.valShell
                            accent: root.fetchColorShell
                        }

                        FetchSwatches {
                            Layout.topMargin: 4
                            Layout.alignment: Qt.AlignLeft
                        }
                    }
                }
            }

            NotificationCenterCard {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(360, flick.height - 236 - contentColumn.spacing)
            }
        }
    }

    component InfoCard: Rectangle {
        id: card
        default property alias content: body.data
        color: Appearance.colors.colLayer3
        radius: root.cardRadius

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: root.cardPadding
        }
    }

    component MaterialIcon: Text {
        property int iconSize: 20
        font.family: root.materialFont
        font.pixelSize: iconSize
        color: Appearance.colors.colOnSurface
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    component FetchLine: RowLayout {
        id: line
        property string icon: ""
        property string label: ""
        property string value: ""
        property color accent: Appearance.colors.colPrimary

        implicitHeight: 22
        spacing: 9

        MaterialIcon {
            Layout.preferredWidth: 22
            text: line.icon
            iconSize: 18
            color: line.accent
        }

        Text {
            Layout.preferredWidth: 62
            text: line.label + ":"
            color: line.accent
            font.family: Sizes.fontFamilyMono
            font.pixelSize: 12
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: line.value
            color: Appearance.colors.colOnSurface
            font.family: Sizes.fontFamilyMono
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    component FetchSwatches: RowLayout {
        spacing: 6

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 10
            radius: 3
            color: root.fetchColorChassis
        }

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 10
            radius: 3
            color: root.fetchColorUptime
        }

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 10
            radius: 3
            color: root.fetchColorOsAge
        }

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 10
            radius: 3
            color: root.fetchColorKernel
        }

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 10
            radius: 3
            color: root.fetchColorWm
        }

        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 10
            radius: 3
            color: root.fetchColorShell
        }
    }

}

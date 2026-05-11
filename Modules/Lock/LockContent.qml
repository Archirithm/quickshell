import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Clavis.Sysmon 1.0
import qs.Common
import qs.Widgets.common
import "Cards"

Item {
    id: root

    property var context: null
    property real screenHeight: height
    readonly property real centerScale: Math.min(1, root.screenHeight / 1440)
    readonly property real centerWidth: Math.min(Sizes.lockCenterWidth * centerScale, width * 0.48)

    function forceAuthFocus() {
        authCard.forceActiveFocus();
    }

    RowLayout {
        anchors.fill: parent
        spacing: Sizes.lockColumnGap

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Sizes.lockCardGap

            WeatherCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                radius: Sizes.lockCardRadiusSmall
                topLeftRadius: Sizes.lockCardRadiusLarge
            }

            SystemFetchCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Sizes.lockCardRadiusSmall
                color: Appearance.colors.colLayer2
                compact: true
                cardPadding: 18
                systemUser: SysmonPlugin.systemUser
                hostName: SysmonPlugin.hostName
                chassis: SysmonPlugin.chassis
                uptime: SysmonPlugin.uptime
                osAge: SysmonPlugin.osAgeText
                kernelRelease: SysmonPlugin.kernelRelease
                wmName: SysmonPlugin.wmName
                shellName: SysmonPlugin.shellName
                distroId: SysmonPlugin.distroId
            }

            MediaCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                radius: Sizes.lockCardRadiusSmall
                bottomLeftRadius: Sizes.lockCardRadiusLarge
            }
        }

        ColumnLayout {
            Layout.preferredWidth: root.centerWidth
            Layout.fillHeight: true
            Layout.fillWidth: false
            spacing: Sizes.lockColumnGap

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 0

                Text {
                    id: timeText
                    text: Qt.formatTime(clockTimer.now, "HH:mm")
                    color: Appearance.colors.colSecondary
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: Math.floor(84 * root.centerScale)
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: Qt.formatDate(clockTimer.now, "dddd, d MMMM yyyy")
                    color: Appearance.colors.colTertiary
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: Math.floor(24 * root.centerScale)
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Item {
                Layout.preferredWidth: root.centerWidth / 2
                Layout.preferredHeight: root.centerWidth / 2
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                    color: "black"
                }

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: Paths.fileUrl(Paths.defaultAvatar)
                    sourceSize: Qt.size(width, height)
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                    cache: true
                }

                OpacityMask {
                    anchors.fill: parent
                    source: avatarImg
                    maskSource: avatarMask
                }

                Text {
                    anchors.centerIn: parent
                    text: "person"
                    visible: avatarImg.status !== Image.Ready
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: parent.width * 0.45
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: Appearance.colors.colOutline
                    border.width: 4
                }
            }

            AuthCard {
                id: authCard
                Layout.preferredWidth: root.centerWidth * 0.8
                Layout.preferredHeight: 50
                Layout.alignment: Qt.AlignHCenter
                context: root.context

                onRequestUnlock: {
                    if (root.context)
                        root.context.tryUnlock();
                }
            }

            Item {
                Layout.fillWidth: true
                implicitHeight: Math.max(errorMessage.implicitHeight, 18)

                Text {
                    id: errorMessage
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: root.context && root.context.showFailure ? "Incorrect password. Please try again." : ""
                    opacity: text.length > 0 ? 1 : 0
                    scale: text.length > 0 ? 1 : 0.7
                    color: Appearance.colors.colError
                    font.family: Sizes.fontFamilyMono
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.expressiveEffects.duration
                            easing.type: Appearance.animation.expressiveEffects.type
                            easing.bezierCurve: Appearance.animation.expressiveEffects.bezierCurve
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Appearance.animation.expressiveDefaultSpatial.duration
                            easing.type: Appearance.animation.expressiveDefaultSpatial.type
                            easing.bezierCurve: Appearance.animation.expressiveDefaultSpatial.bezierCurve
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Sizes.lockCardGap

            SystemGrid {
                Layout.fillWidth: true
                Layout.preferredHeight: 280
                radius: Sizes.lockCardRadiusSmall
                topRightRadius: Sizes.lockCardRadiusLarge
            }

            NotificationCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Sizes.lockCardRadiusSmall
                bottomRightRadius: Sizes.lockCardRadiusLarge
            }
        }
    }

    Timer {
        id: clockTimer
        property date now: new Date()
        interval: 1000
        running: true
        repeat: true
        onTriggered: now = new Date()
    }
}

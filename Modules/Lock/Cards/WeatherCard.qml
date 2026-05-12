import QtQuick
import QtQuick.Layouts
import Clavis.Weather 1.0
import qs.Common

Rectangle {
    id: root

    property real rootHeight: height

    readonly property string temp: fmtTemp(WeatherPlugin.currentTemperatureC, "--")
    readonly property string cond: WeatherPlugin.loading ? "Loading..." : (WeatherPlugin.currentWeatherText || "Unknown")
    readonly property string loc: WeatherPlugin.locationName || "Location"
    readonly property string iconName: WeatherPlugin.currentIconName || "cloud"
    readonly property string feelsLike: "Feels like: " + fmtTemp(WeatherPlugin.currentFeelsLikeC, "--")
    readonly property string humidity: "Humidity: " + fmtPercent(WeatherPlugin.currentRelativeHumidity)
    readonly property bool loadingState: WeatherPlugin.loading || !WeatherPlugin.hasValidData
    readonly property bool showTitle: root.rootHeight > 610 && root.height > 150
    readonly property bool showSkeletonForecast: root.loadingState && root.rootHeight > 610
    readonly property bool showForecast: WeatherPlugin.hasValidData && root.rootHeight > 610 && WeatherPlugin.hourlyForecast.count() > 0
    readonly property int forecastCount: root.width < 320 ? 3 : root.width < 360 ? 4 : 5
    readonly property int forecastSpacing: root.width < 400 ? 12 : 22
    readonly property int forecastFontSize: root.width < 400 ? 18 : 20
    readonly property int forecastIconSize: root.width < 400 ? 50 : 56
    readonly property int contentMargin: Sizes.lockOuterPadding * 2
    property real skeletonPulse: 0

    Layout.fillWidth: true
    implicitHeight: showForecast || showSkeletonForecast ? Sizes.lockWeatherForecastHeight : Sizes.lockWeatherCompactHeight
    color: Appearance.colors.colLayer2
    radius: Sizes.lockCardRadius
    clip: true

    function validNumber(value) {
        return typeof value === "number" && isFinite(value);
    }

    function fmtTemp(value, fallback) {
        if (!WeatherPlugin.hasValidData || !validNumber(value))
            return fallback;
        return Math.round(value) + "°";
    }

    function fmtPercent(value) {
        if (!WeatherPlugin.hasValidData || !validNumber(value))
            return "--";
        return Math.round(value) + "%";
    }

    function hourLabel(value) {
        const epoch = Number(value || 0);
        const date = new Date(epoch > 100000000000 ? epoch : epoch * 1000);
        if (isNaN(date.getTime()))
            return "--";
        const hour = date.getHours();
        if (hour === 0)
            return "12 AM";
        if (hour === 12)
            return "12 PM";
        return (hour > 12 ? hour - 12 : hour).toString().padStart(2, "0") + (hour > 12 ? " PM" : " AM");
    }

    function forecastModel() {
        const count = Math.min(root.forecastCount, WeatherPlugin.hourlyForecast.count());
        const items = [];
        for (let i = 0; i < count; i += 1)
            items.push(WeatherPlugin.hourlyForecast.get(i));
        return items;
    }

    Component.onCompleted: {
        if (!WeatherPlugin.hasValidData)
            WeatherPlugin.refresh();
    }

    ColumnLayout {
        id: contentLayout

        anchors.fill: parent
        anchors.leftMargin: root.contentMargin
        anchors.rightMargin: root.contentMargin
        anchors.topMargin: root.showTitle ? Sizes.lockOuterPadding * 2 : Sizes.lockOuterPadding
        anchors.bottomMargin: root.showForecast ? Sizes.lockOuterPadding * 2 : Sizes.lockOuterPadding
        opacity: root.loadingState ? 0 : 1
        scale: root.loadingState ? 0.98 : 1
        spacing: 7

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

        Text {
            visible: root.showTitle
            text: "Weather"
            color: Appearance.colors.colPrimary
            font.family: Sizes.fontFamily
            font.pixelSize: 36
            font.weight: 500
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: -Sizes.lockOuterPadding
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 22

            Text {
                text: root.iconName
                color: Appearance.colors.colSecondary
                font.family: "Material Symbols Outlined"
                font.pixelSize: root.width < 320 ? 72 : 92
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 9

                Text {
                    Layout.fillWidth: true
                    text: root.width <= 320 ? root.temp + "  " + root.cond : root.cond
                    color: Appearance.colors.colSecondary
                    font.family: Sizes.fontFamily
                    font.pixelSize: 24
                    font.weight: 500
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.humidity
                    color: Appearance.colors.colOnSurfaceVariant
                    font.family: Sizes.fontFamily
                    font.pixelSize: 17
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                visible: root.width > 360
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 7
                spacing: 9

                Text {
                    Layout.fillWidth: true
                    text: root.temp
                    color: Appearance.colors.colPrimary
                    font.family: Sizes.fontFamily
                    font.pixelSize: 38
                    font.weight: 500
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }

                Text {
                    Layout.fillWidth: true
                    text: root.feelsLike
                    color: Appearance.colors.colOutline
                    font.family: Sizes.fontFamily
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }
        }

        RowLayout {
            visible: root.showForecast
            Layout.fillWidth: true
            Layout.topMargin: 10
            spacing: root.forecastSpacing

            Repeater {
                model: root.forecastModel()

                ColumnLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: root.hourLabel(parent.modelData.time)
                        color: Appearance.colors.colOutline
                        font.family: Sizes.fontFamily
                        font.pixelSize: root.forecastFontSize
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: root.forecastIconSize + 8
                        text: parent.modelData.iconName || "cloud_alert"
                        color: Appearance.colors.colOnSurface
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: root.forecastIconSize
                        font.weight: 500
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.fmtTemp(parent.modelData.temperatureC, "--")
                        color: Appearance.colors.colSecondary
                        font.family: Sizes.fontFamily
                        font.pixelSize: root.forecastFontSize
                    }
                }
            }
        }
    }

    Item {
        id: skeleton

        anchors.fill: parent
        z: 2
        opacity: root.loadingState ? 1 : 0
        scale: root.loadingState ? 1 : 0.98
        visible: opacity > 0

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

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: root.contentMargin
            anchors.rightMargin: root.contentMargin
            anchors.topMargin: root.showTitle ? Sizes.lockOuterPadding * 2 : Sizes.lockOuterPadding
            anchors.bottomMargin: root.showSkeletonForecast ? Sizes.lockOuterPadding * 2 : Sizes.lockOuterPadding
            spacing: 7

            SkeletonBlock {
                Layout.preferredWidth: 128
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: -Sizes.lockOuterPadding
                visible: root.showTitle
                pulse: root.skeletonPulse
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 20

                SkeletonBlock {
                    Layout.preferredWidth: root.width < 320 ? 72 : 92
                    Layout.preferredHeight: root.width < 320 ? 72 : 92
                    Layout.alignment: Qt.AlignVCenter
                    radius: Sizes.lockCardRadiusSmall
                    pulse: root.skeletonPulse
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 9

                    SkeletonBlock {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        pulse: root.skeletonPulse
                    }

                    SkeletonBlock {
                        Layout.preferredWidth: Math.max(90, parent.width * 0.7)
                        Layout.preferredHeight: 18
                        pulse: root.skeletonPulse
                    }
                }

                ColumnLayout {
                    visible: root.width > 360
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 7
                    spacing: 9

                    SkeletonBlock {
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 38
                        pulse: root.skeletonPulse
                    }

                    SkeletonBlock {
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 18
                        pulse: root.skeletonPulse
                    }
                }
            }

            RowLayout {
                visible: root.showSkeletonForecast
                Layout.fillWidth: true
                Layout.topMargin: 10
                spacing: root.forecastSpacing

                Repeater {
                    model: root.forecastCount

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        SkeletonBlock {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            pulse: root.skeletonPulse
                        }

                        SkeletonBlock {
                            Layout.preferredWidth: root.forecastIconSize
                            Layout.preferredHeight: root.forecastIconSize
                            Layout.alignment: Qt.AlignHCenter
                            radius: Sizes.lockCardRadiusSmall
                            pulse: root.skeletonPulse
                        }

                        SkeletonBlock {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignHCenter
                            pulse: root.skeletonPulse
                        }
                    }
                }
            }
        }
    }

    SequentialAnimation on skeletonPulse {
        running: root.loadingState
        loops: Animation.Infinite

        NumberAnimation {
            to: 1
            duration: Appearance.animation.standard.duration
            easing.type: Appearance.animation.standard.type
            easing.bezierCurve: Appearance.animation.standard.bezierCurve
        }

        NumberAnimation {
            to: 0
            duration: Appearance.animation.standard.duration
            easing.type: Appearance.animation.standard.type
            easing.bezierCurve: Appearance.animation.standard.bezierCurve
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 900000
        onTriggered: WeatherPlugin.refresh()
    }

    component SkeletonBlock: Rectangle {
        property real pulse: 0

        color: Appearance.colors.colOnSurfaceVariant
        opacity: 0.14 + pulse * 0.12
        radius: 8
    }
}

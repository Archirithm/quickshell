import QtQuick
import QtQuick.Controls
import qs.config

Rectangle {
    id: root

    property var sourceModel
    property int maxHours: 25
    property var items: []
    property var keyLines: []
    property real chartMax: 150
    property bool hasData: false
    property real itemWidth: width > 0 ? width / 6 : 122

    readonly property real sidePadding: 18
    readonly property real topPadding: 14
    readonly property real chartTop: 70
    readonly property real chartBottom: height - 52
    readonly property real chartWidth: Math.max(0, width - sidePadding * 2)
    readonly property real contentWidth: Math.max(width, items.length * itemWidth)

    radius: 22
    color: Qt.rgba(Colorscheme.surface_container_high.r, Colorscheme.surface_container_high.g, Colorscheme.surface_container_high.b, 0.42)
    clip: true

    function aqiThresholds() {
        return [0, 20, 50, 100, 150, 250]
    }

    function aqiLevelIndex(aqi) {
        if (aqi === undefined || aqi === null || isNaN(aqi)) return -1
        const thresholds = aqiThresholds()
        for (let i = thresholds.length - 1; i >= 0; --i) {
            if (aqi >= thresholds[i]) return i
        }
        return -1
    }

    function aqiLevelName(level) {
        const names = ["优", "良", "差", "不健康", "很不健康", "危险"]
        return level >= 0 && level < names.length ? names[level] : "--"
    }

    function aqiPalette(level) {
        const colors = ["#00e59b", "#ffc302", "#ff712b", "#f62a55", "#c72eaa", "#9930ff"]
        return colors[Math.max(0, Math.min(colors.length - 1, level >= 0 ? level : 0))]
    }

    function pollutantIndex(value, thresholds) {
        if (value === undefined || value === null || isNaN(value)) return NaN
        const aqi = aqiThresholds()
        for (let level = thresholds.length - 1; level >= 0; --level) {
            if (value >= thresholds[level]) {
                if (level < thresholds.length - 1) {
                    const bpLo = thresholds[level]
                    const bpHi = thresholds[level + 1]
                    const inLo = aqi[level]
                    const inHi = aqi[level + 1]
                    return Math.round((inHi - inLo) / (bpHi - bpLo) * (value - bpLo) + inLo)
                }
                return Math.round(value * aqi[aqi.length - 1] / thresholds[thresholds.length - 1])
            }
        }
        return NaN
    }

    function hourlyAqiValue(air) {
        if (!air) return NaN
        const values = [
            pollutantIndex(air.ozone, [0, 50, 100, 160, 240, 480]),
            pollutantIndex(air.nitrogenDioxide, [0, 10, 25, 200, 400, 1000]),
            pollutantIndex(air.pm10, [0, 15, 45, 80, 160, 400]),
            pollutantIndex(air.pm25, [0, 5, 15, 30, 60, 150])
        ].filter(function(v) { return !isNaN(v) })
        if (values.length === 0) return NaN
        return Math.max.apply(Math, values)
    }

    function hourLabel(epoch) {
        return epoch ? Qt.formatDateTime(new Date(epoch * 1000), "hh:00") : "--"
    }

    function yForValue(value) {
        if (value === undefined || value === null || isNaN(value)) return chartBottom
        if (chartMax <= 0) return chartBottom
        const clamped = Math.max(0, Math.min(chartMax, value))
        return chartBottom - clamped / chartMax * (chartBottom - chartTop)
    }

    function chartUpperBound(highest) {
        if (highest === undefined || highest === null || isNaN(highest) || highest <= 0) return 100
        if (highest <= 100) return 100
        if (highest <= 150) return 150
        if (highest <= 250) return 250
        return Math.ceil(highest / 50) * 50
    }

    function rebuild() {
        const list = []
        let highest = 0
        let validCount = 0
        const count = sourceModel && sourceModel.count ? Math.min(maxHours, sourceModel.count()) : 0
        for (let i = 0; i < count; ++i) {
            const hour = sourceModel.get(i) || ({})
            const aqi = hourlyAqiValue(hour.airQuality || ({}))
            const level = aqiLevelIndex(aqi)
            if (!isNaN(aqi)) {
                highest = Math.max(highest, aqi)
                validCount += 1
            }
            list.push({
                time: hour.time || 0,
                hourText: hourLabel(hour.time || 0),
                aqi: aqi,
                aqiText: !isNaN(aqi) ? Math.round(aqi).toString() : "--",
                color: aqiPalette(level),
                emphasized: i !== 0
            })
        }
        items = list
        chartMax = chartUpperBound(highest)
        hasData = validCount > 0

        const lines = [
            { value: 20, label: aqiLevelName(1) },
            { value: 100, label: aqiLevelName(3) }
        ]
        if (chartMax >= 250) {
            lines.push({ value: 250, label: aqiLevelName(5) })
        }
        keyLines = lines
    }

    onSourceModelChanged: rebuild()
    onWidthChanged: Qt.callLater(rebuild)
    onHeightChanged: Qt.callLater(rebuild)
    Component.onCompleted: rebuild()

    Connections {
        target: root.sourceModel
        ignoreUnknownSignals: true

        function onModelReset() {
            root.rebuild()
        }

        function onRowsInserted() {
            root.rebuild()
        }

        function onRowsRemoved() {
            root.rebuild()
        }

        function onDataChanged() {
            root.rebuild()
        }
    }

    Repeater {
        model: root.keyLines

        Item {
            required property var modelData

            x: root.sidePadding
            y: root.yForValue(modelData.value)
            width: root.chartWidth
            height: 20

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 1
                color: Qt.rgba(Colorscheme.outline_variant.r, Colorscheme.outline_variant.g, Colorscheme.outline_variant.b, 0.44)
            }

            Text {
                anchors.left: parent.left
                anchors.bottom: parent.verticalCenter
                anchors.leftMargin: 2
                anchors.bottomMargin: 5
                text: modelData.value
                color: Qt.rgba(Colorscheme.on_surface_variant.r, Colorscheme.on_surface_variant.g, Colorscheme.on_surface_variant.b, 0.72)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
            }

            Text {
                anchors.right: parent.right
                anchors.bottom: parent.verticalCenter
                anchors.rightMargin: 2
                anchors.bottomMargin: 5
                text: modelData.label
                color: Qt.rgba(Colorscheme.on_surface_variant.r, Colorscheme.on_surface_variant.g, Colorscheme.on_surface_variant.b, 0.72)
                font.family: "LXGW WenKai GB Screen"
                font.pixelSize: 12
            }
        }
    }

    Flickable {
        id: trendFlick

        anchors.fill: parent
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick
        contentWidth: root.contentWidth
        contentHeight: height

        Item {
            id: trendContent
            width: trendFlick.contentWidth
            height: trendFlick.height

            Repeater {
                model: root.items

                Item {
                    required property var modelData
                    required property int index

                    x: index * root.itemWidth
                    width: root.itemWidth
                    height: root.height

                    readonly property real barWidth: Math.max(8, Math.min(12, width * 0.36))
                    readonly property real barHeight: !isNaN(modelData.aqi) ? Math.max(8, root.chartBottom - root.yForValue(modelData.aqi)) : 0
                    readonly property color hourColor: modelData.emphasized
                                                       ? Colorscheme.on_surface_variant
                                                       : Qt.rgba(Colorscheme.on_surface_variant.r, Colorscheme.on_surface_variant.g, Colorscheme.on_surface_variant.b, 0.64)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.topPadding
                        text: modelData.hourText
                        color: parent.hourColor
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }

                    Rectangle {
                        visible: !isNaN(modelData.aqi)
                        width: parent.barWidth
                        height: parent.barHeight
                        x: (parent.width - width) / 2
                        y: root.chartBottom - height
                        radius: width / 2
                        color: Qt.rgba(Qt.color(modelData.color).r, Qt.color(modelData.color).g, Qt.color(modelData.color).b, 0.58)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.chartBottom + 8
                        text: modelData.aqiText
                        color: Colorscheme.on_surface
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                }
            }

            MouseArea {
                id: dragArea
                x: trendFlick.contentX
                y: 0
                z: 20
                width: trendFlick.width
                height: trendFlick.height
                acceptedButtons: Qt.LeftButton
                preventStealing: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                property real lastMouseX: 0

                onPressed: function(mouse) {
                    lastMouseX = mouse.x
                }

                onPositionChanged: function(mouse) {
                    if (!pressed) return
                    const dx = mouse.x - lastMouseX
                    const maxX = Math.max(0, trendFlick.contentWidth - trendFlick.width)
                    trendFlick.contentX = Math.max(0, Math.min(maxX, trendFlick.contentX - dx))
                    lastMouseX = mouse.x
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.hasData
        text: "空气质量数据暂不可用"
        color: Colorscheme.on_surface_variant
        font.family: "LXGW WenKai GB Screen"
        font.pixelSize: 16
    }
}

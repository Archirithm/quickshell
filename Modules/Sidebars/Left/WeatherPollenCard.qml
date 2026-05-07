import QtQuick
import QtQuick.Shapes
import qs.Common

WeatherInsightCard {
    id: root

    property var pollenMap: ({})

    readonly property color ink: Qt.rgba(0.96, 0.95, 0.97, 0.96)
    readonly property color mutedInk: Qt.rgba(0.90, 0.88, 0.92, 0.92)
    readonly property var displayItems: buildDisplayItems()

    icon: ""
    title: ""
    color: Qt.rgba(0.10, 0.12, 0.13, 0.985)
    border.width: 0

    function validNumber(value) {
        return value !== undefined && value !== null && !isNaN(value)
    }

    function pollenDefinitions() {
        return [
            { key: "grass", title: "草类", thresholds: [0, 3, 30, 50, 250] },
            { key: "birch", title: "桦树", thresholds: [0, 10, 60, 100, 500] },
            { key: "alder", title: "桤木", thresholds: [0, 10, 60, 100, 500] },
            { key: "mugwort", title: "艾蒿", thresholds: [0, 3, 30, 50, 250] },
            { key: "olive", title: "橄榄", thresholds: [0, 20, 100, 200, 500] },
            { key: "ragweed", title: "豚草", thresholds: [0, 3, 30, 50, 250] }
        ]
    }

    function pollenIndexThresholds() {
        return [0, 25, 50, 75, 100]
    }

    function pollenLevelColor(level) {
        const colors = ["#bfbfbf", "#08c286", "#6ad555", "#ffd741", "#ffab40", "#ff3b30"]
        return colors[Math.max(0, Math.min(colors.length - 1, level))]
    }

    function pollenLevelName(level) {
        const names = ["无", "非常低", "低", "中", "高", "非常高"]
        return names[Math.max(0, Math.min(names.length - 1, level))]
    }

    function interpolateIndex(value, thresholds, level) {
        const outThresholds = pollenIndexThresholds()
        if (level < thresholds.length - 1) {
            const bpLo = thresholds[level]
            const bpHi = thresholds[level + 1]
            const inLo = outThresholds[level]
            const inHi = outThresholds[level + 1]
            return Math.round(((inHi - inLo) / (bpHi - bpLo)) * (value - bpLo) + inLo)
        }
        return Math.round((value * outThresholds[outThresholds.length - 1]) / thresholds[thresholds.length - 1])
    }

    function pollenIndex(value, thresholds) {
        if (!validNumber(value))
            return null
        let level = -1
        for (let i = 0; i < thresholds.length; ++i) {
            if (value >= thresholds[i])
                level = i
        }
        return level >= 0 ? interpolateIndex(value, thresholds, level) : 0
    }

    function pollenLevel(index) {
        if (index === null || index === undefined)
            return null
        const thresholds = pollenIndexThresholds()
        let level = -1
        for (let i = 0; i < thresholds.length; ++i) {
            if (index >= thresholds[i])
                level = i
        }
        if (level < 0)
            level = 0
        return Math.max(0, Math.min(5, level))
    }

    function buildDisplayItems() {
        const items = []
        const defs = pollenDefinitions()
        let hasAnyValue = false
        for (let i = 0; i < defs.length; ++i) {
            const def = defs[i]
            const value = pollenMap ? pollenMap[def.key] : undefined
            if (!validNumber(value))
                continue
            hasAnyValue = true
            const index = pollenIndex(value, def.thresholds)
            const level = pollenLevel(index)
            items.push({
                key: def.key,
                title: def.title,
                level: level,
                levelText: pollenLevelName(level),
                color: pollenLevelColor(level),
                index: index
            })
        }

        if (!hasAnyValue) {
            return [{
                title: "花粉数据",
                levelText: "暂无数据",
                color: pollenLevelColor(0)
            }]
        }

        items.sort(function(a, b) { return b.index - a.index })
        if (items.length > 0 && items[0].index <= 0) {
            return [{
                title: "今日花粉",
                levelText: "无",
                color: pollenLevelColor(0)
            }]
        }
        return items.slice(0, 2)
    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.topMargin: 16
        spacing: 8
        z: 2

        Item {
            width: 28
            height: 28

            Shape {
                width: 960
                height: 960
                anchors.centerIn: parent
                scale: Math.min(parent.width / width, parent.height / height)
                antialiasing: true
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeWidth: 0
                    fillColor: root.mutedInk

                    PathSvg {
                        path: "M760,900Q745,900 732,893Q719,886 711,874Q590,852 497.5,766Q405,680 368,554Q272,599 216,686.5Q160,774 160,880L80,880Q80,746 153.5,636Q227,526 350,474Q329,359 346.5,266.5Q364,174 420,117Q420,117 420,117Q420,117 420,117Q422,93 439,76.5Q456,60 480,60Q505,60 522.5,77.5Q540,95 540,120Q540,145 522.5,162.5Q505,180 480,180Q478,180 476,180Q474,180 471,179Q449,204 436,240.5Q423,277 419,322Q439,302 465.5,287.5Q492,273 524,265Q554,257 588.5,254.5Q623,252 661,255Q669,247 679,243.5Q689,240 700,240Q725,240 742.5,257.5Q760,275 760,300Q760,325 742.5,342.5Q725,360 700,360Q686,360 672.5,353.5Q659,347 651,335Q618,333 587.5,335.5Q557,338 533,346Q494,359 471.5,384Q449,409 443,448Q471,443 490.5,441.5Q510,440 576,440Q584,430 595.5,425Q607,420 620,420Q645,420 662.5,437.5Q680,455 680,480Q680,505 662.5,522.5Q645,540 620,540Q607,540 595.5,535Q584,530 576,520Q513,520 493,521.5Q473,523 448,528Q461,562 499,580Q537,598 598,600Q627,602 660.5,599Q694,596 728,590Q736,576 750,568Q764,560 780,560Q805,560 822.5,577.5Q840,595 840,620Q840,645 822.5,662.5Q805,680 780,680Q770,680 761.5,677Q753,674 745,668Q711,674 678.5,677.5Q646,681 617,681Q588,681 562,678Q536,675 513,669Q551,718 605.5,751.5Q660,785 720,796Q728,788 738.5,784Q749,780 760,780Q785,780 802.5,797.5Q820,815 820,840Q820,865 802.5,882.5Q785,900 760,900Z"
                    }
                }
            }
        }

        Text {
            text: "花粉"
            color: root.mutedInk
            font.pixelSize: 18
            font.bold: true
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.topMargin: 78
        spacing: 20

        Repeater {
            model: root.displayItems.length

            Row {
                width: parent.width
                spacing: 10

                Rectangle {
                    width: 12
                    height: 12
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.displayItems[index].color
                }

                Column {
                    width: parent.width - 22
                    spacing: 1

                    Text {
                        text: root.displayItems[index].title
                        color: root.ink
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.displayItems[index].levelText
                        color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.80)
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}

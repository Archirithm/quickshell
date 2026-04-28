import QtQuick

Item {
    id: root

    property real value: NaN
    property string level: "--"
    property int activeIndex: -1

    WeatherBlob {
        anchors.fill: parent
        value: root.value
        level: root.level
        activeIndex: root.activeIndex
        title: "紫外线指数"
    }
}

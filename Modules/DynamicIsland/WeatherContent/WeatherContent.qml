import QtQuick
import qs.config
import "file:///home/archirithm/.config/quickshell/JS/weather.js" as WeatherJS
import "file:///home/archirithm/.config/quickshell/JS/astro.js" as AstroJS

Item {
    id: root
    width: 720
    height: 540
    
    property string materialFont: "Material Symbols Outlined" 
    
    property real latitude: 0
    property real longitude: 0
    property string locationName: "LOCATING..."

    property string currentTemp: "--"
    property string currentIcon: "cloud"
    property string currentDesc: "--"
    property string feelsLike: "--"
    property string humidity: "--"
    property string windSpeed: "--"
    property string pressure: "--"
    
    property bool isHourly: true
    property var hourlyData: []
    property var dailyData: []
    property real sunAzimuth: 0
    property real sunAltitude: 0

    Component.onCompleted: {
        fetchData() 
    }

    // ================== 全局 UI 超时控制 ==================
    Timer {
        id: forceStopTimer
        interval: 5000 // 强制 5 秒超时
        onTriggered: root.stopRefreshAnim()
    }

    function stopRefreshAnim() {
        forceStopTimer.stop()
        if (spinAnim.running) {
            spinAnim.stop()
        }
        // 触发顺滑归位动画
        resetAnim.start()
    }

    function fetchData() {
        WeatherJS.fetchLocationAndWeather(function(data) {
            // 收到任何回调，立刻停止动画并归位
            root.stopRefreshAnim()
            
            if (!data) return;

            root.latitude = data.lat
            root.longitude = data.lon
            root.locationName = data.locName

            root.currentTemp = Math.round(data.current.temperature_2m) + "°"
            root.currentIcon = WeatherJS.getMaterialIcon(data.current.weather_code)
            root.currentDesc = WeatherJS.getWeatherDesc(data.current.weather_code)
            root.feelsLike = Math.round(data.current.apparent_temperature) + "°C"
            root.humidity = data.current.relative_humidity_2m + "%"
            root.windSpeed = data.current.wind_speed_10m + " km/h"
            root.pressure = data.current.surface_pressure + " hPa"

            var now = new Date()
            var startIndex = 0
            for (var i = 0; i < data.hourly.time.length; i++) {
                if (new Date(data.hourly.time[i]) >= now) { startIndex = Math.max(0, i - 1); break }
            }
            var tempHourly = []
            for (var h = 0; h < 12; h++) {
                var idx = startIndex + h
                var timeObj = new Date(data.hourly.time[idx])
                tempHourly.push({
                    time: timeObj.getHours().toString().padStart(2, '0') + ":00",
                    temp: Math.round(data.hourly.temperature_2m[idx]),
                    icon: WeatherJS.getMaterialIcon(data.hourly.weather_code[idx])
                })
            }
            root.hourlyData = tempHourly

            var tempDaily = []
            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            for (var d = 0; d < 7; d++) {
                var dateObj = new Date(data.daily.time[d])
                tempDaily.push({
                    day: (d === 0) ? "Today" : days[dateObj.getDay()],
                    icon: WeatherJS.getMaterialIcon(data.daily.weather_code[d]),
                    maxTemp: Math.round(data.daily.temperature_2m_max[d]) + "°",
                    minTemp: Math.round(data.daily.temperature_2m_min[d]) + "°"
                })
            }
            root.dailyData = tempDaily
            
            updateAstroData()
            hourlyCanvas.requestPaint()
        })
    }

    function updateAstroData() {
        if(root.latitude === 0 && root.longitude === 0) return;
        var pos = AstroJS.getSunPosition(new Date(), root.latitude, root.longitude);
        root.sunAzimuth = pos.az;
        root.sunAltitude = pos.alt;
        skyCanvas.requestPaint();
    }

    Timer { interval: 60000; running: true; repeat: true; onTriggered: updateAstroData() }
    Timer { interval: 1800000; running: true; repeat: true; onTriggered: fetchData() }

    // ==========================================
    // 布局设计
    // ==========================================
    
    // 1. 左上：综合天气信息
    Item {
        id: infoSection
        width: 220
        height: 220
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 25
        
        Column {
            spacing: 8
            
            Row {
                spacing: 8
                Text {
                    text: root.locationName 
                    font.family: Sizes.fontFamily
                    font.pixelSize: 15; font.bold: true; font.letterSpacing: 2
                    color: Colorscheme.on_surface_variant
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                // 刷新按钮组件
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: refreshMouseArea.pressed ? Colorscheme.surface_variant : "transparent"
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Text {
                        id: refreshIcon
                        anchors.centerIn: parent
                        text: "refresh"
                        font.family: root.materialFont
                        font.pixelSize: 16
                        color: refreshMouseArea.containsMouse ? Colorscheme.primary : Colorscheme.on_surface_variant
                        
                        // 1. 无限循环的转圈动画
                        NumberAnimation {
                            id: spinAnim
                            target: refreshIcon
                            property: "rotation"
                            from: 0; to: 360
                            duration: 800
                            loops: Animation.Infinite
                        }

                        // 2. 抄近道顺滑归位动画 (利用 RotationAnimation.Shortest 算法)
                        RotationAnimation {
                            id: resetAnim
                            target: refreshIcon
                            property: "rotation"
                            to: 0
                            duration: 300
                            direction: RotationAnimation.Shortest
                        }
                    }
                    
                    MouseArea {
                        id: refreshMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (!spinAnim.running) {
                                resetAnim.stop() // 打断可能正在进行的归位
                                refreshIcon.rotation = 0 // 重置起始点
                                spinAnim.start()
                                forceStopTimer.restart() // 启动 5 秒强制打断定时器
                                fetchData()
                            }
                        }
                    }
                }
            }
            
            Row {
                spacing: 12
                Text { 
                    text: root.currentIcon; font.family: root.materialFont; 
                    font.pixelSize: 56; color: Colorscheme.primary 
                }
                Text { 
                    text: root.currentTemp; font.family: Sizes.fontFamilyMono; 
                    font.pixelSize: 56; font.bold: true; color: Colorscheme.on_surface 
                }
            }
            Text { text: root.currentDesc; font.family: Sizes.fontFamily; font.pixelSize: 18; font.bold: true; color: Colorscheme.on_surface }
            
            Item { height: 10; width: 1 } 
            
            Grid {
                columns: 2
                spacing: 12
                columnSpacing: 24
                
                Row { spacing: 6; Text { text: "thermometer"; font.family: root.materialFont; color: Colorscheme.on_surface_variant; font.pixelSize: 15 } Text { text: root.feelsLike; color: Colorscheme.on_surface_variant; font.family: Sizes.fontFamilyMono; font.pixelSize: 13 } }
                Row { spacing: 6; Text { text: "water_drop"; font.family: root.materialFont; color: Colorscheme.on_surface_variant; font.pixelSize: 15 } Text { text: root.humidity; color: Colorscheme.on_surface_variant; font.family: Sizes.fontFamilyMono; font.pixelSize: 13 } }
                Row { spacing: 6; Text { text: "air"; font.family: root.materialFont; color: Colorscheme.on_surface_variant; font.pixelSize: 15 } Text { text: root.windSpeed; color: Colorscheme.on_surface_variant; font.family: Sizes.fontFamilyMono; font.pixelSize: 13 } }
                Row { spacing: 6; Text { text: "compress"; font.family: root.materialFont; color: Colorscheme.on_surface_variant; font.pixelSize: 15 } Text { text: root.pressure; color: Colorscheme.on_surface_variant; font.family: Sizes.fontFamilyMono; font.pixelSize: 13 } }
            }
        }
    }

    // 2. 左侧下方：完美的 Material 3 分段形变按钮
    Item {
        id: segmentedContainer
        width: 200
        height: 40
        anchors.top: infoSection.bottom
        anchors.left: parent.left
        anchors.margins: 25

        Row {
            anchors.fill: parent
            spacing: 4 

            Rectangle {
                width: (parent.width - parent.spacing) / 2; height: parent.height
                color: root.isHourly ? Colorscheme.primary : Colorscheme.surface_variant
                
                topLeftRadius: 20; bottomLeftRadius: 20
                topRightRadius: root.isHourly ? 20 : 0
                bottomRightRadius: root.isHourly ? 20 : 0
                
                Behavior on topRightRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on bottomRightRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "check"; font.family: root.materialFont; font.pixelSize: 14; color: Colorscheme.on_primary; visible: root.isHourly }
                    Text { text: "12 Hrs"; font.family: Sizes.fontFamily; font.bold: true; font.pixelSize: 13; color: root.isHourly ? Colorscheme.on_primary : Colorscheme.on_surface_variant }
                }
                MouseArea { anchors.fill: parent; onClicked: root.isHourly = true }
            }

            Rectangle {
                width: (parent.width - parent.spacing) / 2; height: parent.height
                color: !root.isHourly ? Colorscheme.primary : Colorscheme.surface_variant
                
                topRightRadius: 20; bottomRightRadius: 20
                topLeftRadius: !root.isHourly ? 20 : 0
                bottomLeftRadius: !root.isHourly ? 20 : 0
                
                Behavior on topLeftRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on bottomLeftRadius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "check"; font.family: root.materialFont; font.pixelSize: 14; color: Colorscheme.on_primary; visible: !root.isHourly }
                    Text { text: "7 Days"; font.family: Sizes.fontFamily; font.bold: true; font.pixelSize: 13; color: !root.isHourly ? Colorscheme.on_primary : Colorscheme.on_surface_variant }
                }
                MouseArea { anchors.fill: parent; onClicked: root.isHourly = false }
            }
        }
    }

    // 3. 右半场：天穹图
    Item {
        id: astroArea
        anchors.top: parent.top
        anchors.bottom: forecastCard.top
        anchors.left: infoSection.right
        anchors.right: parent.right
        anchors.margins: 10
        
        Canvas {
            id: skyCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                if(root.latitude === 0) return;
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = width / 2;
                var cy = height / 2;
                var R = 135; 

                function project(az, alt) {
                    var r = R * (1 - alt / (Math.PI / 2));
                    return {x: cx + r * Math.sin(az), y: cy - r * Math.cos(az)};
                }

                ctx.lineWidth = 1.5;
                ctx.strokeStyle = Colorscheme.outline_variant; 
                
                [0, 30, 60].forEach(function(deg) {
                    ctx.beginPath();
                    ctx.arc(cx, cy, R * (1 - deg / 90), 0, Math.PI * 2);
                    ctx.stroke();
                    if(deg > 0) {
                        ctx.fillStyle = Colorscheme.on_surface_variant;
                        ctx.font = "11px '" + Sizes.fontFamilyMono + "'";
                        ctx.fillText(deg + "°", cx + 4, cy - R * (1 - deg / 90) - 4);
                    }
                });
                
                ctx.beginPath();
                ctx.moveTo(cx, cy - R); ctx.lineTo(cx, cy + R);
                ctx.moveTo(cx - R, cy); ctx.lineTo(cx + R, cy);
                ctx.stroke();

                var y = new Date().getFullYear();
                var terms = [
                    { date: new Date(y, 5, 21), color: "rgba(239, 68, 68, 0.6)" }, 
                    { date: new Date(y, 2, 21), color: "rgba(34, 197, 94, 0.6)" }, 
                    { date: new Date(y, 11, 21), color: "rgba(56, 189, 248, 0.6)" }
                ];
                
                ctx.setLineDash([4, 6]);
                ctx.lineWidth = 1.5;
                for(var j=0; j<terms.length; j++) {
                    ctx.strokeStyle = terms[j].color;
                    ctx.beginPath();
                    var isFirstRef = true;
                    for (var min = 0; min <= 24 * 60; min += 20) {
                        var t = new Date(terms[j].date.getTime() + min * 60000);
                        var pos = AstroJS.getSunPosition(t, root.latitude, root.longitude);
                        if (pos.alt >= 0) {
                            var pt = project(pos.az, pos.alt);
                            if (isFirstRef) { ctx.moveTo(pt.x, pt.y); isFirstRef = false; } 
                            else { ctx.lineTo(pt.x, pt.y); }
                        } else {
                            isFirstRef = true; 
                        }
                    }
                    ctx.stroke();
                }
                ctx.setLineDash([]);

                var startOfDay = new Date(); startOfDay.setHours(0,0,0,0);
                
                ctx.beginPath();
                ctx.lineWidth = 1.5;
                ctx.strokeStyle = "rgba(226, 232, 240, 0.4)"; 
                ctx.setLineDash([5, 5]); 
                var isFirstMoon = true;
                for (var mm = 0; mm <= 24 * 60; mm += 15) {
                    var tMoon = new Date(startOfDay.getTime() + mm * 60000);
                    var pMoon = AstroJS.getMoonPosition(tMoon, root.latitude, root.longitude);
                    if (pMoon.alt >= 0) {
                        var ptM = project(pMoon.az, pMoon.alt);
                        if (isFirstMoon) { ctx.moveTo(ptM.x, ptM.y); isFirstMoon = false; } 
                        else { ctx.lineTo(ptM.x, ptM.y); }
                    } else { 
                        isFirstMoon = true; 
                    } 
                }
                ctx.stroke();
                ctx.setLineDash([]);

                ctx.beginPath();
                ctx.lineWidth = 2.5;
                ctx.strokeStyle = "#fbbf24"; 
                ctx.setLineDash([6, 6]); 
                var isFirstDay = true;
                for (var md = 0; md <= 24 * 60; md += 10) {
                    var td = new Date(startOfDay.getTime() + md * 60000);
                    var pd = AstroJS.getSunPosition(td, root.latitude, root.longitude);
                    if (pd.alt >= 0) {
                        var pttd = project(pd.az, pd.alt);
                        if (isFirstDay) { ctx.moveTo(pttd.x, pttd.y); isFirstDay = false; } 
                        else { ctx.lineTo(pttd.x, pttd.y); }
                    } else { 
                        isFirstDay = true; 
                    }
                }
                ctx.stroke();
                ctx.setLineDash([]);

                var posMoonNow = AstroJS.getMoonPosition(new Date(), root.latitude, root.longitude);
                if (posMoonNow.alt >= 0) {
                    var ptMNow = project(posMoonNow.az, posMoonNow.alt);
                    ctx.beginPath();
                    ctx.arc(ptMNow.x, ptMNow.y, 4, 0, Math.PI*2);
                    ctx.fillStyle = "#f8fafc"; 
                    ctx.fill();
                }

                if (root.sunAltitude >= 0) {
                    var currentPt = project(root.sunAzimuth, root.sunAltitude);
                    
                    var glowRadius = 22; 
                    var gradient = ctx.createRadialGradient(currentPt.x, currentPt.y, 4, currentPt.x, currentPt.y, glowRadius);
                    
                    gradient.addColorStop(0, "rgba(253, 224, 71, 0.8)");   
                    gradient.addColorStop(0.4, "rgba(253, 224, 71, 0.3)"); 
                    gradient.addColorStop(1, "rgba(253, 224, 71, 0.0)");   

                    ctx.beginPath(); 
                    ctx.arc(currentPt.x, currentPt.y, glowRadius, 0, Math.PI*2);
                    ctx.fillStyle = gradient; 
                    ctx.fill();
                    
                    ctx.beginPath(); 
                    ctx.arc(currentPt.x, currentPt.y, 5, 0, Math.PI*2);
                    ctx.fillStyle = "#ffffff";
                    ctx.fill();
                } 
                
                ctx.fillStyle = Colorscheme.on_surface;
                ctx.font = "bold 16px '" + Sizes.fontFamilyMono + "'";
                ctx.textAlign = "center"; ctx.textBaseline = "middle";
                ctx.fillText("N", cx, cy - R - 20);
                ctx.fillText("E", cx + R + 22, cy);
                ctx.fillText("S", cx, cy + R + 20);
                ctx.fillText("W", cx - R - 22, cy);
            }
        }
    }

    // 4. 下方：天气预报长卡片
    Rectangle {
        id: forecastCard
        height: 200
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 15
        color: Colorscheme.surface_container
        radius: Sizes.lockCardRadius

        Item {
            anchors.fill: parent
            anchors.margins: 20

            // 12 小时折线图
            Canvas {
                id: hourlyCanvas
                anchors.fill: parent
                renderTarget: Canvas.FramebufferObject
                opacity: root.isHourly ? 1.0 : 0.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutSine } }

                onPaint: {
                    if (!root.hourlyData || root.hourlyData.length === 0) return;
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    var minTemp = 999, maxTemp = -999;
                    for (var i = 0; i < root.hourlyData.length; i++) {
                        var t = root.hourlyData[i].temp;
                        if (t < minTemp) minTemp = t;
                        if (t > maxTemp) maxTemp = t;
                    }
                    if (maxTemp - minTemp < 4) { maxTemp += 2; minTemp -= 2; }

                    var points = [];
                    var padTop = 65, padBottom = 20; 
                    var padSide = 35; 
                    var drawHeight = height - padTop - padBottom;
                    var drawWidth = width - padSide * 2;
                    var stepX = drawWidth / (root.hourlyData.length - 1);

                    for (var j = 0; j < root.hourlyData.length; j++) {
                        var normalized = (root.hourlyData[j].temp - minTemp) / (maxTemp - minTemp);
                        points.push({ 
                            x: padSide + j * stepX, 
                            y: padTop + (1 - normalized) * drawHeight, 
                            data: root.hourlyData[j] 
                        });
                    }

                    ctx.beginPath();
                    ctx.moveTo(points[0].x, points[0].y);
                    for (var k = 1; k < points.length; k++) { ctx.lineTo(points[k].x, points[k].y); }
                    ctx.lineWidth = 2.5;
                    ctx.strokeStyle = Colorscheme.primary; 
                    ctx.stroke();

                    ctx.textAlign = "center";
                    for (var p = 0; p < points.length; p++) {
                        var pt = points[p];
                        ctx.beginPath();
                        ctx.arc(pt.x, pt.y, 4, 0, Math.PI * 2);
                        ctx.fillStyle = Colorscheme.surface_container; ctx.fill();
                        ctx.lineWidth = 2; ctx.strokeStyle = Colorscheme.primary; ctx.stroke();
                        
                        ctx.fillStyle = Colorscheme.on_surface;
                        ctx.font = "18px '" + root.materialFont + "'";
                        ctx.fillText(pt.data.icon, pt.x, pt.y - 22);
                        
                        ctx.font = "bold 13px '" + Sizes.fontFamilyMono + "'";
                        ctx.fillText(pt.data.temp + "°", pt.x, pt.y - 44);
                        
                        ctx.fillStyle = Colorscheme.on_surface_variant;
                        ctx.font = "12px '" + Sizes.fontFamily + "'";
                        ctx.fillText(pt.data.time, pt.x, height - 2);
                    }
                }
            }

            // 7 天排版
            Row {
                anchors.centerIn: parent
                spacing: 10
                opacity: root.isHourly ? 0.0 : 1.0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutSine } }

                Repeater {
                    model: root.dailyData
                    Rectangle {
                        width: 82; height: 140; radius: 16
                        color: Colorscheme.surface_container_highest
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 12
                            Text { text: modelData.day; color: Colorscheme.on_surface_variant; font.family: Sizes.fontFamily; font.pixelSize: 14; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: modelData.icon; color: Colorscheme.primary; font.family: root.materialFont; font.pixelSize: 32; anchors.horizontalCenter: parent.horizontalCenter }
                            Column {
                                spacing: 2; anchors.horizontalCenter: parent.horizontalCenter
                                Text { text: modelData.maxTemp; color: Colorscheme.on_surface; font.family: Sizes.fontFamilyMono; font.pixelSize: 16; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: modelData.minTemp; color: Colorscheme.on_surface_variant; font.family: Sizes.fontFamilyMono; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }
                }
            }
        }
    }
}

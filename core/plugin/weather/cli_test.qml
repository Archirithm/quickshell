import QtQuick
import Clavis.Weather 1.0

Item {
    Component.onCompleted: {
        console.log("Clavis.Weather loaded")
        console.log("Status:", WeatherPlugin.status, "loading:", WeatherPlugin.loading)
        console.log("Location:", WeatherPlugin.locationName, WeatherPlugin.latitude, WeatherPlugin.longitude)
        console.log("Current:", WeatherPlugin.currentTemperatureC, WeatherPlugin.currentWeatherText)
        console.log("Hourly count:", WeatherPlugin.hourlyForecast.count())
        console.log("Daily count:", WeatherPlugin.dailyForecast.count())
        WeatherPlugin.refresh()
    }

    Connections {
        target: WeatherPlugin
        function onDataChanged() {
            console.log("Weather update:", WeatherPlugin.status, WeatherPlugin.locationName, WeatherPlugin.currentTemperatureC, WeatherPlugin.currentWeatherText)
            console.log("Hourly:", WeatherPlugin.hourlyForecast.count(), "Daily:", WeatherPlugin.dailyForecast.count())
            Qt.quit()
        }
    }
}

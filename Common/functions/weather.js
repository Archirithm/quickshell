.pragma library

function fetchLocationAndWeather(callback) {
    var locXhr = new XMLHttpRequest();
    locXhr.timeout = 5000; // 强制 5 秒超时设置

    locXhr.onreadystatechange = function() {
        if (locXhr.readyState === XMLHttpRequest.DONE) {
            if (locXhr.status === 200) {
                try {
                    var locData = JSON.parse(locXhr.responseText);
                    if (locData.success === false) {
                        callback(null); // API 报错，返回 null
                        return;
                    }

                    var lat = locData.latitude;
                    var lon = locData.longitude;
                    var cityStr = locData.city;
                    if (!cityStr || cityStr.trim() === "") cityStr = locData.region;
                    if (!cityStr || cityStr.trim() === "") cityStr = locData.country;
                    if (!cityStr || cityStr.trim() === "") cityStr = "UNKNOWN";

                    fetchWeatherAPI(lat, lon, cityStr.toUpperCase(), callback);
                } catch(e) {
                    console.log("Location Parse Error:", e);
                    callback(null); // 解析失败，返回 null
                }
            } else {
                console.log("Location Network Error:", locXhr.status);
                callback(null); // 状态码非 200，返回 null
            }
        }
    }
    
    // 捕获底层网络断开和超时
    locXhr.onerror = function() { console.log("Location XHR Error"); callback(null); }
    locXhr.ontimeout = function() { console.log("Location XHR Timeout"); callback(null); }

    locXhr.open("GET", "https://ipwho.is/?t=" + new Date().getTime(), true);
    locXhr.send();
}

function fetchWeatherAPI(lat, lon, city, callback) {
    var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + 
              "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,surface_pressure" + 
              "&hourly=temperature_2m,weather_code" + 
              "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto";
              
    var xhr = new XMLHttpRequest();
    xhr.timeout = 5000; // 天气请求同样增加 5 秒超时

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                var data = JSON.parse(xhr.responseText);
                data.locName = city;
                data.lat = lat;
                data.lon = lon;
                callback(data);
            } else {
                console.log("Weather API Network Error:", xhr.status);
                callback(null);
            }
        }
    }
    
    // 捕获天气接口的网络异常
    xhr.onerror = function() { console.log("Weather XHR Error"); callback(null); }
    xhr.ontimeout = function() { console.log("Weather XHR Timeout"); callback(null); }

    xhr.open("GET", url, true);
    xhr.send();
}

function getMaterialIcon(code) {
    if (code === 0) return "sunny";
    if (code === 1 || code === 2) return "partly_cloudy_day";
    if (code === 3) return "cloudy";
    if (code === 45 || code === 48) return "foggy";
    if (code >= 51 && code <= 67) return "rainy";
    if (code >= 71 && code <= 82) return "snowing";
    if (code >= 95) return "thunderstorm";
    return "cloud";
}

function getWeatherDesc(code) {
    var mapping = {
        0: "Clear", 1: "Mainly Clear", 2: "Partly Cloudy", 3: "Overcast",
        45: "Fog", 48: "Rime Fog", 51: "Drizzle", 61: "Rain", 71: "Snow", 95: "Storm"
    };
    return mapping[code] || "Cloudy";
}

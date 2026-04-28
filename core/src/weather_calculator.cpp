#include "weather_calculator.h"

#include <QtMath>

QString WeatherCalculator::weatherText(int code) {
    switch (code) {
    case 0: return "Clear";
    case 1: return "Mainly clear";
    case 2: return "Partly cloudy";
    case 3: return "Overcast";
    case 45: return "Fog";
    case 48: return "Rime fog";
    case 51:
    case 53:
    case 55: return "Drizzle";
    case 56:
    case 57: return "Freezing drizzle";
    case 61:
    case 63:
    case 65: return "Rain";
    case 66:
    case 67: return "Freezing rain";
    case 71:
    case 73:
    case 75: return "Snow";
    case 77: return "Snow grains";
    case 80:
    case 81:
    case 82: return "Showers";
    case 85:
    case 86: return "Snow showers";
    case 95: return "Thunderstorm";
    case 96:
    case 99: return "Thunderstorm with hail";
    default: return "Unknown";
    }
}

QString WeatherCalculator::iconName(int code) {
    if (code == 0) return "sunny";
    if (code == 1 || code == 2) return "partly_cloudy_day";
    if (code == 3) return "cloud";
    if (code == 45 || code == 48) return "foggy";
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "rainy";
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) return "weather_snowy";
    if (code >= 95) return "thunderstorm";
    return "cloud";
}

QVariantMap WeatherCalculator::completeCurrent(const QVariantMap &initial, const QVariantMap &hourly, const QVariantMap &daily) {
    QVariantMap current = initial;
    const int code = current.value("weatherCode", hourly.value("weatherCode", -1)).toInt();
    current["weatherCode"] = code;
    current["weatherText"] = current.value("weatherText", weatherText(code)).toString();
    current["iconName"] = current.value("iconName", iconName(code)).toString();

    const double temp = current.value("temperatureC", hourly.value("temperatureC")).toDouble();
    const double humidity = current.value("relativeHumidity", hourly.value("relativeHumidity", -1)).toDouble();
    const double wind = current.value("windSpeedMs", hourly.value("windSpeedMs", -1)).toDouble();
    const double dew = current.value("dewPointC", hourly.value("dewPointC", qQNaN())).toDouble();
    current["temperatureC"] = temp;
    if (!current.contains("sourceFeelsLikeC") || current.value("sourceFeelsLikeC").isNull()) {
        current["computedApparentC"] = apparentTemperature(temp, humidity, wind);
        current["computedWindChillC"] = windChill(temp, wind);
        current["computedHumidexC"] = humidex(temp, dew);
        current["feelsLikeC"] = current.value("computedApparentC");
    } else {
        current["feelsLikeC"] = current.value("sourceFeelsLikeC");
    }
    current["sunrise"] = daily.value("sunrise");
    current["sunset"] = daily.value("sunset");
    return current;
}

QList<QVariantMap> WeatherCalculator::completeDaily(QList<QVariantMap> daily, const QList<QVariantMap> &hourly, double latitude, double longitude) {
    for (auto &day : daily) {
        const QDate date = QDate::fromString(day.value("date").toString(), Qt::ISODate);
        QList<QVariantMap> itemsForDate;
        for (const auto &hour : hourly) {
            const QDateTime dt = QDateTime::fromSecsSinceEpoch(hour.value("time").toLongLong());
            if (dt.date() == date) itemsForDate.append(hour);
        }

        day["day"] = aggregateHalfDay(itemsForDate, true);
        day["night"] = aggregateHalfDay(itemsForDate, false);
        const QVariantMap astro = astroForDate(date, latitude, longitude);
        for (auto it = astro.cbegin(); it != astro.cend(); ++it) day[it.key()] = it.value();
        day["moonPhaseAngle"] = moonPhaseAngle(date);
    }
    return daily;
}

QVariantMap WeatherCalculator::aggregateHalfDay(const QList<QVariantMap> &items, bool day) {
    QVariantMap out;
    QList<QVariantMap> slice;
    for (const auto &item : items) {
        const int hour = QDateTime::fromSecsSinceEpoch(item.value("time").toLongLong()).time().hour();
        const bool isDayHalf = hour >= 6 && hour < 18;
        if (isDayHalf == day) slice.append(item);
    }
    if (slice.isEmpty()) return out;

    double temp = day ? -999.0 : 999.0;
    double feels = day ? -999.0 : 999.0;
    double precip = 0.0;
    double rain = 0.0;
    double snow = 0.0;
    double wind = 0.0;
    double gusts = 0.0;
    double windDirection = qQNaN();
    double pop = 0.0;
    int code = slice.first().value("weatherCode", -1).toInt();

    for (const auto &item : slice) {
        const double t = item.value("temperatureC").toDouble();
        const double f = item.value("feelsLikeC", item.value("sourceFeelsLikeC")).toDouble();
        const double itemWind = item.value("windSpeedMs").toDouble();
        temp = day ? qMax(temp, t) : qMin(temp, t);
        feels = day ? qMax(feels, f) : qMin(feels, f);
        precip += item.value("precipitationMm").toDouble();
        rain += item.value("rainMm").toDouble();
        snow += item.value("snowCm").toDouble();
        if (itemWind >= wind) {
            wind = itemWind;
            bool dirOk = false;
            const double direction = item.value("windDirection").toDouble(&dirOk);
            if (dirOk) windDirection = direction;
        }
        gusts = qMax(gusts, item.value("windGustsMs").toDouble());
        pop = qMax(pop, item.value("precipitationProbability").toDouble());
        const int itemCode = item.value("weatherCode", -1).toInt();
        if (itemCode >= 95 || (itemCode >= 61 && itemCode <= 86)) code = itemCode;
    }

    out["temperatureC"] = temp;
    out["feelsLikeC"] = feels;
    out["precipitationMm"] = precip;
    out["rainMm"] = rain;
    out["snowCm"] = snow;
    out["precipitationProbability"] = pop;
    out["windSpeedMs"] = wind;
    out["windDirection"] = windDirection;
    out["windGustsMs"] = gusts;
    out["weatherCode"] = code;
    out["weatherText"] = weatherText(code);
    out["iconName"] = iconName(code);
    return out;
}

QVariantMap WeatherCalculator::astroForDate(const QDate &date, double latitude, double longitude) {
    Q_UNUSED(longitude)
    const int dayOfYear = date.dayOfYear();
    const double lat = qDegreesToRadians(latitude);
    const double decl = qDegreesToRadians(23.44) * qSin(qDegreesToRadians(360.0 / 365.0 * (dayOfYear - 81)));
    const double cosHourAngle = (qSin(qDegreesToRadians(-0.833)) - qSin(lat) * qSin(decl)) / (qCos(lat) * qCos(decl));

    double daylightHours = 12.0;
    if (cosHourAngle <= -1.0) daylightHours = 24.0;
    else if (cosHourAngle >= 1.0) daylightHours = 0.0;
    else daylightHours = 2.0 * qRadiansToDegrees(qAcos(cosHourAngle)) / 15.0;

    const double sunriseHour = 12.0 - daylightHours / 2.0;
    const double sunsetHour = 12.0 + daylightHours / 2.0;
    const int sunriseMinutes = qBound(0, qRound(sunriseHour * 60.0), 24 * 60 - 1);
    const int sunsetMinutes = qBound(0, qRound(sunsetHour * 60.0), 24 * 60 - 1);
    const int phase = moonPhaseAngle(date);
    const int moonriseMinutes = (sunriseMinutes + qRound(phase / 360.0 * 24.0 * 60.0)) % (24 * 60);
    const int moonsetMinutes = (moonriseMinutes + 12 * 60) % (24 * 60);

    QVariantMap out;
    out["sunrise"] = QDateTime(date, QTime(sunriseMinutes / 60, sunriseMinutes % 60)).toSecsSinceEpoch();
    out["sunset"] = QDateTime(date, QTime(sunsetMinutes / 60, sunsetMinutes % 60)).toSecsSinceEpoch();
    out["dawn"] = QDateTime(date, QTime(qMax(0, sunriseMinutes - 35) / 60, qMax(0, sunriseMinutes - 35) % 60)).toSecsSinceEpoch();
    out["dusk"] = QDateTime(date, QTime(qMin(24 * 60 - 1, sunsetMinutes + 35) / 60, qMin(24 * 60 - 1, sunsetMinutes + 35) % 60)).toSecsSinceEpoch();
    out["moonrise"] = QDateTime(date, QTime(moonriseMinutes / 60, moonriseMinutes % 60)).toSecsSinceEpoch();
    out["moonset"] = QDateTime(date, QTime(moonsetMinutes / 60, moonsetMinutes % 60)).toSecsSinceEpoch();
    return out;
}

int WeatherCalculator::moonPhaseAngle(const QDate &date) {
    const QDate knownNewMoon(2000, 1, 6);
    const double lunations = knownNewMoon.daysTo(date) / 29.53058867;
    const double fraction = lunations - qFloor(lunations);
    return qRound(fraction * 360.0);
}

double WeatherCalculator::apparentTemperature(double celsius, double humidity, double windMs) {
    if (qIsNaN(celsius)) return qQNaN();
    if (humidity < 0 || windMs < 0) return qQNaN();
    const double vaporPressure = humidity / 100.0 * 6.105 * qExp(17.27 * celsius / (237.7 + celsius));
    return celsius + 0.33 * vaporPressure - 0.70 * windMs - 4.0;
}

double WeatherCalculator::windChill(double celsius, double windMs) {
    if (qIsNaN(celsius) || windMs < 1.34 || celsius > 10.0) return qQNaN();
    const double windKmh = windMs * 3.6;
    return 13.12 + 0.6215 * celsius - 11.37 * qPow(windKmh, 0.16) + 0.3965 * celsius * qPow(windKmh, 0.16);
}

double WeatherCalculator::humidex(double celsius, double dewPoint) {
    if (qIsNaN(celsius) || qIsNaN(dewPoint)) return qQNaN();
    const double e = 6.11 * qExp(5417.7530 * (1.0 / 273.16 - 1.0 / (273.15 + dewPoint)));
    return celsius + 0.5555 * (e - 10.0);
}

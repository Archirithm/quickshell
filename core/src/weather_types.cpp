#include "weather_types.h"

QVariantMap WeatherSnapshot::toVariantMap() const {
    QVariantMap map;
    QVariantList hourlyList;
    QVariantList dailyList;
    QVariantList dailyTrendList;
    QVariantList minutelyList;
    for (const auto &item : hourly) hourlyList.append(item);
    for (const auto &item : daily) dailyList.append(item);
    for (const auto &item : dailyTrend) dailyTrendList.append(item);
    for (const auto &item : minutely) minutelyList.append(item);

    map["valid"] = valid;
    map["status"] = status;
    map["errorMessage"] = errorMessage;
    map["locationName"] = locationName;
    map["latitude"] = latitude;
    map["longitude"] = longitude;
    map["lastUpdated"] = lastUpdated.toString(Qt::ISODate);
    map["nextRefreshAt"] = nextRefreshAt.toString(Qt::ISODate);
    map["current"] = current;
    map["hourly"] = hourlyList;
    map["daily"] = dailyList;
    map["dailyTrend"] = dailyTrendList;
    map["minutely"] = minutelyList;
    return map;
}

WeatherSnapshot WeatherSnapshot::fromVariantMap(const QVariantMap &map) {
    WeatherSnapshot snapshot;
    snapshot.valid = map.value("valid").toBool();
    snapshot.status = map.value("status", "cache").toString();
    snapshot.errorMessage = map.value("errorMessage").toString();
    snapshot.locationName = map.value("locationName").toString();
    snapshot.latitude = map.value("latitude").toDouble();
    snapshot.longitude = map.value("longitude").toDouble();
    snapshot.lastUpdated = QDateTime::fromString(map.value("lastUpdated").toString(), Qt::ISODate);
    snapshot.nextRefreshAt = QDateTime::fromString(map.value("nextRefreshAt").toString(), Qt::ISODate);
    snapshot.current = map.value("current").toMap();

    for (const auto &value : map.value("hourly").toList()) snapshot.hourly.append(value.toMap());
    for (const auto &value : map.value("daily").toList()) snapshot.daily.append(value.toMap());
    for (const auto &value : map.value("dailyTrend").toList()) snapshot.dailyTrend.append(value.toMap());
    for (const auto &value : map.value("minutely").toList()) snapshot.minutely.append(value.toMap());
    return snapshot;
}

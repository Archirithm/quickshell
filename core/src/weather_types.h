#pragma once

#include <QDateTime>
#include <QList>
#include <QVariantMap>

struct WeatherSnapshot {
    bool valid = false;
    QString status = "idle";
    QString errorMessage;
    QString locationName;
    double latitude = 0.0;
    double longitude = 0.0;
    QDateTime lastUpdated;
    QDateTime nextRefreshAt;
    QVariantMap current;
    QList<QVariantMap> hourly;
    QList<QVariantMap> daily;
    QList<QVariantMap> dailyTrend;
    QList<QVariantMap> minutely;

    QVariantMap toVariantMap() const;
    static WeatherSnapshot fromVariantMap(const QVariantMap &map);
};

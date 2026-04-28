#pragma once

#include <QDate>
#include <QList>
#include <QTimeZone>
#include <QVariantMap>

class WeatherCalculator {
public:
    static QString weatherText(int code);
    static QString iconName(int code);
    static QVariantMap completeCurrent(const QVariantMap &initial, const QVariantMap &hourly, const QVariantMap &daily);
    static QList<QVariantMap> completeDaily(QList<QVariantMap> daily, const QList<QVariantMap> &hourly, double latitude, double longitude);
    static QVariantMap astroForDate(const QDate &date, double latitude, double longitude);
    static int moonPhaseAngle(const QDate &date);

private:
    static QVariantMap aggregateHalfDay(const QList<QVariantMap> &items, bool day);
    static double apparentTemperature(double celsius, double humidity, double windMs);
    static double windChill(double celsius, double windMs);
    static double humidex(double celsius, double dewPoint);
    static QDateTime dateAtHour(const QDate &date, int hour);
};

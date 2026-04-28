#pragma once

#include "weather_types.h"

#include <QString>

class WeatherCache {
public:
    static WeatherSnapshot load(const QString &path);
    static bool save(const QString &path, const WeatherSnapshot &snapshot);
    static QString defaultPath();
};

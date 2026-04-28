#pragma once
#include <QString>

class SysmonTemp {
public:
    SysmonTemp();
    ~SysmonTemp() = default;

    void update();
    double getCoreTempCelsius() const;

private:
    QString m_sensorPath;
    double m_coreTempCelsius = 0.0;
    
    QString findSensorPath() const;
};

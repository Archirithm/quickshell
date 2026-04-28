#pragma once
#include <QString>

class SysmonBattery {
public:
    SysmonBattery();
    ~SysmonBattery() = default;

    void update();
    
    double getPercent() const;
    QString getStatus() const;
    int getHealthPercent() const;
    double getPowerWatts() const;
    bool isPresent() const;

private:
    QString m_batPath;
    bool m_present;
    double m_percent;
    QString m_status;
    int m_healthPercent;
    double m_powerWatts;
    
    QString findBatPath() const;
    long long readSysFile(const QString &name) const;
    QString readSysString(const QString &name) const;
};

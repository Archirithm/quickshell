#pragma once
#include <QString>

class SysmonMisc {
public:
    SysmonMisc();
    ~SysmonMisc() = default;

    void update();
    
    int getFanRpm() const;
    double getCpuFreqGHz() const;
    QString getUptime() const;

private:
    QString m_fanPath;
    int m_fanRpm;
    double m_cpuFreqGHz;
    QString m_uptime;
    
    QString findFanPath() const;
};

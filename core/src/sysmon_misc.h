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
    QString getSystemUser() const;
    QString getHostName() const;
    QString getWmName() const;
    QString getKernelRelease() const;
    QString getShellName() const;
    QString getDistroId() const;
    QString getDistroName() const;
    QString getChassis() const;
    QString getOsAgeText() const;

private:
    QString m_fanPath;
    int m_fanRpm;
    double m_cpuFreqGHz;
    QString m_uptime;
    QString m_systemUser;
    QString m_hostName;
    QString m_wmName;
    QString m_kernelRelease;
    QString m_shellName;
    QString m_distroId;
    QString m_distroName;
    QString m_chassis;
    QString m_osAgeText;
    
    QString findFanPath() const;
    void loadStaticInfo();
    QString readFirstLine(const QString& path, const QString& fallback = QString()) const;
    QString osReleaseValue(const QString& key, const QString& fallback = QString()) const;
    QString detectChassis() const;
    QString detectOsAge() const;
};

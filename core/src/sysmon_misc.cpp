#include "sysmon_misc.h"
#include <QFile>
#include <QDebug>
#include <filesystem>

namespace fs = std::filesystem;

SysmonMisc::SysmonMisc() : m_fanRpm(0), m_cpuFreqGHz(0.0) {
    m_fanPath = findFanPath();
    if (!m_fanPath.isEmpty())
        qDebug() << "[SysmonMisc] Fan sensor path:" << m_fanPath;
}

QString SysmonMisc::findFanPath() const {
    std::error_code ec;
    for (const auto &entry : fs::directory_iterator("/sys/class/hwmon", ec)) {
        if (!entry.is_directory(ec) && !entry.is_symlink(ec)) continue;
        
        QString hwmonPath = QString::fromStdString(entry.path().string());
        QString candidate = hwmonPath + "/fan1_input";
        if (QFile::exists(candidate)) return candidate;
    }
    return QString();
}

int SysmonMisc::getFanRpm() const { return m_fanRpm; }
double SysmonMisc::getCpuFreqGHz() const { return m_cpuFreqGHz; }
QString SysmonMisc::getUptime() const { return m_uptime; }

void SysmonMisc::update() {
    // 风扇转速
    if (!m_fanPath.isEmpty()) {
        QFile file(m_fanPath);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            bool ok;
            int val = QString::fromUtf8(file.readAll()).trimmed().toInt(&ok);
            if (ok) m_fanRpm = val;
        }
    }
    
    // CPU 频率: /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq (kHz)
    {
        QFile file("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq");
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            bool ok;
            long kHz = QString::fromUtf8(file.readAll()).trimmed().toLong(&ok);
            if (ok) m_cpuFreqGHz = static_cast<double>(kHz) / 1000000.0;
        }
    }
    
    // Uptime
    {
        QFile file("/proc/uptime");
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString line = QString::fromUtf8(file.readAll()).trimmed();
            bool ok;
            double totalSeconds = line.split(' ').first().toDouble(&ok);
            if (ok) {
                int secs = static_cast<int>(totalSeconds);
                int days  = secs / 86400;
                int hours = (secs % 86400) / 3600;
                int mins  = (secs % 3600) / 60;
                
                if (days > 0)
                    m_uptime = QString("%1d %2h").arg(days).arg(hours);
                else if (hours > 0)
                    m_uptime = QString("%1h %2m").arg(hours).arg(mins);
                else
                    m_uptime = QString("%1m").arg(mins);
            }
        }
    }
}

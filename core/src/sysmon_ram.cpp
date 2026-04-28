#include "sysmon_ram.h"
#include <QFile>
#include <QStringList>

SysmonRam::SysmonRam() : m_totalMemKB(1), m_memUsagePercent(0.0), m_usedMemGB(0.0) {
    update();
}

unsigned long long SysmonRam::getTotalMemKB() const { return m_totalMemKB; }
double SysmonRam::getMemUsagePercent() const { return m_memUsagePercent; }
double SysmonRam::getUsedMemGB() const { return m_usedMemGB; }

void SysmonRam::update() {
    QFile file("/proc/meminfo");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;

    QByteArray content = file.readAll();
    QString text = QString::fromUtf8(content);
    QStringList lines = text.split('\n');
    
    unsigned long long memTotal = 0;
    unsigned long long memAvailable = 0;
    
    for (const QString& line : lines) {
        if (line.startsWith("MemTotal:")) {
            QStringList parts = line.split(' ', Qt::SkipEmptyParts);
            if (parts.size() >= 2) memTotal = parts[1].toULongLong();
        } else if (line.startsWith("MemAvailable:")) {
            QStringList parts = line.split(' ', Qt::SkipEmptyParts);
            if (parts.size() >= 2) memAvailable = parts[1].toULongLong();
        }
        
        if (memTotal > 0 && memAvailable > 0) break;
    }

    if (memTotal > 0) {
        unsigned long long usedKB = memTotal - memAvailable;
        m_totalMemKB = memTotal;
        m_memUsagePercent = (static_cast<double>(usedKB) / static_cast<double>(memTotal)) * 100.0;
        m_usedMemGB = static_cast<double>(usedKB) / (1024.0 * 1024.0);
    }
}

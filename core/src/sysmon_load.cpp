#include "sysmon_load.h"
#include <QFile>
#include <QStringList>

double SysmonLoad::getLoad1()  const { return m_load1; }
double SysmonLoad::getLoad5()  const { return m_load5; }
double SysmonLoad::getLoad15() const { return m_load15; }
int SysmonLoad::getRunningTasks() const { return m_runningTasks; }
int SysmonLoad::getTotalTasks()   const { return m_totalTasks; }

void SysmonLoad::update() {
    QFile file("/proc/loadavg");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;
    
    QString line = QString::fromUtf8(file.readAll()).trimmed();
    QStringList parts = line.split(' ', Qt::SkipEmptyParts);
    
    if (parts.size() >= 5) {
        m_load1  = parts[0].toDouble();
        m_load5  = parts[1].toDouble();
        m_load15 = parts[2].toDouble();
        
        QStringList taskParts = parts[3].split('/');
        if (taskParts.size() == 2) {
            m_runningTasks = taskParts[0].toInt();
            m_totalTasks   = taskParts[1].toInt();
        }
    }
}

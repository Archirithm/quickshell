#include "sysmon_battery.h"
#include <QFile>
#include <QDir>
#include <QDebug>

SysmonBattery::SysmonBattery() : m_present(false), m_percent(0), m_healthPercent(100), m_powerWatts(0) {
    m_batPath = findBatPath();
    m_present = !m_batPath.isEmpty();
    if (m_present) {
        qDebug() << "[SysmonBattery] Found battery at:" << m_batPath;
        update();
    }
}

QString SysmonBattery::findBatPath() const {
    QDir psDir("/sys/class/power_supply");
    if (!psDir.exists()) return QString();
    
    for (const QString &entry : psDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        if (entry.startsWith("BAT")) {
            QString path = psDir.absoluteFilePath(entry);
            QFile typeFile(path + "/type");
            if (typeFile.open(QIODevice::ReadOnly)) {
                QString type = QString::fromUtf8(typeFile.readAll()).trimmed();
                if (type == "Battery") return path;
            }
        }
    }
    return QString();
}

long long SysmonBattery::readSysFile(const QString &name) const {
    QFile file(m_batPath + "/" + name);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return -1;
    bool ok;
    long long val = QString::fromUtf8(file.readAll()).trimmed().toLongLong(&ok);
    return ok ? val : -1;
}

QString SysmonBattery::readSysString(const QString &name) const {
    QFile file(m_batPath + "/" + name);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return QString();
    return QString::fromUtf8(file.readAll()).trimmed();
}

double SysmonBattery::getPercent() const { return m_percent; }
QString SysmonBattery::getStatus() const { return m_status; }
int SysmonBattery::getHealthPercent() const { return m_healthPercent; }
double SysmonBattery::getPowerWatts() const { return m_powerWatts; }
bool SysmonBattery::isPresent() const { return m_present; }

void SysmonBattery::update() {
    if (!m_present) return;
    
    long long cap = readSysFile("capacity");
    if (cap >= 0) m_percent = static_cast<double>(cap);
    
    m_status = readSysString("status");
    
    long long energyFull = readSysFile("energy_full");
    long long energyDesign = readSysFile("energy_full_design");
    
    if (energyFull < 0 || energyDesign < 0) {
        energyFull = readSysFile("charge_full");
        energyDesign = readSysFile("charge_full_design");
    }
    
    if (energyFull > 0 && energyDesign > 0) {
        m_healthPercent = static_cast<int>((static_cast<double>(energyFull) / static_cast<double>(energyDesign)) * 100.0);
    }
    
    long long powerNow = readSysFile("power_now");
    if (powerNow >= 0) {
        m_powerWatts = static_cast<double>(powerNow) / 1000000.0;
    } else {
        long long currentNow = readSysFile("current_now");
        long long voltageNow = readSysFile("voltage_now");
        if (currentNow >= 0 && voltageNow >= 0) {
            m_powerWatts = (static_cast<double>(currentNow) * static_cast<double>(voltageNow)) / 1e12;
        }
    }
}

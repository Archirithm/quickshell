#include "sysmon_temp.h"
#include <QFile>
#include <filesystem>
#include <QDebug>

namespace fs = std::filesystem;

SysmonTemp::SysmonTemp() {
    m_sensorPath = findSensorPath();
}

QString SysmonTemp::findSensorPath() const {
    std::error_code ec;
    // Iterate /sys/class/hwmon
    for (const auto& entry : fs::directory_iterator("/sys/class/hwmon", ec)) {
        if (!entry.is_directory(ec) && !entry.is_symlink(ec)) continue;

        QString hwmonPath = QString::fromStdString(entry.path().string());
        QFile nameFile(hwmonPath + "/name");
        if (nameFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString name = QString::fromUtf8(nameFile.readAll()).trimmed();
            
            // Match usual Linux CPU probe names
            if (name == "coretemp" || name == "k10temp" || name == "x86_pkg_temp" || name == "TCPU") {
                // Find valid temp input (1 to 5)
                for (int i = 1; i <= 5; ++i) {
                    QString probe = hwmonPath + QString("/temp%1_input").arg(i);
                    QFile probeFile(probe);
                    if (probeFile.exists()) {
                        qDebug() << "[SysmonTemp] Found thermal probe:" << name << "at" << probe;
                        return probe;
                    }
                }
            }
        }
    }
    qWarning() << "[SysmonTemp] Failed to find coretemp or k10temp in hwmon!";
    return QString();
}

double SysmonTemp::getCoreTempCelsius() const {
    return m_coreTempCelsius;
}

void SysmonTemp::update() {
    if (m_sensorPath.isEmpty()) return;
    
    QFile file(m_sensorPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;
    
    QByteArray content = file.readAll();
    bool ok;
    // Usually it represents milliDegrees. Divide by 1000.
    long milliDeg = QString::fromUtf8(content).trimmed().toLong(&ok);
    if (ok) {
        m_coreTempCelsius = static_cast<double>(milliDeg) / 1000.0;
    }
}

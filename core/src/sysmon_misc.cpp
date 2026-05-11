#include "sysmon_misc.h"
#include <QFile>
#include <QFileInfo>
#include <QDebug>
#include <QDateTime>
#include <QDir>
#include <QProcessEnvironment>
#include <filesystem>
#include <sys/utsname.h>

namespace fs = std::filesystem;

SysmonMisc::SysmonMisc() : m_fanRpm(0), m_cpuFreqGHz(0.0) {
    m_fanPath = findFanPath();
    if (!m_fanPath.isEmpty())
        qDebug() << "[SysmonMisc] Fan sensor path:" << m_fanPath;
    loadStaticInfo();
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
QString SysmonMisc::getSystemUser() const { return m_systemUser; }
QString SysmonMisc::getHostName() const { return m_hostName; }
QString SysmonMisc::getWmName() const { return m_wmName; }
QString SysmonMisc::getKernelRelease() const { return m_kernelRelease; }
QString SysmonMisc::getShellName() const { return m_shellName; }
QString SysmonMisc::getDistroId() const { return m_distroId; }
QString SysmonMisc::getDistroName() const { return m_distroName; }
QString SysmonMisc::getChassis() const { return m_chassis; }
QString SysmonMisc::getOsAgeText() const { return m_osAgeText; }

QString SysmonMisc::readFirstLine(const QString& path, const QString& fallback) const {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return fallback;

    const QString line = QString::fromUtf8(file.readLine()).trimmed();
    return line.isEmpty() ? fallback : line;
}

QString SysmonMisc::osReleaseValue(const QString& key, const QString& fallback) const {
    QFile file("/etc/os-release");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return fallback;

    while (!file.atEnd()) {
        const QString line = QString::fromUtf8(file.readLine()).trimmed();
        const int split = line.indexOf('=');
        if (split <= 0)
            continue;

        if (line.left(split) != key)
            continue;

        QString value = line.mid(split + 1).trimmed();
        if (value.startsWith('"') && value.endsWith('"') && value.length() >= 2)
            value = value.mid(1, value.length() - 2);
        return value.isEmpty() ? fallback : value;
    }

    return fallback;
}

QString SysmonMisc::detectChassis() const {
    QString vendor = readFirstLine("/sys/class/dmi/id/sys_vendor", "Unknown");
    vendor.replace(" Inc.", "");
    vendor.replace(" Corporation", "");

    const QString typeValue = readFirstLine("/sys/class/dmi/id/chassis_type");
    bool ok = false;
    const int type = typeValue.toInt(&ok);
    QString kind = "Computer";
    if (ok) {
        if (type == 3 || type == 4 || type == 6 || type == 7)
            kind = "Desktop";
        else if (type == 8 || type == 9 || type == 10 || type == 11 || type == 31 || type == 32)
            kind = "Notebook";
    }

    return vendor == "Unknown" || vendor.isEmpty() ? kind : QString("%1 %2").arg(kind, vendor);
}

QString SysmonMisc::detectOsAge() const {
    QFileInfo pacmanLog("/var/log/pacman.log");
    if (!pacmanLog.exists())
        return "Unknown";

    QDateTime origin = pacmanLog.birthTime();
    if (!origin.isValid())
        origin = pacmanLog.metadataChangeTime();
    if (!origin.isValid())
        origin = pacmanLog.lastModified();
    if (!origin.isValid())
        return "Unknown";

    const qint64 days = origin.daysTo(QDateTime::currentDateTime());
    return QString("%1 days").arg(qMax<qint64>(0, days));
}

void SysmonMisc::loadStaticInfo() {
    const QProcessEnvironment env = QProcessEnvironment::systemEnvironment();

    m_systemUser = env.value("USER", "archirithm");
    m_hostName = readFirstLine("/proc/sys/kernel/hostname", readFirstLine("/etc/hostname", "arch"));

    QString wm = env.value("XDG_CURRENT_DESKTOP", env.value("XDG_SESSION_DESKTOP", "niri"));
    m_wmName = wm.split(':').first().toLower();

    struct utsname uts {};
    if (uname(&uts) == 0)
        m_kernelRelease = QString::fromLocal8Bit(uts.release);
    else
        m_kernelRelease = "Unknown";

    const QString shellPath = env.value("SHELL");
    m_shellName = shellPath.isEmpty() ? "Unknown" : QFileInfo(shellPath).fileName();
    m_distroId = osReleaseValue("ID", "linux").toLower();
    m_distroName = osReleaseValue("PRETTY_NAME", osReleaseValue("NAME", "Linux"));
    m_chassis = detectChassis();
    m_osAgeText = detectOsAge();
}

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

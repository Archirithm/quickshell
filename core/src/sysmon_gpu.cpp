#include "sysmon_gpu.h"
#include <QFile>
#include <QDir>
#include <QProcess>
#include <QDebug>
#include <filesystem>

namespace fs = std::filesystem;

SysmonGpu::SysmonGpu() : m_gpuUsage(0.0), m_gpuTemp(0.0), m_gpuType("NONE") {
    detectGpuType();
    qDebug() << "[SysmonGpu] Detected GPU type:" << m_gpuType;
}

void SysmonGpu::detectGpuType() {
    // 优先检测 NVIDIA (闭源驱动通过 nvidia-smi)
    QProcess probe;
    probe.start("nvidia-smi", QStringList() << "-L");
    probe.waitForFinished(2000);
    if (probe.exitCode() == 0 && !probe.readAllStandardOutput().trimmed().isEmpty()) {
        m_gpuType = "NVIDIA";
        return;
    }
    
    // 其次检测 AMD/Intel 通用 sysfs 接口
    m_gpuBusyPath = findGpuBusyPath();
    if (!m_gpuBusyPath.isEmpty()) {
        m_gpuType = "GENERIC";
        m_gpuTempPath = findGpuTempPath();
        if (!m_gpuBusyPath.isEmpty())
            qDebug() << "[SysmonGpu] GPU busy path:" << m_gpuBusyPath;
        if (!m_gpuTempPath.isEmpty())
            qDebug() << "[SysmonGpu] GPU temp path:" << m_gpuTempPath;
        return;
    }
    
    m_gpuType = "NONE";
}

QString SysmonGpu::findGpuBusyPath() const {
    std::error_code ec;
    for (const auto &entry : fs::directory_iterator("/sys/class/drm", ec)) {
        QString dirName = QString::fromStdString(entry.path().filename().string());
        if (!dirName.startsWith("card") || dirName.contains('-')) continue;
        
        QString candidate = QString::fromStdString(entry.path().string()) + "/device/gpu_busy_percent";
        if (QFile::exists(candidate)) return candidate;
    }
    return QString();
}

QString SysmonGpu::findGpuTempPath() const {
    std::error_code ec;
    for (const auto &entry : fs::directory_iterator("/sys/class/hwmon", ec)) {
        if (!entry.is_directory(ec) && !entry.is_symlink(ec)) continue;
        
        QString hwmonPath = QString::fromStdString(entry.path().string());
        QFile nameFile(hwmonPath + "/name");
        if (nameFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString name = QString::fromUtf8(nameFile.readAll()).trimmed();
            if (name == "amdgpu" || name == "nouveau" || name == "radeon" || name == "i915") {
                for (int i = 1; i <= 5; ++i) {
                    QString probe = hwmonPath + QString("/temp%1_input").arg(i);
                    if (QFile::exists(probe)) return probe;
                }
            }
        }
    }
    return QString();
}

double SysmonGpu::getGpuUsagePercent() const { return m_gpuUsage; }
double SysmonGpu::getGpuTempCelsius() const { return m_gpuTemp; }
QString SysmonGpu::getGpuType() const { return m_gpuType; }

void SysmonGpu::update() {
    if (m_gpuType == "NVIDIA") {
        updateNvidia();
    } else if (m_gpuType == "GENERIC") {
        updateGeneric();
    }
    // NONE: 什么都不做
}

void SysmonGpu::updateNvidia() {
    // nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits
    // 输出示例: "42, 65"
    QProcess proc;
    proc.start("nvidia-smi", QStringList() 
        << "--query-gpu=utilization.gpu,temperature.gpu" 
        << "--format=csv,noheader,nounits");
    proc.waitForFinished(2000);
    
    if (proc.exitCode() != 0) return;
    
    QString output = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
    QStringList parts = output.split(",");
    if (parts.size() >= 2) {
        bool ok1, ok2;
        int usage = parts[0].trimmed().toInt(&ok1);
        int temp = parts[1].trimmed().toInt(&ok2);
        if (ok1) m_gpuUsage = static_cast<double>(usage);
        if (ok2) m_gpuTemp = static_cast<double>(temp);
    }
}

void SysmonGpu::updateGeneric() {
    // GPU 使用率 (sysfs)
    if (!m_gpuBusyPath.isEmpty()) {
        QFile file(m_gpuBusyPath);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            bool ok;
            int val = QString::fromUtf8(file.readAll()).trimmed().toInt(&ok);
            if (ok) m_gpuUsage = static_cast<double>(val);
        }
    }
    
    // GPU 温度 (hwmon)
    if (!m_gpuTempPath.isEmpty()) {
        QFile file(m_gpuTempPath);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            bool ok;
            long milliDeg = QString::fromUtf8(file.readAll()).trimmed().toLong(&ok);
            if (ok) m_gpuTemp = static_cast<double>(milliDeg) / 1000.0;
        }
    }
}

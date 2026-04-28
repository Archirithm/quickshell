#pragma once
#include <QString>

class SysmonGpu {
public:
    SysmonGpu();
    ~SysmonGpu() = default;

    void update();
    
    double getGpuUsagePercent() const;
    double getGpuTempCelsius() const;
    QString getGpuType() const;    // "NVIDIA", "GENERIC", "NONE"

private:
    QString m_gpuType;             // 检测到的 GPU 类型
    QString m_gpuBusyPath;         // AMD/通用: /sys/class/drm/card*/device/gpu_busy_percent
    QString m_gpuTempPath;         // hwmon temp for non-NVIDIA GPU
    double m_gpuUsage;
    double m_gpuTemp;
    
    void detectGpuType();
    QString findGpuBusyPath() const;
    QString findGpuTempPath() const;
    void updateNvidia();           // 通过 nvidia-smi 获取
    void updateGeneric();          // 通过 sysfs 获取
};

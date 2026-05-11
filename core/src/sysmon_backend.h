#pragma once

#include <QObject>
#include <vector>
#include "sysmon_types.h"
#include "sysmon_cpu.h"
#include "sysmon_ram.h"
#include "sysmon_disk.h"
#include "sysmon_temp.h"
#include "sysmon_net.h"
#include "sysmon_load.h"
#include "sysmon_battery.h"
#include "sysmon_gpu.h"
#include "sysmon_misc.h"

// The central HUB (Facade Pattern) for accessing isolated micro-services
class SysmonBackend : public QObject {
    Q_OBJECT

public:
    static SysmonBackend& instance();
    
    // 分级更新接口
    void updateFast();      // 1s: CPU, RAM, Net, Processes
    void updateMedium();    // 2s: Temp, GPU, Load, CPU Freq
    void updateSlow();      // 5s: Fan, Battery
    void updateGlacial();   // 30s: Disk, Uptime
    
    // --- Existing ---
    double getGlobalCpuUsage() const;
    std::vector<ProcessInfo> getTopProcesses(int limit = 10) const;
    double getRamUsagePercent() const;
    double getRamUsedGB() const;
    double getRamTotalGB() const;
    double getDiskUsagePercent() const;
    double getDiskUsedGB() const;
    double getDiskTotalGB() const;
    double getCoreTempCelsius() const;
    
    // --- New: Network ---
    double getNetDownBps() const;
    double getNetUpBps() const;
    
    // --- New: Load ---
    double getLoad1() const;
    double getLoad5() const;
    double getLoad15() const;
    int getRunningTasks() const;
    int getTotalTasks() const;
    
    // --- New: Battery ---
    double getBatteryPercent() const;
    QString getBatteryStatus() const;
    int getBatteryHealth() const;
    double getBatteryPowerW() const;
    bool hasBattery() const;
    
    // --- New: GPU ---
    double getGpuUsagePercent() const;
    double getGpuTempCelsius() const;
    
    // --- New: Misc ---
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
    explicit SysmonBackend(QObject* parent = nullptr);
    ~SysmonBackend() override = default;
    
    SysmonBackend(const SysmonBackend&) = delete;
    SysmonBackend& operator=(const SysmonBackend&) = delete;

    SysmonCpu m_cpuProvider;
    SysmonRam m_ramProvider;
    SysmonDisk m_diskProvider;
    SysmonTemp m_tempProvider;
    SysmonNet m_netProvider;
    SysmonLoad m_loadProvider;
    SysmonBattery m_batteryProvider;
    SysmonGpu m_gpuProvider;
    SysmonMisc m_miscProvider;
};

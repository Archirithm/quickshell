#include "sysmon_backend.h"

SysmonBackend& SysmonBackend::instance() {
    static SysmonBackend inst;
    return inst;
}

SysmonBackend::SysmonBackend(QObject* parent) : QObject(parent) {
    // 首次初始化所有传感器游标（热身）
    updateFast();
    updateMedium();
    updateSlow();
    updateGlacial();
}

// --- 分级更新 ---

void SysmonBackend::updateFast() {
    m_ramProvider.update();
    m_netProvider.update();
    m_cpuProvider.update(m_ramProvider.getTotalMemKB());
}

void SysmonBackend::updateMedium() {
    m_tempProvider.update();
    m_gpuProvider.update();
    m_loadProvider.update();
    m_miscProvider.update(); // CPU freq 在此
}

void SysmonBackend::updateSlow() {
    m_batteryProvider.update();
    // Fan RPM 也在 miscProvider 的 update 中，但我们归类在 medium
    // 如果需要单独控制，可以拆分 miscProvider
}

void SysmonBackend::updateGlacial() {
    m_diskProvider.update();
    // Uptime 也在 miscProvider 中
}

// --- Existing getters ---

double SysmonBackend::getGlobalCpuUsage() const { 
    return m_cpuProvider.getGlobalCpuUsage(); 
}

std::vector<ProcessInfo> SysmonBackend::getTopProcesses(int limit) const { 
    return m_cpuProvider.getTopProcesses(limit); 
}

double SysmonBackend::getRamUsagePercent() const { 
    return m_ramProvider.getMemUsagePercent(); 
}

double SysmonBackend::getRamUsedGB() const { 
    return m_ramProvider.getUsedMemGB(); 
}

double SysmonBackend::getRamTotalGB() const {
    return static_cast<double>(m_ramProvider.getTotalMemKB()) / (1024.0 * 1024.0);
}

double SysmonBackend::getDiskUsagePercent() const { 
    return m_diskProvider.getRootDiskUsagePercent(); 
}

double SysmonBackend::getDiskUsedGB() const {
    return m_diskProvider.getDiskUsedGB();
}

double SysmonBackend::getDiskTotalGB() const {
    return m_diskProvider.getDiskTotalGB();
}

double SysmonBackend::getCoreTempCelsius() const { 
    return m_tempProvider.getCoreTempCelsius(); 
}

// --- Network ---
double SysmonBackend::getNetDownBps() const { return m_netProvider.getDownloadBytesPerSec(); }
double SysmonBackend::getNetUpBps() const { return m_netProvider.getUploadBytesPerSec(); }

// --- Load ---
double SysmonBackend::getLoad1() const { return m_loadProvider.getLoad1(); }
double SysmonBackend::getLoad5() const { return m_loadProvider.getLoad5(); }
double SysmonBackend::getLoad15() const { return m_loadProvider.getLoad15(); }
int SysmonBackend::getRunningTasks() const { return m_loadProvider.getRunningTasks(); }
int SysmonBackend::getTotalTasks() const { return m_loadProvider.getTotalTasks(); }

// --- Battery ---
double SysmonBackend::getBatteryPercent() const { return m_batteryProvider.getPercent(); }
QString SysmonBackend::getBatteryStatus() const { return m_batteryProvider.getStatus(); }
int SysmonBackend::getBatteryHealth() const { return m_batteryProvider.getHealthPercent(); }
double SysmonBackend::getBatteryPowerW() const { return m_batteryProvider.getPowerWatts(); }
bool SysmonBackend::hasBattery() const { return m_batteryProvider.isPresent(); }

// --- GPU ---
double SysmonBackend::getGpuUsagePercent() const { return m_gpuProvider.getGpuUsagePercent(); }
double SysmonBackend::getGpuTempCelsius() const { return m_gpuProvider.getGpuTempCelsius(); }

// --- Misc ---
int SysmonBackend::getFanRpm() const { return m_miscProvider.getFanRpm(); }
double SysmonBackend::getCpuFreqGHz() const { return m_miscProvider.getCpuFreqGHz(); }
QString SysmonBackend::getUptime() const { return m_miscProvider.getUptime(); }
QString SysmonBackend::getSystemUser() const { return m_miscProvider.getSystemUser(); }
QString SysmonBackend::getHostName() const { return m_miscProvider.getHostName(); }
QString SysmonBackend::getWmName() const { return m_miscProvider.getWmName(); }
QString SysmonBackend::getKernelRelease() const { return m_miscProvider.getKernelRelease(); }
QString SysmonBackend::getShellName() const { return m_miscProvider.getShellName(); }
QString SysmonBackend::getDistroId() const { return m_miscProvider.getDistroId(); }
QString SysmonBackend::getDistroName() const { return m_miscProvider.getDistroName(); }
QString SysmonBackend::getChassis() const { return m_miscProvider.getChassis(); }
QString SysmonBackend::getOsAgeText() const { return m_miscProvider.getOsAgeText(); }

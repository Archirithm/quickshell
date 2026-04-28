#pragma once
#include <vector>
#include <map>
#include "sysmon_types.h"

struct CpuTimes {
    unsigned long long user;
    unsigned long long nice;
    unsigned long long system;
    unsigned long long idle;
    unsigned long long iowait;
    unsigned long long irq;
    unsigned long long softirq;
    unsigned long long steal;
    unsigned long long guest;
    unsigned long long guest_nice;

    unsigned long long total() const;
    unsigned long long work() const;
};

class SysmonCpu {
public:
    SysmonCpu();
    ~SysmonCpu() = default;

    // 每一帧轮询，需要传入当前总内存量用于辅助计算各个进程使用的 %
    void update(unsigned long long totalSystemMemKB);
    
    double getGlobalCpuUsage() const;
    std::vector<ProcessInfo> getTopProcesses(int limit = 10) const;

private:
    CpuTimes m_previousCpuTimes;
    double m_globalCpuUsage;
    bool m_firstSample;
    std::map<int, unsigned long long> m_previousProcTicks;
    std::vector<ProcessInfo> m_lastProcesses;

    CpuTimes readCpuTimes() const;
};

#pragma once

class SysmonDisk {
public:
    SysmonDisk() = default;
    ~SysmonDisk() = default;

    void update();
    double getRootDiskUsagePercent() const;
    double getDiskUsedGB() const;
    double getDiskTotalGB() const;

private:
    double m_diskUsagePercent = 0.0;
    double m_diskUsedGB = 0.0;
    double m_diskTotalGB = 0.0;
};

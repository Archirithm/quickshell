#pragma once

class SysmonRam {
public:
    SysmonRam();
    ~SysmonRam() = default;

    void update();
    
    unsigned long long getTotalMemKB() const;
    double getMemUsagePercent() const;
    double getUsedMemGB() const;

private:
    unsigned long long m_totalMemKB;
    double m_memUsagePercent;
    double m_usedMemGB;
};

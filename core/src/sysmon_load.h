#pragma once

class SysmonLoad {
public:
    SysmonLoad() = default;
    ~SysmonLoad() = default;

    void update();
    
    double getLoad1() const;
    double getLoad5() const;
    double getLoad15() const;
    int getRunningTasks() const;
    int getTotalTasks() const;

private:
    double m_load1 = 0.0;
    double m_load5 = 0.0;
    double m_load15 = 0.0;
    int m_runningTasks = 0;
    int m_totalTasks = 0;
};

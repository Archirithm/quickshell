#pragma once
#include <QString>

struct ProcessInfo {
    int pid;
    int uid;            // 进程所属用户 UID
    QString name;
    QString cmdline;   // 完整命令行路径 (来自 /proc/{pid}/cmdline)
    double cpuPercent;
    unsigned long long memoryKB;
    double memoryPercent;
};

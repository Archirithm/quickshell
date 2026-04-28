#include "sysmon_disk.h"
#include <sys/statvfs.h>

double SysmonDisk::getRootDiskUsagePercent() const {
    return m_diskUsagePercent;
}

double SysmonDisk::getDiskUsedGB() const {
    return m_diskUsedGB;
}

double SysmonDisk::getDiskTotalGB() const {
    return m_diskTotalGB;
}

void SysmonDisk::update() {
    struct statvfs stat;
    if (statvfs("/", &stat) == 0) {
        unsigned long long total = stat.f_blocks;
        unsigned long long bfree = stat.f_bavail; // bavail 表示非特权用户真正可用的
        unsigned long long blockSize = stat.f_frsize;
        
        if (total > 0) {
            double used = static_cast<double>(total - bfree);
            m_diskUsagePercent = (used / static_cast<double>(total)) * 100.0;
            m_diskTotalGB = static_cast<double>(total * blockSize) / (1024.0 * 1024.0 * 1024.0);
            m_diskUsedGB  = static_cast<double>((total - bfree) * blockSize) / (1024.0 * 1024.0 * 1024.0);
        }
    }
}

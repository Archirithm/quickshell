#include "sysmon_net.h"
#include <QFile>
#include <QStringList>

SysmonNet::SysmonNet() : m_prevRxBytes(0), m_prevTxBytes(0), m_downloadBps(0), m_uploadBps(0), m_firstSample(true) {
    readNetBytes(m_prevRxBytes, m_prevTxBytes);
}

double SysmonNet::getDownloadBytesPerSec() const { return m_downloadBps; }
double SysmonNet::getUploadBytesPerSec() const { return m_uploadBps; }

void SysmonNet::readNetBytes(unsigned long long &rx, unsigned long long &tx) const {
    rx = 0; tx = 0;
    QFile file("/proc/net/dev");
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;
    
    QByteArray content = file.readAll();
    QString text = QString::fromUtf8(content);
    QStringList lines = text.split('\n');
    
    for (int i = 2; i < lines.size(); ++i) {
        QString line = lines[i].trimmed();
        if (line.isEmpty()) continue;
        
        int colonIdx = line.indexOf(':');
        if (colonIdx < 0) continue;
        
        QString iface = line.left(colonIdx).trimmed();
        if (iface == "lo") continue;
        
        QString data = line.mid(colonIdx + 1).trimmed();
        QStringList parts = data.split(' ', Qt::SkipEmptyParts);
        if (parts.size() >= 9) {
            rx += parts[0].toULongLong();
            tx += parts[8].toULongLong();
        }
    }
}

void SysmonNet::update() {
    unsigned long long curRx = 0, curTx = 0;
    readNetBytes(curRx, curTx);
    
    if (!m_firstSample) {
        m_downloadBps = static_cast<double>(curRx - m_prevRxBytes);
        m_uploadBps = static_cast<double>(curTx - m_prevTxBytes);
    }
    
    m_prevRxBytes = curRx;
    m_prevTxBytes = curTx;
    m_firstSample = false;
}

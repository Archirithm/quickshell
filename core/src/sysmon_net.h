#pragma once

class SysmonNet {
public:
    SysmonNet();
    ~SysmonNet() = default;

    void update();
    
    double getDownloadBytesPerSec() const;
    double getUploadBytesPerSec() const;

private:
    unsigned long long m_prevRxBytes;
    unsigned long long m_prevTxBytes;
    double m_downloadBps;
    double m_uploadBps;
    bool m_firstSample;
    
    void readNetBytes(unsigned long long &rx, unsigned long long &tx) const;
};

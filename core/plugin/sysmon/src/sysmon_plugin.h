#pragma once

#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>
#include "process_model.h"

class SysmonPlugin : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    
    // === 快速组 (1s) ===
    Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY fastDataChanged)
    Q_PROPERTY(double ramUsage READ ramUsage NOTIFY fastDataChanged)
    Q_PROPERTY(double ramUsedGB READ ramUsedGB NOTIFY fastDataChanged)
    Q_PROPERTY(double ramTotalGB READ ramTotalGB NOTIFY fastDataChanged)
    Q_PROPERTY(double netDownBps READ netDownBps NOTIFY fastDataChanged)
    Q_PROPERTY(double netUpBps READ netUpBps NOTIFY fastDataChanged)
    Q_PROPERTY(ProcessModel* processes READ processes CONSTANT)
    
    // === 中速组 (2s) ===
    Q_PROPERTY(double coreTemp READ coreTemp NOTIFY mediumDataChanged)
    Q_PROPERTY(double gpuTemp READ gpuTemp NOTIFY mediumDataChanged)
    Q_PROPERTY(double gpuUsage READ gpuUsage NOTIFY mediumDataChanged)
    Q_PROPERTY(double load1 READ load1 NOTIFY mediumDataChanged)
    Q_PROPERTY(double load5 READ load5 NOTIFY mediumDataChanged)
    Q_PROPERTY(double load15 READ load15 NOTIFY mediumDataChanged)
    Q_PROPERTY(double cpuFreqGHz READ cpuFreqGHz NOTIFY mediumDataChanged)
    
    // === 慢速组 (5s) ===
    Q_PROPERTY(int fanRpm READ fanRpm NOTIFY slowDataChanged)
    Q_PROPERTY(double batteryPercent READ batteryPercent NOTIFY slowDataChanged)
    Q_PROPERTY(QString batteryStatus READ batteryStatus NOTIFY slowDataChanged)
    Q_PROPERTY(int batteryHealth READ batteryHealth NOTIFY slowDataChanged)
    Q_PROPERTY(double batteryPowerW READ batteryPowerW NOTIFY slowDataChanged)
    Q_PROPERTY(bool hasBattery READ hasBattery CONSTANT)
    
    // === 超慢组 (30s) ===
    Q_PROPERTY(double diskUsage READ diskUsage NOTIFY glacialDataChanged)
    Q_PROPERTY(double diskUsedGB READ diskUsedGB NOTIFY glacialDataChanged)
    Q_PROPERTY(double diskTotalGB READ diskTotalGB NOTIFY glacialDataChanged)
    Q_PROPERTY(QString uptime READ uptime NOTIFY glacialDataChanged)
    Q_PROPERTY(int taskRunning READ taskRunning NOTIFY mediumDataChanged)
    Q_PROPERTY(int taskTotal READ taskTotal NOTIFY mediumDataChanged)

public:
    explicit SysmonPlugin(QObject *parent = nullptr);
    ~SysmonPlugin() override = default;

    // Fast
    double cpuUsage() const;
    double ramUsage() const;
    double ramUsedGB() const;
    double ramTotalGB() const;
    double netDownBps() const;
    double netUpBps() const;
    ProcessModel* processes() const;
    
    // Medium
    double coreTemp() const;
    double gpuTemp() const;
    double gpuUsage() const;
    double load1() const;
    double load5() const;
    double load15() const;
    double cpuFreqGHz() const;
    
    // Slow
    int fanRpm() const;
    double batteryPercent() const;
    QString batteryStatus() const;
    int batteryHealth() const;
    double batteryPowerW() const;
    bool hasBattery() const;
    
    // Glacial
    double diskUsage() const;
    double diskUsedGB() const;
    double diskTotalGB() const;
    QString uptime() const;
    int taskRunning() const;
    int taskTotal() const;

signals:
    void fastDataChanged();
    void mediumDataChanged();
    void slowDataChanged();
    void glacialDataChanged();

private slots:
    void onFastTick();
    void onMediumTick();
    void onSlowTick();
    void onGlacialTick();

private:
    QTimer m_fastTimer;     // 1s
    QTimer m_mediumTimer;   // 2s
    QTimer m_slowTimer;     // 5s
    QTimer m_glacialTimer;  // 30s
    
    // Fast cache
    double m_cpuUsage;
    double m_ramUsage;
    double m_ramUsedGB;
    double m_ramTotalGB;
    double m_netDownBps;
    double m_netUpBps;
    
    // Medium cache
    double m_coreTemp;
    double m_gpuTemp;
    double m_gpuUsage;
    double m_load1;
    double m_load5;
    double m_load15;
    double m_cpuFreqGHz;
    int m_taskRunning;
    int m_taskTotal;
    
    // Slow cache
    int m_fanRpm;
    double m_batteryPercent;
    QString m_batteryStatus;
    int m_batteryHealth;
    double m_batteryPowerW;
    
    // Glacial cache
    double m_diskUsage;
    double m_diskUsedGB;
    double m_diskTotalGB;
    QString m_uptime;
    
    ProcessModel* m_processModel;
};

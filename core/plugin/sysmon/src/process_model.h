#pragma once

#include <QAbstractListModel>
#include <QVariantMap>
#include <vector>
#include "sysmon_backend.h"

// Note: 此类不需要 QML_ELEMENT，我们会将其指针提供给 Q_PROPERTY
class ProcessModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum ProcessRoles {
        PidRole = Qt::UserRole + 1,
        NameRole,
        CpuRole,
        MemRole,
        MemKbRole,
        CmdlineRole,
        UidRole
    };

    explicit ProcessModel(QObject *parent = nullptr);
    ~ProcessModel() override = default;

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // 提供给 JS 环境使用的直达取值方法
    Q_INVOKABLE int count() const;
    Q_INVOKABLE QVariantMap get(int index) const;

    // 重置并覆盖现有数组并抛发更新事件
    void setProcesses(const std::vector<ProcessInfo>& processes);

private:
    std::vector<ProcessInfo> m_processes;
};

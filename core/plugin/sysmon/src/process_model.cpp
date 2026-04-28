#include "process_model.h"

ProcessModel::ProcessModel(QObject *parent) : QAbstractListModel(parent) {}

int ProcessModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid()) return 0;
    return static_cast<int>(m_processes.size());
}

QVariant ProcessModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= static_cast<int>(m_processes.size())) return QVariant();

    const ProcessInfo& process = m_processes[index.row()];
    switch (role) {
        case PidRole: return process.pid;
        case NameRole: return process.name;
        case CpuRole: return process.cpuPercent;
        case MemRole: return process.memoryPercent;
        case MemKbRole: return static_cast<qulonglong>(process.memoryKB);
        case CmdlineRole: return process.cmdline;
        case UidRole: return process.uid;
    }
    return QVariant();
}

QHash<int, QByteArray> ProcessModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[PidRole] = "pid";
    roles[NameRole] = "name";
    roles[CpuRole] = "cpuPercent";
    roles[MemRole] = "memPercent";
    roles[MemKbRole] = "memKB";
    roles[CmdlineRole] = "cmdline";
    roles[UidRole] = "uid";
    return roles;
}

int ProcessModel::count() const {
    return static_cast<int>(m_processes.size());
}

QVariantMap ProcessModel::get(int index) const {
    if (index < 0 || index >= static_cast<int>(m_processes.size())) return QVariantMap();
    QVariantMap map;
    const ProcessInfo& proc = m_processes[index];
    map["pid"] = proc.pid;
    map["name"] = proc.name;
    map["cpuPercent"] = proc.cpuPercent;
    map["memPercent"] = proc.memoryPercent;
    map["memKB"] = static_cast<qulonglong>(proc.memoryKB);
    map["cmdline"] = proc.cmdline;
    map["uid"] = proc.uid;
    return map;
}

void ProcessModel::setProcesses(const std::vector<ProcessInfo>& processes) {
    // 这将自动通知 QML ListView 此模型发生了全量重置
    beginResetModel();
    m_processes = processes;
    endResetModel();
}

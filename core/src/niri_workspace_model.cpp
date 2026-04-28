#include "niri_workspace_model.h"

NiriWorkspaceModel::NiriWorkspaceModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int NiriWorkspaceModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_workspaces.count();
}

QVariant NiriWorkspaceModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_workspaces.count())
        return {};

    const NiriWorkspace &workspace = m_workspaces.at(index.row());
    switch (role) {
    case IdRole:
        return QVariant::fromValue(workspace.id);
    case IndexRole:
        return workspace.index;
    case NameRole:
        return workspace.name;
    case OutputRole:
        return workspace.output;
    case IsActiveRole:
        return workspace.isActive;
    case IsFocusedRole:
        return workspace.isFocused;
    case IsUrgentRole:
        return workspace.isUrgent;
    case ActiveWindowIdRole:
        return QVariant::fromValue(workspace.activeWindowId);
    case WindowCountRole:
        return workspace.windowCount;
    case IconsRole:
        return workspace.icons;
    default:
        return {};
    }
}

QHash<int, QByteArray> NiriWorkspaceModel::roleNames() const
{
    return {
        {IdRole, "id"},
        {IndexRole, "index"},
        {NameRole, "name"},
        {OutputRole, "output"},
        {IsActiveRole, "isActive"},
        {IsFocusedRole, "isFocused"},
        {IsUrgentRole, "isUrgent"},
        {ActiveWindowIdRole, "activeWindowId"},
        {WindowCountRole, "windowCount"},
        {IconsRole, "icons"},
    };
}

void NiriWorkspaceModel::setWorkspaces(const QList<NiriWorkspace> &workspaces)
{
    bool sameRows = m_workspaces.count() == workspaces.count();
    if (sameRows) {
        for (int i = 0; i < m_workspaces.count(); ++i) {
            if (m_workspaces.at(i).id != workspaces.at(i).id) {
                sameRows = false;
                break;
            }
        }
    }

    if (sameRows) {
        for (int i = 0; i < workspaces.count(); ++i) {
            m_workspaces[i] = workspaces.at(i);
            const QModelIndex modelIndex = index(i);
            emit dataChanged(modelIndex, modelIndex, {
                IdRole,
                IndexRole,
                NameRole,
                OutputRole,
                IsActiveRole,
                IsFocusedRole,
                IsUrgentRole,
                ActiveWindowIdRole,
                WindowCountRole,
                IconsRole,
            });
        }
        return;
    }

    const int oldCount = m_workspaces.count();
    beginResetModel();
    m_workspaces = workspaces;
    endResetModel();
    if (oldCount != m_workspaces.count())
        emit countChanged();
}

const QList<NiriWorkspace> &NiriWorkspaceModel::workspaces() const
{
    return m_workspaces;
}

QVariantMap NiriWorkspaceModel::workspaceById(quint64 id) const
{
    for (const NiriWorkspace &workspace : m_workspaces) {
        if (workspace.id == id)
            return toMap(workspace);
    }
    return {};
}

QVariantList NiriWorkspaceModel::workspacesForOutput(const QString &output) const
{
    QVariantList result;
    for (const NiriWorkspace &workspace : m_workspaces) {
        if (output.isEmpty() || workspace.output == output)
            result.append(toMap(workspace));
    }
    return result;
}

QVariantMap NiriWorkspaceModel::toMap(const NiriWorkspace &workspace) const
{
    return {
        {QStringLiteral("id"), QVariant::fromValue(workspace.id)},
        {QStringLiteral("index"), workspace.index},
        {QStringLiteral("name"), workspace.name},
        {QStringLiteral("output"), workspace.output},
        {QStringLiteral("isActive"), workspace.isActive},
        {QStringLiteral("isFocused"), workspace.isFocused},
        {QStringLiteral("isUrgent"), workspace.isUrgent},
        {QStringLiteral("activeWindowId"), QVariant::fromValue(workspace.activeWindowId)},
        {QStringLiteral("windowCount"), workspace.windowCount},
        {QStringLiteral("icons"), workspace.icons},
    };
}

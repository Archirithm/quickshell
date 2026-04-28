#pragma once

#include "niri_types.h"

#include <QAbstractListModel>

class NiriWorkspaceModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Role {
        IdRole = Qt::UserRole + 1,
        IndexRole,
        NameRole,
        OutputRole,
        IsActiveRole,
        IsFocusedRole,
        IsUrgentRole,
        ActiveWindowIdRole,
        WindowCountRole,
        IconsRole
    };

    explicit NiriWorkspaceModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setWorkspaces(const QList<NiriWorkspace> &workspaces);
    const QList<NiriWorkspace> &workspaces() const;
    QVariantMap workspaceById(quint64 id) const;
    QVariantList workspacesForOutput(const QString &output) const;

signals:
    void countChanged();

private:
    QVariantMap toMap(const NiriWorkspace &workspace) const;

    QList<NiriWorkspace> m_workspaces;
};

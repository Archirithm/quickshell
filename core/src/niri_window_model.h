#pragma once

#include "niri_types.h"

#include <QAbstractListModel>

class NiriWindowModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Role {
        IdRole = Qt::UserRole + 1,
        TitleRole,
        AppIdRole,
        AppNameRole,
        PidRole,
        WorkspaceIdRole,
        IsFocusedRole,
        IsFloatingRole,
        IsUrgentRole,
        LayoutColumnRole,
        LayoutRowRole,
        IconPathRole
    };

    explicit NiriWindowModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setWindows(const QList<NiriWindow> &windows);
    const QList<NiriWindow> &windows() const;
    QVariantMap windowById(quint64 id) const;
    QVariantList windowsForWorkspace(quint64 workspaceId) const;
    QVariantList allWindows() const;

signals:
    void countChanged();

private:
    QVariantMap toMap(const NiriWindow &window) const;

    QList<NiriWindow> m_windows;
};

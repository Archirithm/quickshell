#pragma once

#include "niri_types.h"

#include <QAbstractListModel>

class NiriOutputModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Role {
        NameRole = Qt::UserRole + 1,
        MakeRole,
        ModelRole,
        SerialRole,
        LogicalXRole,
        LogicalYRole,
        LogicalWidthRole,
        LogicalHeightRole,
        ScaleRole,
        TransformRole,
        CurrentModeRole,
        VrrEnabledRole
    };

    explicit NiriOutputModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setOutputs(const QList<NiriOutput> &outputs);
    const QList<NiriOutput> &outputs() const;
    QVariantMap outputByName(const QString &name) const;

signals:
    void countChanged();

private:
    QVariantMap toMap(const NiriOutput &output) const;

    QList<NiriOutput> m_outputs;
};

#pragma once

#include <QAbstractListModel>
#include <QVariantMap>

class WeatherListModel : public QAbstractListModel {
    Q_OBJECT

public:
    explicit WeatherListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE QVariantMap get(int index) const;
    Q_INVOKABLE int count() const;

    void setItems(const QList<QVariantMap> &items);

private:
    QList<QVariantMap> m_items;
    QHash<int, QByteArray> m_roles;
};

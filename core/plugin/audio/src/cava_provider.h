#pragma once

#include <QObject>
#include <QTimer>
#include <QVector>
#include <QtQml/qqmlregistration.h>
#include <cava/cavacore.h>

class CavaProvider : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(int bars READ bars WRITE setBars NOTIFY barsChanged)
    Q_PROPERTY(QVector<double> values READ values NOTIFY valuesChanged)

public:
    explicit CavaProvider(QObject* parent = nullptr);
    ~CavaProvider() override;

    bool active() const;
    void setActive(bool active);

    bool available() const;

    int bars() const;
    void setBars(int bars);

    QVector<double> values() const;

signals:
    void activeChanged();
    void availableChanged();
    void barsChanged();
    void valuesChanged();

private slots:
    void process();

private:
    bool m_active = false;
    bool m_available = false;
    int m_bars = 45;
    QVector<double> m_values;
    QVector<double> m_input;
    QVector<double> m_output;
    cava_plan* m_plan = nullptr;
    QTimer m_timer;

    void rebuildCava();
    void destroyCava();
    void setAvailable(bool available);
    void resetValues();
};

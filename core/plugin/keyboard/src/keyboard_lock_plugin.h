#pragma once

#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class KeyboardLockState : public QObject {
    Q_OBJECT
    QML_NAMED_ELEMENT(KeyboardLockState)
    QML_SINGLETON

    Q_PROPERTY(bool numLock READ numLock NOTIFY lockStateChanged)
    Q_PROPERTY(bool capsLock READ capsLock NOTIFY lockStateChanged)

public:
    explicit KeyboardLockState(QObject *parent = nullptr);

    bool numLock() const;
    bool capsLock() const;

    Q_INVOKABLE void refresh();

signals:
    void lockStateChanged();

private:
    static bool readAnyLedState(const QString &suffix);
    void setStates(bool numLock, bool capsLock);

    bool m_numLock = false;
    bool m_capsLock = false;
    QTimer m_pollTimer;
};

#include "keyboard_lock_plugin.h"

#include <QDir>
#include <QFile>
#include <QTextStream>

KeyboardLockState::KeyboardLockState(QObject *parent)
    : QObject(parent)
{
    m_pollTimer.setInterval(1000);
    m_pollTimer.setTimerType(Qt::CoarseTimer);
    connect(&m_pollTimer, &QTimer::timeout, this, &KeyboardLockState::refresh);
    m_pollTimer.start();
    QTimer::singleShot(0, this, &KeyboardLockState::refresh);
}

bool KeyboardLockState::numLock() const { return m_numLock; }
bool KeyboardLockState::capsLock() const { return m_capsLock; }

void KeyboardLockState::refresh()
{
    setStates(
        readAnyLedState(QStringLiteral("::numlock")),
        readAnyLedState(QStringLiteral("::capslock"))
    );
}

bool KeyboardLockState::readAnyLedState(const QString &suffix)
{
    const QDir ledsDir(QStringLiteral("/sys/class/leds"));
    const QStringList entries = ledsDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

    for (const QString &entry : entries) {
        if (!entry.endsWith(suffix))
            continue;

        QFile brightness(ledsDir.filePath(entry + QStringLiteral("/brightness")));
        if (!brightness.open(QIODevice::ReadOnly | QIODevice::Text))
            continue;

        const QString value = QString::fromUtf8(brightness.readAll()).trimmed();
        if (value == QStringLiteral("1"))
            return true;
    }

    return false;
}

void KeyboardLockState::setStates(bool numLock, bool capsLock)
{
    if (m_numLock == numLock && m_capsLock == capsLock)
        return;

    m_numLock = numLock;
    m_capsLock = capsLock;
    emit lockStateChanged();
}

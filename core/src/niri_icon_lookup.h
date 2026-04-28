#pragma once

#include <QHash>
#include <QString>

class NiriIconLookup {
public:
    struct IconInfo {
        QString appId;
        QString appName;
        QString iconPath;
    };

    IconInfo resolve(const QString &appId);

private:
    struct DesktopEntry {
        QString id;
        QString name;
        QString icon;
        QString exec;
    };

    QString moddedAppId(const QString &appId) const;
    DesktopEntry findDesktopEntry(const QString &appId);
    DesktopEntry parseDesktopFile(const QString &path, const QString &entryId) const;
    QString findIconFile(const QString &iconName);
    QString findIconByCandidates(const QStringList &candidates);
    QString normalizeIconUrl(const QString &path) const;

    QHash<QString, IconInfo> m_cache;
    QHash<QString, DesktopEntry> m_desktopCache;
    QHash<QString, QString> m_iconCache;
};

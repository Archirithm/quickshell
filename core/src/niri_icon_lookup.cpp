#include "niri_icon_lookup.h"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTextStream>
#include <QUrl>

NiriIconLookup::IconInfo NiriIconLookup::resolve(const QString &appId)
{
    if (appId.isEmpty())
        return {};

    const QString normalized = moddedAppId(appId);
    if (m_cache.contains(normalized))
        return m_cache.value(normalized);

    IconInfo info;
    info.appId = normalized;

    QStringList candidates;
    candidates << normalized << normalized.toLower();
    if (normalized.contains('.')) {
        const QString tail = normalized.section('.', -1);
        candidates << tail << tail.toLower();
    }

    DesktopEntry entry = findDesktopEntry(normalized);
    if (entry.id.isEmpty() && normalized != appId)
        entry = findDesktopEntry(appId);

    if (!entry.id.isEmpty()) {
        info.appName = entry.name;
        if (!entry.icon.isEmpty())
            candidates.prepend(entry.icon);
    }

    if (info.appName.isEmpty()) {
        QString display = normalized;
        if (display.contains('.'))
            display = display.section('.', -1);
        display.replace('-', ' ');
        display.replace('_', ' ');
        info.appName = display;
    }

    if (normalized == "org.quickshell" || normalized == "quickshell") {
        candidates.prepend(QStringLiteral("quickshell"));
        candidates.prepend(QStringLiteral("application-x-executable"));
    }

    info.iconPath = findIconByCandidates(candidates);
    if (info.iconPath.isEmpty())
        info.iconPath = findIconFile(QStringLiteral("application-x-executable"));

    m_cache.insert(normalized, info);
    return info;
}

QString NiriIconLookup::moddedAppId(const QString &appId) const
{
    static const QRegularExpression steamRe(QStringLiteral("^steam_app_(\\d+)$"));
    const auto match = steamRe.match(appId);
    if (match.hasMatch())
        return QStringLiteral("steam_icon_%1").arg(match.captured(1));

    static const QHash<QString, QString> exact = {
        {QStringLiteral("Code"), QStringLiteral("visual-studio-code")},
        {QStringLiteral("code"), QStringLiteral("visual-studio-code")},
        {QStringLiteral("codium"), QStringLiteral("vscodium")},
        {QStringLiteral("footclient"), QStringLiteral("foot")},
        {QStringLiteral("org.wezfurlong.wezterm"), QStringLiteral("org.wezfurlong.wezterm")},
        {QStringLiteral("kitty"), QStringLiteral("kitty")},
    };

    return exact.value(appId, appId);
}

NiriIconLookup::DesktopEntry NiriIconLookup::findDesktopEntry(const QString &appId)
{
    if (m_desktopCache.contains(appId))
        return m_desktopCache.value(appId);

    QStringList appDirs;
    const QString dataHome = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    if (!dataHome.isEmpty())
        appDirs << dataHome + QStringLiteral("/applications");

    const QString xdgDataDirs = QProcessEnvironment::systemEnvironment().value(
        QStringLiteral("XDG_DATA_DIRS"),
        QStringLiteral("/usr/local/share:/usr/share"));
    for (const QString &dir : xdgDataDirs.split(':', Qt::SkipEmptyParts))
        appDirs << dir + QStringLiteral("/applications");

    appDirs.removeDuplicates();

    QStringList ids;
    ids << appId;
    if (!appId.endsWith(QStringLiteral(".desktop")))
        ids << appId + QStringLiteral(".desktop");
    if (appId.contains('.'))
        ids << appId.section('.', -1) + QStringLiteral(".desktop");
    ids.removeDuplicates();

    for (const QString &dir : appDirs) {
        for (const QString &id : ids) {
            const QString path = QDir(dir).filePath(id);
            if (QFileInfo::exists(path)) {
                DesktopEntry entry = parseDesktopFile(path, id);
                m_desktopCache.insert(appId, entry);
                return entry;
            }
        }
    }

    DesktopEntry best;
    for (const QString &dir : appDirs) {
        if (!QFileInfo::exists(dir))
            continue;

        QDirIterator it(dir, {QStringLiteral("*.desktop")}, QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            const QString path = it.next();
            const QString entryId = QFileInfo(path).fileName();
            DesktopEntry entry = parseDesktopFile(path, entryId);
            const QString compactExec = entry.exec.section(' ', 0, 0);
            if (entry.id.compare(appId, Qt::CaseInsensitive) == 0 ||
                entry.id.compare(appId + QStringLiteral(".desktop"), Qt::CaseInsensitive) == 0 ||
                entry.name.compare(appId, Qt::CaseInsensitive) == 0 ||
                QFileInfo(compactExec).baseName().compare(appId, Qt::CaseInsensitive) == 0) {
                best = entry;
                break;
            }
        }
        if (!best.id.isEmpty())
            break;
    }

    m_desktopCache.insert(appId, best);
    return best;
}

NiriIconLookup::DesktopEntry NiriIconLookup::parseDesktopFile(const QString &path, const QString &entryId) const
{
    DesktopEntry entry;
    entry.id = entryId;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return entry;

    bool inDesktopEntry = false;
    QTextStream stream(&file);
    while (!stream.atEnd()) {
        const QString line = stream.readLine().trimmed();
        if (line == QStringLiteral("[Desktop Entry]")) {
            inDesktopEntry = true;
            continue;
        }
        if (line.startsWith('[') && line.endsWith(']') && line != QStringLiteral("[Desktop Entry]"))
            inDesktopEntry = false;
        if (!inDesktopEntry || line.startsWith('#') || !line.contains('='))
            continue;

        const QString key = line.section('=', 0, 0);
        const QString value = line.section('=', 1);
        if (key == QStringLiteral("Name") && entry.name.isEmpty())
            entry.name = value;
        else if (key == QStringLiteral("Icon") && entry.icon.isEmpty())
            entry.icon = value;
        else if (key == QStringLiteral("Exec") && entry.exec.isEmpty())
            entry.exec = value;
    }

    return entry;
}

QString NiriIconLookup::findIconByCandidates(const QStringList &candidates)
{
    for (const QString &candidate : candidates) {
        const QString icon = findIconFile(candidate);
        if (!icon.isEmpty())
            return icon;
    }
    return {};
}

QString NiriIconLookup::findIconFile(const QString &iconName)
{
    if (iconName.isEmpty())
        return {};
    if (m_iconCache.contains(iconName))
        return m_iconCache.value(iconName);

    QFileInfo direct(iconName);
    if (direct.isAbsolute() && direct.exists()) {
        const QString path = normalizeIconUrl(direct.absoluteFilePath());
        m_iconCache.insert(iconName, path);
        return path;
    }

    const QStringList names = iconName.contains('.')
        ? QStringList{iconName}
        : QStringList{iconName + QStringLiteral(".svg"), iconName + QStringLiteral(".png"), iconName + QStringLiteral(".xpm")};

    QStringList roots;
    const QString dataHome = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation);
    if (!dataHome.isEmpty())
        roots << dataHome + QStringLiteral("/icons");
    roots << QDir::homePath() + QStringLiteral("/.icons");

    const QString xdgDataDirs = QProcessEnvironment::systemEnvironment().value(
        QStringLiteral("XDG_DATA_DIRS"),
        QStringLiteral("/usr/local/share:/usr/share"));
    for (const QString &dir : xdgDataDirs.split(':', Qt::SkipEmptyParts))
        roots << dir + QStringLiteral("/icons");
    roots << QStringLiteral("/usr/share/pixmaps");
    roots.removeDuplicates();

    for (const QString &root : roots) {
        if (!QFileInfo::exists(root))
            continue;
        for (const QString &name : names) {
            QDirIterator it(root, {name}, QDir::Files, QDirIterator::Subdirectories);
            if (it.hasNext()) {
                const QString path = normalizeIconUrl(it.next());
                m_iconCache.insert(iconName, path);
                return path;
            }
        }
    }

    m_iconCache.insert(iconName, QString());
    return {};
}

QString NiriIconLookup::normalizeIconUrl(const QString &path) const
{
    return QUrl::fromLocalFile(path).toString();
}

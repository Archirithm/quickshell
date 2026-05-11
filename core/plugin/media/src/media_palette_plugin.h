#pragma once

#include <QObject>
#include <QColor>
#include <QString>
#include <QtQml/qqmlregistration.h>

class MediaPalettePlugin : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QColor primary READ primary NOTIFY paletteChanged)
    Q_PROPERTY(QColor onPrimary READ onPrimary NOTIFY paletteChanged)
    Q_PROPERTY(QColor track READ track NOTIFY paletteChanged)

public:
    explicit MediaPalettePlugin(QObject *parent = nullptr);
    ~MediaPalettePlugin() override = default;

    QColor primary() const;
    QColor onPrimary() const;
    QColor track() const;

    Q_INVOKABLE void extract(const QString &artUrl, const QColor &fallback);

signals:
    void paletteChanged();

private:
    bool applyPalette(const QColor &primary, const QColor &onPrimary, const QColor &track);

    QString m_lastArtUrl;
    QColor m_lastFallback;
    QColor m_primary;
    QColor m_onPrimary;
    QColor m_track;
};

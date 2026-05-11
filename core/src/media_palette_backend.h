#pragma once

#include <QColor>
#include <QString>

struct MediaPalette {
    QColor primary;
    QColor onPrimary;
    QColor track;
};

class MediaPaletteBackend {
public:
    static MediaPalette extract(const QString &artUrl, const QColor &fallback);
    static MediaPalette fallbackPalette(const QColor &fallback);
};

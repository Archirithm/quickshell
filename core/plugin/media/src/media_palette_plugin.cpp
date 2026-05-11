#include "media_palette_plugin.h"

#include "media_palette_backend.h"

MediaPalettePlugin::MediaPalettePlugin(QObject *parent)
    : QObject(parent)
{
    const MediaPalette palette = MediaPaletteBackend::fallbackPalette(QColor(QStringLiteral("#88d0ec")));
    applyPalette(palette.primary, palette.onPrimary, palette.track);
}

QColor MediaPalettePlugin::primary() const
{
    return m_primary;
}

QColor MediaPalettePlugin::onPrimary() const
{
    return m_onPrimary;
}

QColor MediaPalettePlugin::track() const
{
    return m_track;
}

void MediaPalettePlugin::extract(const QString &artUrl, const QColor &fallback)
{
    const QString normalizedArtUrl = artUrl.trimmed();
    const QColor normalizedFallback = fallback.isValid() ? fallback : QColor(QStringLiteral("#88d0ec"));

    if (normalizedArtUrl == m_lastArtUrl && normalizedFallback == m_lastFallback)
        return;

    m_lastArtUrl = normalizedArtUrl;
    m_lastFallback = normalizedFallback;

    const MediaPalette palette = MediaPaletteBackend::extract(normalizedArtUrl, normalizedFallback);
    if (applyPalette(palette.primary, palette.onPrimary, palette.track))
        emit paletteChanged();
}

bool MediaPalettePlugin::applyPalette(const QColor &primary, const QColor &onPrimary, const QColor &track)
{
    if (m_primary == primary
        && m_onPrimary == onPrimary
        && m_track == track) {
        return false;
    }

    m_primary = primary;
    m_onPrimary = onPrimary;
    m_track = track;
    return true;
}

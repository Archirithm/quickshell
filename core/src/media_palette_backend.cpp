#include "media_palette_backend.h"

#include <QHash>
#include <QImage>
#include <QUrl>

#include <algorithm>
#include <cmath>
#include <vector>

namespace {

constexpr int kSampleSize = 112;
constexpr double kMinOklchChroma = 0.028;
constexpr double kPi = 3.14159265358979323846;

struct Bin {
    int count = 0;
    quint64 red = 0;
    quint64 green = 0;
    quint64 blue = 0;
};

struct Oklab {
    double l = 0.0;
    double a = 0.0;
    double b = 0.0;
};

struct Oklch {
    double l = 0.0;
    double c = 0.0;
    double h = 0.0;
};

struct Candidate {
    QColor color;
    Oklch oklch;
    int count = 0;
    double proportion = 0.0;
    double score = 0.0;
};

double clamp01(double value)
{
    return std::clamp(value, 0.0, 1.0);
}

double radiansToDegrees(double radians)
{
    return radians * 180.0 / kPi;
}

double degreesToRadians(double degrees)
{
    return degrees * kPi / 180.0;
}

double normalizeDegrees(double degrees)
{
    double normalized = std::fmod(degrees, 360.0);
    if (normalized < 0.0)
        normalized += 360.0;
    return normalized;
}

QColor safeFallback(const QColor &fallback)
{
    if (fallback.isValid())
        return fallback;
    return QColor(QStringLiteral("#88d0ec"));
}

QImage loadImage(const QString &artUrl)
{
    const QString source = artUrl.trimmed();
    if (source.isEmpty())
        return {};

    const QUrl url(source);
    if (url.isValid() && url.isLocalFile())
        return QImage(url.toLocalFile());

    if (source.startsWith(QStringLiteral("qrc:"), Qt::CaseInsensitive)
        || source.startsWith(QStringLiteral(":/"))) {
        return QImage(source);
    }

    if (!url.isValid() || url.scheme().isEmpty())
        return QImage(source);

    return {};
}

double srgbToLinear(double channel)
{
    if (channel <= 0.04045)
        return channel / 12.92;
    return std::pow((channel + 0.055) / 1.055, 2.4);
}

double linearToSrgb(double channel)
{
    if (channel <= 0.0031308)
        return 12.92 * channel;
    return 1.055 * std::pow(channel, 1.0 / 2.4) - 0.055;
}

Oklab colorToOklab(const QColor &color)
{
    const QColor rgb = color.toRgb();
    const double r = srgbToLinear(rgb.redF());
    const double g = srgbToLinear(rgb.greenF());
    const double b = srgbToLinear(rgb.blueF());

    const double l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
    const double m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
    const double s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;

    const double lRoot = std::cbrt(l);
    const double mRoot = std::cbrt(m);
    const double sRoot = std::cbrt(s);

    return {
        0.2104542553 * lRoot + 0.7936177850 * mRoot - 0.0040720468 * sRoot,
        1.9779984951 * lRoot - 2.4285922050 * mRoot + 0.4505937099 * sRoot,
        0.0259040371 * lRoot + 0.7827717662 * mRoot - 0.8086757660 * sRoot
    };
}

Oklch oklabToOklch(const Oklab &lab)
{
    const double chroma = std::sqrt(lab.a * lab.a + lab.b * lab.b);
    const double hue = chroma <= 0.000001 ? 0.0 : normalizeDegrees(radiansToDegrees(std::atan2(lab.b, lab.a)));
    return { lab.l, chroma, hue };
}

Oklab oklchToOklab(const Oklch &lch)
{
    const double hueRadians = degreesToRadians(lch.h);
    return {
        lch.l,
        lch.c * std::cos(hueRadians),
        lch.c * std::sin(hueRadians)
    };
}

QColor oklabToColor(const Oklab &lab)
{
    const double lRoot = lab.l + 0.3963377774 * lab.a + 0.2158037573 * lab.b;
    const double mRoot = lab.l - 0.1055613458 * lab.a - 0.0638541728 * lab.b;
    const double sRoot = lab.l - 0.0894841775 * lab.a - 1.2914855480 * lab.b;

    const double l = lRoot * lRoot * lRoot;
    const double m = mRoot * mRoot * mRoot;
    const double s = sRoot * sRoot * sRoot;

    const double r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
    const double g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
    const double b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;

    return QColor::fromRgbF(
        clamp01(linearToSrgb(r)),
        clamp01(linearToSrgb(g)),
        clamp01(linearToSrgb(b)),
        1.0
    );
}

QColor oklchToColor(const Oklch &lch)
{
    return oklabToColor(oklchToOklab(lch));
}

double relativeLuminance(const QColor &color)
{
    const QColor rgb = color.toRgb();
    return 0.2126 * srgbToLinear(rgb.redF())
        + 0.7152 * srgbToLinear(rgb.greenF())
        + 0.0722 * srgbToLinear(rgb.blueF());
}

double contrastRatio(const QColor &a, const QColor &b)
{
    const double l1 = relativeLuminance(a);
    const double l2 = relativeLuminance(b);
    const double lighter = std::max(l1, l2);
    const double darker = std::min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
}

QColor readableForeground(const QColor &background)
{
    const QColor dark(QStringLiteral("#101418"));
    const QColor light(QStringLiteral("#ffffff"));
    return contrastRatio(background, dark) >= contrastRatio(background, light) ? dark : light;
}

Oklch fallbackOklch(const QColor &fallback)
{
    Oklch lch = oklabToOklch(colorToOklab(safeFallback(fallback)));
    if (lch.c < 0.045)
        lch.c = 0.10;
    return lch;
}

QColor makeUiColor(Oklch lch, double lightness, double chromaScale, double minChroma, double maxChroma)
{
    lch.l = std::clamp(lightness, 0.0, 1.0);
    lch.c = std::clamp(lch.c * chromaScale, minChroma, maxChroma);
    return oklchToColor(lch);
}

MediaPalette paletteFromCandidates(const std::vector<Candidate> &candidates, const QColor &fallback)
{
    Candidate primaryCandidate;
    if (candidates.empty()) {
        primaryCandidate.color = safeFallback(fallback);
        primaryCandidate.oklch = fallbackOklch(fallback);
    } else {
        primaryCandidate = candidates.front();
    }

    const Oklch primaryLch = primaryCandidate.oklch;

    MediaPalette palette;
    palette.primary = makeUiColor(primaryLch, std::clamp(primaryLch.l, 0.62, 0.78), 1.12, 0.070, 0.220);
    palette.onPrimary = readableForeground(palette.primary);
    palette.track = makeUiColor(primaryLch, std::clamp(primaryLch.l * 0.58, 0.30, 0.42), 0.42, 0.025, 0.080);
    return palette;
}

std::vector<Candidate> collectCandidates(const QImage &input)
{
    QImage image = input.scaled(
        kSampleSize,
        kSampleSize,
        Qt::IgnoreAspectRatio,
        Qt::SmoothTransformation
    ).convertToFormat(QImage::Format_ARGB32);

    QHash<int, Bin> bins;
    int totalOpaque = 0;

    for (int y = 0; y < image.height(); ++y) {
        const auto *line = reinterpret_cast<const QRgb *>(image.constScanLine(y));
        for (int x = 0; x < image.width(); ++x) {
            const QRgb pixel = line[x];
            if (qAlpha(pixel) < 250)
                continue;

            const int red = qRed(pixel);
            const int green = qGreen(pixel);
            const int blue = qBlue(pixel);
            const int key = ((red >> 3) << 10) | ((green >> 3) << 5) | (blue >> 3);
            Bin &bin = bins[key];
            bin.count += 1;
            bin.red += static_cast<quint64>(red);
            bin.green += static_cast<quint64>(green);
            bin.blue += static_cast<quint64>(blue);
            totalOpaque += 1;
        }
    }

    std::vector<Candidate> candidates;
    candidates.reserve(static_cast<size_t>(bins.size()));

    for (const Bin &bin : bins) {
        if (bin.count <= 0)
            continue;

        const QColor color(
            static_cast<int>(bin.red / static_cast<quint64>(bin.count)),
            static_cast<int>(bin.green / static_cast<quint64>(bin.count)),
            static_cast<int>(bin.blue / static_cast<quint64>(bin.count))
        );
        const Oklch lch = oklabToOklch(colorToOklab(color));

        if (lch.c < kMinOklchChroma || lch.l < 0.12 || lch.l > 0.94)
            continue;

        const double proportion = totalOpaque > 0
            ? static_cast<double>(bin.count) / static_cast<double>(totalOpaque)
            : 0.0;
        const double lightnessScore = 1.0 - std::min(std::abs(lch.l - 0.58) / 0.42, 1.0);
        const double chromaScore = std::min(lch.c / 0.24, 1.0);
        const double presencePenalty = proportion < 0.002 ? 0.65 : 1.0;

        Candidate candidate;
        candidate.color = color;
        candidate.oklch = lch;
        candidate.count = bin.count;
        candidate.proportion = proportion;
        candidate.score = (
            std::sqrt(proportion) * 70.0
            + chromaScore * 34.0
            + lightnessScore * 10.0
        ) * presencePenalty;
        candidates.push_back(candidate);
    }

    std::sort(candidates.begin(), candidates.end(), [](const Candidate &a, const Candidate &b) {
        return a.score > b.score;
    });

    return candidates;
}

} // namespace

MediaPalette MediaPaletteBackend::extract(const QString &artUrl, const QColor &fallback)
{
    const QColor safe = safeFallback(fallback);
    const QImage image = loadImage(artUrl);
    if (image.isNull())
        return fallbackPalette(safe);

    return paletteFromCandidates(collectCandidates(image), safe);
}

MediaPalette MediaPaletteBackend::fallbackPalette(const QColor &fallback)
{
    return paletteFromCandidates({}, safeFallback(fallback));
}

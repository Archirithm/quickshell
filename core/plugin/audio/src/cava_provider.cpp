#include "cava_provider.h"

#include "audio_collector.h"

#include <algorithm>
#include <QDebug>

CavaProvider::CavaProvider(QObject* parent)
    : QObject(parent)
    , m_values(m_bars, 0.0)
    , m_input(AudioCollector::ChunkSize, 0.0)
    , m_output(m_bars, 0.0)
{
    m_timer.setInterval(static_cast<int>(AudioCollector::ChunkSize * 1000.0 / AudioCollector::SampleRate));
    m_timer.setTimerType(Qt::PreciseTimer);
    connect(&m_timer, &QTimer::timeout, this, &CavaProvider::process);
    rebuildCava();
}

CavaProvider::~CavaProvider()
{
    setActive(false);
    destroyCava();
}

bool CavaProvider::active() const
{
    return m_active;
}

void CavaProvider::setActive(bool active)
{
    if (m_active == active)
        return;

    m_active = active;
    emit activeChanged();

    if (m_active) {
        rebuildCava();
        AudioCollector::instance().start();
        m_timer.start();
    } else {
        m_timer.stop();
        AudioCollector::instance().stop();
        resetValues();
    }
}

bool CavaProvider::available() const
{
    return m_available;
}

int CavaProvider::bars() const
{
    return m_bars;
}

void CavaProvider::setBars(int bars)
{
    bars = std::max(0, bars);
    if (m_bars == bars)
        return;

    m_bars = bars;
    m_values = QVector<double>(m_bars, 0.0);
    m_output = QVector<double>(m_bars, 0.0);
    emit barsChanged();
    emit valuesChanged();
    rebuildCava();
}

QVector<double> CavaProvider::values() const
{
    return m_values;
}

void CavaProvider::process()
{
    if (!m_active || !m_plan || m_bars <= 0)
        return;

    const int count = static_cast<int>(AudioCollector::instance().readChunk(m_input.data(), AudioCollector::ChunkSize));
    cava_execute(m_input.data(), count, m_output.data(), m_plan);

    QVector<double> next(m_bars, 0.0);
    const double falloff = 1.0 / 1.5;
    double carry = 0.0;

    for (int i = 0; i < m_bars; ++i) {
        carry = std::max(m_output[i], carry * falloff);
        next[i] = carry;
    }

    carry = 0.0;
    for (int i = m_bars - 1; i >= 0; --i) {
        carry = std::max(m_output[i], carry * falloff);
        next[i] = std::max(next[i], carry);
    }

    if (next != m_values) {
        m_values = next;
        emit valuesChanged();
    }
}

void CavaProvider::rebuildCava()
{
    destroyCava();
    if (m_bars <= 0) {
        setAvailable(false);
        return;
    }

    m_plan = cava_init(m_bars, AudioCollector::SampleRate, 1, 1, 0.85, 50, 10000);
    if (!m_plan) {
        qWarning() << "[ClavisAudio] Failed to initialise libcava";
        setAvailable(false);
        return;
    }

    std::fill(m_output.begin(), m_output.end(), 0.0);
    setAvailable(true);
}

void CavaProvider::destroyCava()
{
    if (!m_plan)
        return;

    cava_destroy(m_plan);
    m_plan = nullptr;
}

void CavaProvider::setAvailable(bool available)
{
    if (m_available == available)
        return;

    m_available = available;
    emit availableChanged();
}

void CavaProvider::resetValues()
{
    QVector<double> zeroes(m_bars, 0.0);
    if (m_values == zeroes)
        return;

    m_values = zeroes;
    emit valuesChanged();
}

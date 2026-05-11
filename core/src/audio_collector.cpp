#include "audio_collector.h"

#include <algorithm>
#include <cstring>
#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>
#include <spa/param/latency-utils.h>
#include <QDebug>

namespace {

struct PipewireState {
    AudioCollector* collector = nullptr;
    pw_main_loop* loop = nullptr;
    pw_stream* stream = nullptr;
    spa_source* timer = nullptr;
    std::atomic_bool* stopRequested = nullptr;
};

unsigned int nextPowerOf2(unsigned int value)
{
    if (value == 0)
        return 1;

    value--;
    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    value++;

    return value;
}

void handleTimer(void* data, uint64_t)
{
    auto* state = static_cast<PipewireState*>(data);
    if (state->stopRequested && state->stopRequested->load(std::memory_order_acquire) && state->loop)
        pw_main_loop_quit(state->loop);
}

void handleProcess(void* data)
{
    auto* state = static_cast<PipewireState*>(data);
    if (!state->stream || !state->collector)
        return;

    pw_buffer* buffer = pw_stream_dequeue_buffer(state->stream);
    if (!buffer)
        return;

    const spa_buffer* spaBuffer = buffer->buffer;
    const auto* samples = static_cast<const int16_t*>(spaBuffer->datas[0].data);
    if (samples && spaBuffer->datas[0].chunk) {
        const uint32_t count = spaBuffer->datas[0].chunk->size / sizeof(int16_t);
        state->collector->loadSamples(samples, count);
    }

    pw_stream_queue_buffer(state->stream, buffer);
}

void handleStateChanged(void* data, pw_stream_state, pw_stream_state state, const char*)
{
    auto* pwState = static_cast<PipewireState*>(data);
    if (state == PW_STREAM_STATE_ERROR && pwState->loop)
        pw_main_loop_quit(pwState->loop);
}

} // namespace

AudioCollector& AudioCollector::instance()
{
    static AudioCollector collector;
    return collector;
}

AudioCollector::AudioCollector()
    : m_buffer(ChunkSize, 0.0f)
    , m_stopRequested(false)
{
}

AudioCollector::~AudioCollector()
{
    stop();
}

void AudioCollector::start()
{
    if (m_thread.joinable())
        return;

    clear();
    m_stopRequested.store(false, std::memory_order_release);
    m_thread = std::thread(&AudioCollector::runPipewire, this);
}

void AudioCollector::stop()
{
    if (!m_thread.joinable())
        return;

    m_stopRequested.store(true, std::memory_order_release);
    m_thread.join();
    clear();
}

void AudioCollector::clear()
{
    std::scoped_lock lock(m_mutex);
    std::fill(m_buffer.begin(), m_buffer.end(), 0.0f);
}

void AudioCollector::loadSamples(const int16_t* samples, uint32_t count)
{
    if (!samples)
        return;

    count = std::min<uint32_t>(count, ChunkSize);

    std::scoped_lock lock(m_mutex);
    std::fill(m_buffer.begin(), m_buffer.end(), 0.0f);
    std::transform(samples, samples + count, m_buffer.begin(), [](int16_t sample) {
        return static_cast<float>(sample) / 32768.0f;
    });
}

uint32_t AudioCollector::readChunk(double* out, uint32_t count)
{
    if (!out)
        return 0;

    count = std::min<uint32_t>(count == 0 ? ChunkSize : count, ChunkSize);

    std::scoped_lock lock(m_mutex);
    std::transform(m_buffer.begin(), m_buffer.begin() + count, out, [](float sample) {
        return static_cast<double>(sample);
    });

    return count;
}

void AudioCollector::runPipewire()
{
    pw_init(nullptr, nullptr);

    PipewireState state;
    state.collector = this;
    state.stopRequested = &m_stopRequested;
    state.loop = pw_main_loop_new(nullptr);
    if (!state.loop) {
        qWarning() << "[ClavisAudio] Failed to create PipeWire main loop";
        pw_deinit();
        return;
    }

    timespec timerInterval = { 0, 50 * SPA_NSEC_PER_MSEC };
    state.timer = pw_loop_add_timer(pw_main_loop_get_loop(state.loop), handleTimer, &state);
    if (!state.timer) {
        qWarning() << "[ClavisAudio] Failed to create PipeWire stop timer";
        pw_main_loop_destroy(state.loop);
        pw_deinit();
        return;
    }
    pw_loop_update_timer(pw_main_loop_get_loop(state.loop), state.timer, &timerInterval, &timerInterval, false);

    auto* props = pw_properties_new(
        PW_KEY_MEDIA_TYPE, "Audio",
        PW_KEY_MEDIA_CATEGORY, "Capture",
        PW_KEY_MEDIA_ROLE, "Music",
        nullptr);
    pw_properties_set(props, PW_KEY_STREAM_CAPTURE_SINK, "true");
    pw_properties_setf(
        props, PW_KEY_NODE_LATENCY,
        "%u/%u",
        nextPowerOf2(ChunkSize * SampleRate / 48000),
        SampleRate);
    pw_properties_set(props, PW_KEY_NODE_PASSIVE, "true");
    pw_properties_set(props, PW_KEY_NODE_VIRTUAL, "true");
    pw_properties_set(props, PW_KEY_STREAM_DONT_REMIX, "false");
    pw_properties_set(props, "channelmix.upmix", "true");

    std::vector<uint8_t> paramBuffer(1024);
    spa_pod_builder builder;
    spa_pod_builder_init(&builder, paramBuffer.data(), static_cast<uint32_t>(paramBuffer.size()));

    spa_audio_info_raw info {};
    info.format = SPA_AUDIO_FORMAT_S16;
    info.rate = SampleRate;
    info.channels = 1;

    const spa_pod* params[1];
    params[0] = spa_format_audio_raw_build(&builder, SPA_PARAM_EnumFormat, &info);

    pw_stream_events events {};
    events.version = PW_VERSION_STREAM_EVENTS;
    events.state_changed = handleStateChanged;
    events.process = handleProcess;

    state.stream = pw_stream_new_simple(pw_main_loop_get_loop(state.loop), "clavis-shell-audio", props, &events, &state);
    if (!state.stream) {
        qWarning() << "[ClavisAudio] Failed to create PipeWire stream";
        pw_main_loop_destroy(state.loop);
        pw_deinit();
        return;
    }

    const int result = pw_stream_connect(
        state.stream,
        PW_DIRECTION_INPUT,
        PW_ID_ANY,
        static_cast<pw_stream_flags>(PW_STREAM_FLAG_AUTOCONNECT | PW_STREAM_FLAG_MAP_BUFFERS | PW_STREAM_FLAG_RT_PROCESS),
        params,
        1);
    if (result < 0) {
        qWarning() << "[ClavisAudio] Failed to connect PipeWire stream";
        pw_stream_destroy(state.stream);
        pw_main_loop_destroy(state.loop);
        pw_deinit();
        return;
    }

    pw_main_loop_run(state.loop);

    pw_stream_destroy(state.stream);
    pw_main_loop_destroy(state.loop);
    pw_deinit();
}

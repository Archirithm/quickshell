#pragma once

#include <atomic>
#include <cstdint>
#include <mutex>
#include <thread>
#include <vector>

class AudioCollector {
public:
    static constexpr uint32_t SampleRate = 44100;
    static constexpr uint32_t ChunkSize = 512;

    AudioCollector(const AudioCollector&) = delete;
    AudioCollector& operator=(const AudioCollector&) = delete;

    static AudioCollector& instance();

    void start();
    void stop();
    void clear();
    void loadSamples(const int16_t* samples, uint32_t count);
    uint32_t readChunk(double* out, uint32_t count = ChunkSize);

private:
    AudioCollector();
    ~AudioCollector();

    std::vector<float> m_buffer;
    std::mutex m_mutex;
    std::thread m_thread;
    std::atomic_bool m_stopRequested;

    void runPipewire();
};

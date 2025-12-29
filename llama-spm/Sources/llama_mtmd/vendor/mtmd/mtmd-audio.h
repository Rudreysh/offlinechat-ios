#pragma once

#include "clip-model.h"
#include <cstddef>
#include <vector>

struct mtmd_audio_mel {
    int n_len = 0;
    int n_len_org = 0;
    int n_mel = 0;
    std::vector<float> data;
};

struct mtmd_audio_preprocessor {
    const clip_hparams & hparams;

    mtmd_audio_preprocessor(const clip_ctx * ctx) : hparams(*clip_get_hparams(ctx)) {}
    virtual ~mtmd_audio_preprocessor() = default;
    virtual void initialize() {}
    virtual bool preprocess(const float * /*samples*/, size_t /*n_samples*/, std::vector<mtmd_audio_mel> & /*output*/) {
        return false;
    }
};

struct mtmd_audio_preprocessor_whisper : mtmd_audio_preprocessor {
    mtmd_audio_preprocessor_whisper(const clip_ctx * ctx) : mtmd_audio_preprocessor(ctx) {}
    void initialize() override {}
    bool preprocess(const float * samples, size_t n_samples, std::vector<mtmd_audio_mel> & output) override {
        (void)samples; (void)n_samples; (void)output;
        return false;
    }
};

struct mtmd_audio_preprocessor_conformer : mtmd_audio_preprocessor {
    mtmd_audio_preprocessor_conformer(const clip_ctx * ctx) : mtmd_audio_preprocessor(ctx) {}
    void initialize() override {}
    bool preprocess(const float * samples, size_t n_samples, std::vector<mtmd_audio_mel> & output) override {
        (void)samples; (void)n_samples; (void)output;
        return false;
    }
};

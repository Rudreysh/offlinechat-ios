#import "llama_mtmd.h"

#include "mtmd/mtmd.h"
#include "mtmd/mtmd-helper.h"

bool llama_mtmd_is_available(void) {
    return true;
}

const char * llama_mtmd_default_marker(void) {
    return mtmd_default_marker();
}

mtmd_context * llama_mtmd_create_from_file(const char * mmproj_path,
                                           const struct llama_model * model,
                                           int n_threads) {
    mtmd_context_params params = mtmd_context_params_default();
    params.n_threads = n_threads;
    return mtmd_init_from_file(mmproj_path, model, params);
}

void llama_mtmd_destroy(mtmd_context * ctx) {
    if (ctx) {
        mtmd_free(ctx);
    }
}

mtmd_bitmap * llama_mtmd_bitmap_create_rgb(const uint8_t * data, uint32_t width, uint32_t height) {
    return mtmd_bitmap_init(width, height, data);
}

void llama_mtmd_bitmap_destroy(mtmd_bitmap * bitmap) {
    if (bitmap) {
        mtmd_bitmap_free(bitmap);
    }
}

mtmd_input_chunks * llama_mtmd_tokenize_prompt_single(mtmd_context * ctx,
                                                      const char * prompt,
                                                      bool add_special,
                                                      bool parse_special,
                                                      const mtmd_bitmap * bitmap) {
    if (!ctx || !prompt) {
        return nullptr;
    }

    mtmd_input_chunks * chunks = mtmd_input_chunks_init();
    if (!chunks) {
        return nullptr;
    }

    mtmd_input_text text;
    text.text = prompt;
    text.add_special = add_special;
    text.parse_special = parse_special;

    const mtmd_bitmap * bitmaps[1] = { bitmap };
    size_t n_bitmaps = bitmap ? 1 : 0;

    int32_t res = mtmd_tokenize(ctx, chunks, &text, bitmaps, n_bitmaps);
    if (res != 0) {
        mtmd_input_chunks_free(chunks);
        return nullptr;
    }

    return chunks;
}

int32_t llama_mtmd_eval_chunks(mtmd_context * ctx,
                               struct llama_context * lctx,
                               const mtmd_input_chunks * chunks,
                               llama_pos n_past,
                               llama_seq_id seq_id,
                               int32_t n_batch,
                               bool logits_last,
                               llama_pos * new_n_past) {
    return mtmd_helper_eval_chunks(ctx, lctx, chunks, n_past, seq_id, n_batch, logits_last, new_n_past);
}

void llama_mtmd_chunks_free(mtmd_input_chunks * chunks) {
    if (chunks) {
        mtmd_input_chunks_free(chunks);
    }
}

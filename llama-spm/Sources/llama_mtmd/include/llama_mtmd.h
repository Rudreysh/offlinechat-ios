#pragma once
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Minimal llama forward declarations (avoid including llama.h)
struct llama_context;
struct llama_model;

typedef int32_t llama_pos;
typedef int32_t llama_seq_id;

// Opaque mtmd types for Swift
struct mtmd_context;
struct mtmd_bitmap;
struct mtmd_input_chunks;

typedef struct mtmd_context mtmd_context;
typedef struct mtmd_bitmap mtmd_bitmap;
typedef struct mtmd_input_chunks mtmd_input_chunks;

bool llama_mtmd_is_available(void);
const char * llama_mtmd_default_marker(void);

mtmd_context * llama_mtmd_create_from_file(const char * mmproj_path,
                                           const struct llama_model * model,
                                           int n_threads);
void llama_mtmd_destroy(mtmd_context * ctx);

mtmd_bitmap * llama_mtmd_bitmap_create_rgb(const uint8_t * data, uint32_t width, uint32_t height);
void llama_mtmd_bitmap_destroy(mtmd_bitmap * bitmap);

mtmd_input_chunks * llama_mtmd_tokenize_prompt_single(mtmd_context * ctx,
                                                      const char * prompt,
                                                      bool add_special,
                                                      bool parse_special,
                                                      const mtmd_bitmap * bitmap);

int32_t llama_mtmd_eval_chunks(mtmd_context * ctx,
                               struct llama_context * lctx,
                               const mtmd_input_chunks * chunks,
                               llama_pos n_past,
                               llama_seq_id seq_id,
                               int32_t n_batch,
                               bool logits_last,
                               llama_pos * new_n_past);

void llama_mtmd_chunks_free(mtmd_input_chunks * chunks);

#ifdef __cplusplus
} // extern "C"
#endif

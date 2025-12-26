#ifndef llama_mtmd_h
#define llama_mtmd_h

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Forward declaration of llama_model from llama.h
struct llama_model;

typedef struct llama_mtmd_ctx llama_mtmd_ctx;

typedef struct {
    int32_t * tokens;
    size_t count;
} llama_mtmd_tokens;

// Initialize multimodal context associated with a llama model
llama_mtmd_ctx * llama_mtmd_create_context(const char * mmproj_path);

void llama_mtmd_free_context(llama_mtmd_ctx * ctx);

// Embed image and return tokens. Returns true on success.
// tokens->tokens must be freed with llama_mtmd_free_tokens
bool llama_mtmd_embed_image(llama_mtmd_ctx * ctx, const char * image_path, llama_mtmd_tokens * out_tokens);

void llama_mtmd_free_tokens(int32_t * tokens);

#ifdef __cplusplus
}
#endif

#endif /* llama_mtmd_h */

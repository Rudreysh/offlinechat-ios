#import "include/llama_mtmd.h"
#include <iostream>
#include <vector>

// Include standard llama headers if available from the framework
// We expect them to be available via header search paths from 'llama' target
#if __has_include(<llama/llama.h>)
#include <llama/llama.h>
#else
#include "llama.h"
#endif

struct llama_mtmd_ctx {
  void *placeholder;
};

llama_mtmd_ctx *llama_mtmd_create_context(const char *mmproj_path) {
  if (!mmproj_path)
    return NULL;
  llama_mtmd_ctx *ctx = new llama_mtmd_ctx();
  ctx->placeholder = nullptr;
  return ctx;
}

void llama_mtmd_free_context(llama_mtmd_ctx *ctx) {
  if (!ctx)
    return;
  delete ctx;
}

bool llama_mtmd_embed_image(llama_mtmd_ctx *ctx, const char *image_path,
                            llama_mtmd_tokens *out_tokens) {
  if (!ctx || !image_path || !out_tokens)
    return false;
  out_tokens->tokens = nullptr;
  out_tokens->count = 0;
  return false;
}

void llama_mtmd_free_tokens(int32_t *tokens) {
  if (tokens) {
    free(tokens);
  }
}

#include "llama_mtmd.h"
#include <dlfcn.h>

typedef const char * (*mtmd_default_marker_fn)(void);
typedef void * (*mtmd_init_from_file_fn)(const char *, const void *, void *);
typedef void (*mtmd_free_fn)(void *);

static bool mtmd_symbols_available(void) {
    void * sym_marker = dlsym(RTLD_DEFAULT, "mtmd_default_marker");
    void * sym_init = dlsym(RTLD_DEFAULT, "mtmd_init_from_file");
    void * sym_free = dlsym(RTLD_DEFAULT, "mtmd_free");
    return sym_marker && sym_init && sym_free;
}

bool llama_mtmd_is_available(void) {
    return mtmd_symbols_available();
}

/* Stub archive implementation for tcc compatibility */
/* Real implementation uses libarchive, but tcc can't link against it */

int owl_archive_extract(const char *input, const char *destination) {
    (void)input;
    (void)destination;
    return -1; /* not implemented */
}

int owl_archive_available(void) {
    return 0; /* not available */
}

int owl_archive_pack(const char *root, const char *output) {
    (void)root;
    (void)output;
    return -1; /* not implemented */
}

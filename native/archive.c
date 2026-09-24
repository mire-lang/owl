#include <archive.h>
#include <archive_entry.h>
#include <errno.h>
#include <stdio.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>

/* Owl's archive bridge deliberately exposes only two narrow operations. The
 * Mire process never starts tar/zstd: libarchive selects the zstd filter and
 * performs the archive traversal in-process. */
int owl_archive_available(void) { return 1; }

int owl_archive_pack(const char *root, const char *output) {
    struct archive *reader = archive_read_disk_new();
    struct archive *writer = archive_write_new();
    struct archive_entry *entry;
    const void *buffer;
    size_t size;
    la_int64_t offset;
    int rc = -1;
    char root_real[PATH_MAX];
    if (!reader || !writer) { fprintf(stderr, "archive: allocation failed\n"); goto done; }
    if (!realpath(root, root_real)) { fprintf(stderr, "archive: root: %s\n", strerror(errno)); goto done; }
    archive_read_disk_set_standard_lookup(reader);
    if (archive_write_set_format_pax_restricted(writer) != ARCHIVE_OK) { fprintf(stderr, "archive: format: %s\n", archive_error_string(writer)); goto done; }
    if (archive_write_add_filter_zstd(writer) != ARCHIVE_OK) { fprintf(stderr, "archive: zstd: %s\n", archive_error_string(writer)); goto done; }
    if (archive_write_open_filename(writer, output) != ARCHIVE_OK) { fprintf(stderr, "archive: open output: %s\n", archive_error_string(writer)); goto done; }
    if (archive_read_disk_open(reader, root) != ARCHIVE_OK) { fprintf(stderr, "archive: open root: %s\n", archive_error_string(reader)); goto done; }
    int header_rc;
    while ((header_rc = archive_read_next_header(reader, &entry)) == ARCHIVE_OK) {
        const char *absolute_name = archive_entry_pathname(entry);
        const char *base = root_real;
        size_t root_len = strlen(root_real);
        if (strncmp(absolute_name, root_real, root_len) != 0) {
            base = root;
            root_len = strlen(root);
            if (strncmp(absolute_name, base, root_len) != 0) {
                fprintf(stderr, "archive: entry escapes root: %s vs %s\n", absolute_name, root_real); goto done;
            }
        }
        const char *relative_name = absolute_name + root_len;
        while (*relative_name == '/') relative_name++;
        archive_entry_set_pathname(entry, relative_name[0] ? relative_name : ".");
        if (archive_write_header(writer, entry) != ARCHIVE_OK) { fprintf(stderr, "archive: header: %s\n", archive_error_string(writer)); goto done; }
        while (archive_read_data_block(reader, &buffer, &size, &offset) == ARCHIVE_OK) {
            (void)offset;
            if (archive_write_data(writer, buffer, size) < 0) { fprintf(stderr, "archive: data: %s\n", archive_error_string(writer)); goto done; }
        }
        archive_read_disk_descend(reader);
    }
    if (header_rc != ARCHIVE_EOF) { fprintf(stderr, "archive: read: %s\n", archive_error_string(reader)); goto done; }
    rc = archive_write_close(writer) == ARCHIVE_OK ? 0 : -1;
done:
    if (reader) archive_read_free(reader);
    if (writer) archive_write_free(writer);
    return rc;
}

static int safe_entry_path(const char *path) {
    if (!path || path[0] == '/') return 0;
    if (strstr(path, "../") || strcmp(path, "..") == 0 ||
        strstr(path, "/..") || strstr(path, "\\..")) return 0;
    return 1;
}

int owl_archive_extract(const char *input, const char *destination) {
    struct archive *reader = archive_read_new();
    struct archive *disk = archive_write_disk_new();
    struct archive_entry *entry;
    int rc = -1;
    if (!reader || !disk) goto done;
    archive_read_support_filter_zstd(reader);
    archive_read_support_format_tar(reader);
    archive_write_disk_set_options(disk, ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM |
        ARCHIVE_EXTRACT_ACL | ARCHIVE_EXTRACT_FFLAGS |
        ARCHIVE_EXTRACT_SECURE_SYMLINKS);
    if (archive_read_open_filename(reader, input, 10240) != ARCHIVE_OK) goto done;
    while (archive_read_next_header(reader, &entry) == ARCHIVE_OK) {
        const char *name = archive_entry_pathname(entry);
        if (!safe_entry_path(name)) { fprintf(stderr, "extract: unsafe path %s\n", name ? name : "(null)"); errno = EINVAL; goto done; }
        char full[4096];
        if (snprintf(full, sizeof(full), "%s/%s", destination, name) >= (int)sizeof(full)) {
            errno = ENAMETOOLONG; goto done;
        }
        archive_entry_set_pathname(entry, full);
        if (archive_write_header(disk, entry) != ARCHIVE_OK) { fprintf(stderr, "extract: header %s\n", archive_error_string(disk)); goto done; }
        const void *buffer;
        size_t size;
        la_int64_t offset;
        while (archive_read_data_block(reader, &buffer, &size, &offset) == ARCHIVE_OK) {
            (void)offset;
            if (archive_write_data(disk, buffer, size) < 0) {
                fprintf(stderr, "extract: data %s\n", archive_error_string(disk)); goto done;
            }
        }
        archive_write_finish_entry(disk);
    }
    rc = 0;
done:
    if (reader) archive_read_free(reader);
    if (disk) archive_write_free(disk);
    return rc;
}

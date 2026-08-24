# bounded-read

Safely emits a byte-bounded regular file owned by the current user. It walks
an absolute path with descriptor-relative `O_NOFOLLOW`, opens the final file
with `O_NONBLOCK`, verifies regular-file type and ownership on the descriptor,
and emits no partial output when the file exceeds its limit.

```bash
vendor/qmlpack/bounded-read/bin/bounded-read --max-bytes 65536 /absolute/path
```

The helper is intentionally small and depends only on Python 3's standard
library and Linux descriptor semantics.

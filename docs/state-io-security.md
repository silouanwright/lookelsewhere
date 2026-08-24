# State I/O Security Review

This review records the trust boundary around
`$XDG_STATE_HOME/look-elsewhere/state.json`. LookElsewhere runs inside the
long-lived Omarchy Shell process, so replaceable filesystem input must be
bounded and validated before it reaches QML.

## Threat model

The state pathname may be missing, oversized, a symbolic link, a FIFO, a
device, foreign-owned, or replaced while the plugin starts. The state contents
may be malformed JSON or contain unexpected values. Failures must not block or
allocate without a fixed ceiling in Quickshell, and must not overwrite the
original path after an unsafe load.

This is not a privilege boundary against arbitrary code already running as the
same user. Such code can modify the user's plugin, configuration, and state.
The controls here protect shell availability, accidental corruption, and the
smaller boundary posed by replaceable files and application-controlled desktop
metadata.

## Implemented boundary

- The reader is a dependency-free Python 3 script invoked through Omarchy's
  system `/usr/bin/python3`. Python is used only because its standard library
  exposes the descriptor-relative Linux operations needed here without adding
  a compiler, installer, or architecture-specific binary.
- `vendor/qmlpack/bounded-read/bin/bounded-read` opens each absolute path component relative to an
  already-open directory descriptor with `O_NOFOLLOW`.
- The final descriptor is opened read-only with `O_NONBLOCK`, checked with
  `fstat`, and accepted only when it is a regular file owned by the current
  user.
- At most 64 KiB is read. No bytes are emitted until the complete bounded read
  succeeds, so `StdioCollector` cannot retain partial oversized input.
- Missing state is treated as first run. Unsafe, malformed, or unsupported
  state blocks further persistence and preserves the original path.
- Active-window JSON is capped before QML and shaped to a 256-character
  application identifier plus a fullscreen boolean. Titles are discarded.
- The dedicated state directory is created and maintained with mode `0700`.
  A final-component symlink is rejected before directory preparation, and the
  reader independently rejects links in every component.
- Writes use Quickshell `FileView.atomicWrites`, which writes a temporary file
  and atomically renames it instead of opening the destination object.

The adversarial check covers exact-limit and oversized files, final and parent
symlinks, FIFOs, relative paths, and the ownership guard.

## Further hardening decisions

### Do now

1. Keep all filesystem reads entering QML behind producer-side byte limits and
   descriptor checks.
2. Normalize the parsed snapshot into the known state schema before scheduler
   use; reject non-finite numbers and unknown state names.
3. Keep asynchronous state-load time bounded so an unusual filesystem cannot
   leave scheduler initialization pending forever. `O_NONBLOCK` prevents FIFO
   waits, but does not guarantee nonblocking I/O for regular files.

### Add only if the storage boundary grows

- A descriptor-relative atomic writer that creates a `0600` temporary file,
  calls `fsync`, renames within the already-open directory, and syncs that
  directory. The present writer never opens `state.json` for writing, so the
  reported FIFO/type-confusion path does not apply to it.
- `openat2(RESOLVE_BENEATH | RESOLVE_NO_SYMLINKS)` in a compiled helper. The
  current standard-library descriptor walk provides the required no-symlink
  property without adding architecture-specific syscall bindings.
- Cross-process locking or generation checks. LookElsewhere currently has one
  writer; add coordination only if a daemon or CLI begins writing the same
  state.

## Review checklist for future inputs

Before adding a file, process, socket, or portal input to QML, answer:

1. Can its producer block indefinitely?
2. Is its byte count capped before `StdioCollector`, `FileView`, or JSON parsing?
3. Is only the smallest required shape retained?
4. Is the opened descriptor validated rather than a pre-open pathname?
5. Are failure, timeout, and stale-result behavior explicit?
6. Can unsafe input ever cause the plugin to overwrite the evidence?

## Primary references

- [Linux `openat2(2)`](https://man7.org/linux/man-pages/man2/openat2.2.html)
- [Linux `open(2)`](https://man7.org/linux/man-pages/man2/open.2.html)
- [Linux symbolic-link handling](https://man7.org/linux/man-pages/man7/symlink.7.html)
- [Linux `renameat2(2)`](https://man7.org/linux/man-pages/man2/renameat2.2.html)
- [Python descriptor-relative filesystem APIs](https://docs.python.org/3/library/os.html)
- [Quickshell `FileView`](https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/FileView/)
- [Quickshell `Process`](https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/Process/)
- [Qt `QSaveFile`](https://doc.qt.io/qt-6/qsavefile.html)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/)

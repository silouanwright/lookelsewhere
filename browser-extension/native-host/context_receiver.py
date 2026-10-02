"""Bound browser socket traffic outside the shared Quickshell process."""

import errno
import json
import os
import selectors
import signal
import socket
import stat
import struct
import sys
import time

from context_protocol import normalize

MAX_FRAME = 16 * 1024
MAX_CLIENTS = 8
READ_SIZE = 4096
FRAME_TIMEOUT = 2.0
IDLE_TIMEOUT = 15.0
EMIT_INTERVAL = 0.25
SOCKET_NAME = "look-elsewhere-browser.sock"


class Receiver:
    def __init__(self, runtime, output_fd):
        self.runtime = runtime
        self.output_fd = output_fd
        self.selector = selectors.DefaultSelector()
        self.clients = {}
        self.latest = None
        self.next_emit = 0.0
        self.stopped = False
        self.directory = None
        self.listener = None
        self.identity = None

    def start(self):
        # Keep the directory pinned for bind, stat and cleanup. The normal
        # XDG runtime directory is private and owned by this login user.
        if not os.path.isabs(self.runtime):
            raise ValueError("runtime directory must be absolute")
        self.directory = os.open(self.runtime, os.O_RDONLY | os.O_DIRECTORY
                                 | os.O_NOFOLLOW | os.O_CLOEXEC)
        metadata = os.fstat(self.directory)
        if metadata.st_uid != os.getuid() or metadata.st_mode & 0o077:
            raise ValueError("runtime directory must be private and user-owned")
        address = f"/proc/self/fd/{self.directory}/{SOCKET_NAME}"
        try:
            old = os.stat(SOCKET_NAME, dir_fd=self.directory, follow_symlinks=False)
        except FileNotFoundError:
            old = None
        if old is not None:
            if not stat.S_ISSOCK(old.st_mode) or old.st_uid != os.getuid():
                raise ValueError("refusing existing non-owned socket path")
            # Preserve a live receiver. Only a refused connection proves a
            # leftover socket after a crash; timeout/other errors fail closed.
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as probe:
                probe.settimeout(0.2)
                try:
                    probe.connect(address)
                except OSError as error:
                    if error.errno != errno.ECONNREFUSED:
                        raise
                else:
                    raise ValueError("browser context receiver already running")
            current = os.stat(SOCKET_NAME, dir_fd=self.directory, follow_symlinks=False)
            if (current.st_dev, current.st_ino) != (old.st_dev, old.st_ino):
                raise ValueError("socket path changed")
            os.unlink(SOCKET_NAME, dir_fd=self.directory)
        self.listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.listener.setblocking(False)
        self.listener.bind(address)
        current = os.stat(SOCKET_NAME, dir_fd=self.directory, follow_symlinks=False)
        self.identity = (current.st_dev, current.st_ino)
        self.listener.listen(MAX_CLIENTS)
        self.selector.register(self.listener, selectors.EVENT_READ)
        os.set_blocking(self.output_fd, False)

    def drop(self, connection):
        self.selector.unregister(connection)
        self.clients.pop(connection)
        connection.close()

    def accept(self, now):
        connection, _ = self.listener.accept()
        credentials = connection.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12)
        _, uid, _ = struct.unpack("3i", credentials)
        if uid != os.getuid() or len(self.clients) >= MAX_CLIENTS:
            connection.close()
            return
        connection.setblocking(False)
        self.clients[connection] = {"buffer": bytearray(), "started": None, "last": now}
        self.selector.register(connection, selectors.EVENT_READ)

    def receive(self, connection, now):
        state = self.clients[connection]
        # recv bounds allocation before framing, even without a newline. The
        # extra byte distinguishes an exact-limit frame from an overflow.
        data = connection.recv(min(READ_SIZE, MAX_FRAME + 1 - len(state["buffer"])))
        if not data:
            self.drop(connection)
            return
        state["last"] = now
        start = 0
        while start < len(data):
            if state["started"] is None:
                state["started"] = now
            end = data.find(b"\n", start)
            stop = len(data) if end < 0 else end
            if len(state["buffer"]) + stop - start > MAX_FRAME:
                self.drop(connection)
                return
            state["buffer"].extend(data[start:stop])
            if end < 0:
                return
            try:
                value = normalize(json.loads(state["buffer"]))
            except (ValueError, TypeError, RecursionError, UnicodeError):
                self.drop(connection)
                return
            # Drop unknown fields and coalesce updates. A valid-frame flood
            # cannot become an unbounded queue or stdout flood in the shell.
            self.latest = json.dumps(value, separators=(",", ":"), ensure_ascii=True).encode() + b"\n"
            state["buffer"].clear()
            state["started"] = None
            start = end + 1

    def run(self):
        self.start()
        while not self.stopped:
            now = time.monotonic()
            deadlines = [now + 1.0]
            if self.latest is not None:
                deadlines.append(self.next_emit)
            for state in self.clients.values():
                deadlines.append(state["last"] + IDLE_TIMEOUT)
                if state["started"] is not None:
                    deadlines.append(state["started"] + FRAME_TIMEOUT)
            for key, _ in self.selector.select(max(0, min(deadlines) - now)):
                now = time.monotonic()
                if key.fileobj is self.listener:
                    self.accept(now)
                else:
                    try:
                        self.receive(key.fileobj, now)
                    except (ConnectionError, OSError):
                        self.drop(key.fileobj)
            now = time.monotonic()
            for connection, state in list(self.clients.items()):
                if (now - state["last"] >= IDLE_TIMEOUT
                        or (state["started"] is not None
                            and now - state["started"] >= FRAME_TIMEOUT)):
                    self.drop(connection)
            if self.latest is not None and now >= self.next_emit:
                # Normalized output is <= 1 KiB, below Linux PIPE_BUF: this
                # nonblocking pipe write is all-or-nothing, never a new queue.
                if len(self.latest) > 1024:
                    raise ValueError("normalized context exceeds output limit")
                try:
                    written = os.write(self.output_fd, self.latest)
                    if written != len(self.latest):
                        raise OSError("partial context write")
                    self.latest = None
                except BlockingIOError:
                    pass
                self.next_emit = now + EMIT_INTERVAL

    def close(self):
        for connection in list(self.clients):
            self.drop(connection)
        self.selector.close()
        if self.listener is not None:
            self.listener.close()
        if self.directory is not None:
            try:
                current = os.stat(SOCKET_NAME, dir_fd=self.directory, follow_symlinks=False)
                if self.identity == (current.st_dev, current.st_ino):
                    os.unlink(SOCKET_NAME, dir_fd=self.directory)
            except FileNotFoundError:
                pass
            finally:
                os.close(self.directory)


def main():
    os.umask(0o077)
    receiver = Receiver(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}", 1)

    def stop(_signum, _frame):
        receiver.stopped = True

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        receiver.run()
    except (OSError, ValueError):
        # Do not echo attacker-controlled frames or paths into shell logs.
        print("LookElsewhere browser context receiver unavailable", file=sys.stderr)
        return 1
    finally:
        receiver.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

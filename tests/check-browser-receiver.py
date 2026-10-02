#!/usr/bin/python3
"""Exercise the production receiver with real Unix socket clients."""

import json
import os
from pathlib import Path
import select
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
HOST = ROOT / "browser-extension/native-host"
sys.path.insert(0, str(HOST))
from context_protocol import normalize


def message(sequence=1, **extra):
    return dict(version=1, session_id="fixture", sequence=sequence, browser="chromium",
                browser_focused=True, video_state="playing", video_visible=True,
                picture_in_picture=False, **extra)


def frame(sequence=1, **extra):
    return json.dumps(message(sequence, **extra), separators=(",", ":")).encode() + b"\n"


class ReceiverTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cache = Path.home() / ".cache"
        cache.mkdir(exist_ok=True)
        cls.fixture = Path(tempfile.mkdtemp(prefix="le-receiver-", dir=cache))

    @classmethod
    def tearDownClass(cls):
        subprocess.run(["gio", "trash", "--", str(cls.fixture)], check=True)

    def setUp(self):
        self.runtime = self.fixture / self._testMethodName.removeprefix("test_")
        self.runtime.mkdir(mode=0o700)
        self.path = str(self.runtime / "look-elsewhere-browser.sock")
        self.clients = []
        self.process = None
        self.output = b""

    def launch(self):
        return subprocess.Popen(
            ["/usr/bin/python3", "-B", "-E", "-s", str(HOST / "context_receiver.py")],
            env={"XDG_RUNTIME_DIR": str(self.runtime)},
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def start(self):
        self.process = self.launch()
        deadline = time.monotonic() + 3
        while not os.path.exists(self.path):
            if self.process.poll() is not None or time.monotonic() > deadline:
                self.fail("receiver did not start")
            time.sleep(0.01)

    def connect(self):
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.settimeout(3)
        self.clients.append(client)
        directory = os.open(self.runtime, os.O_RDONLY | os.O_DIRECTORY)
        try:
            deadline = time.monotonic() + 2
            while True:
                try:
                    client.connect(f"/proc/self/fd/{directory}/look-elsewhere-browser.sock")
                    break
                except (ConnectionRefusedError, FileNotFoundError):
                    if time.monotonic() >= deadline:
                        raise
                    time.sleep(0.01)
        finally:
            os.close(directory)
        return client

    def read(self, timeout=2):
        deadline = time.monotonic() + timeout
        while b"\n" not in self.output:
            remaining = deadline - time.monotonic()
            if remaining <= 0 or not select.select([self.process.stdout], [], [], remaining)[0]:
                self.fail("no receiver output")
            chunk = os.read(self.process.stdout.fileno(), 4096)
            self.assertTrue(chunk, "receiver exited")
            self.output += chunk
        line, self.output = self.output.split(b"\n", 1)
        self.assertLessEqual(len(line) + 1, 1024)
        self.assertTrue(line.isascii())
        return json.loads(line)

    def closed(self, client):
        try:
            self.assertEqual(client.recv(1), b"")
        except ConnectionResetError:
            pass

    def tearDown(self):
        for client in self.clients:
            client.close()
        if self.process is not None:
            self.process.terminate()
            try:
                self.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait()
                self.fail("receiver did not terminate")
            self.process.stdout.close()
            self.process.stderr.close()

    def test_fragmented_and_coalesced(self):
        self.start()
        client = self.connect()
        data = frame(private_title="must not cross into QML")
        client.sendall(data[:10])
        self.assertFalse(select.select([self.process.stdout], [], [], 0.1)[0])
        client.sendall(data[10:])
        self.assertEqual(self.read(), message())
        client.sendall(frame(2) + frame(3))
        self.assertEqual(self.read()["sequence"], 3)

    def test_exact_limit_and_overflow(self):
        self.start()
        client = self.connect()
        payload = frame()[:-1]
        client.sendall(payload + b" " * (16384 - len(payload)))
        self.assertFalse(select.select([self.process.stdout], [], [], 0.1)[0])
        client.sendall(b"\n")
        self.assertEqual(self.read(), message())
        client.sendall(b"x" * 16385)
        self.closed(client)
        self.assertIsNone(self.process.poll())
        self.connect().sendall(frame(2))
        self.assertEqual(self.read()["sequence"], 2)

    def test_oversized_terminated(self):
        self.start()
        client = self.connect()
        client.sendall(b"x" * 20000 + b"\n")
        self.closed(client)
        self.assertFalse(select.select([self.process.stdout], [], [], 0.1)[0])

    def test_unterminated_deadline(self):
        self.start()
        client = self.connect()
        begin = time.monotonic()
        client.sendall(b"{")
        # More activity must not renew the absolute incomplete-frame deadline.
        time.sleep(1.1)
        client.sendall(b" ")
        self.closed(client)
        self.assertLess(time.monotonic() - begin, 2.8)

    def test_invalid_and_deep_frames(self):
        self.start()
        for data in [b"\xff\n", b"null\n", b"[]\n", b"[" * 2000 + b"]" * 2000 + b"\n",
                     json.dumps({**message(), "video_state": []}).encode() + b"\n"]:
            client = self.connect()
            client.sendall(data)
            self.closed(client)
            self.assertIsNone(self.process.poll())
        self.connect().sendall(frame())
        self.assertEqual(self.read(), message())

    def test_bytes_not_characters(self):
        self.start()
        client = self.connect()
        client.sendall(('"' + '\u00e9' * 9000 + '"\n').encode())
        self.closed(client)

    def test_connection_limit(self):
        self.start()
        for _ in range(8):
            self.connect()
        time.sleep(0.1)
        extra = self.connect()
        self.closed(extra)
        self.clients[0].sendall(frame())
        self.assertEqual(self.read(), message())

    def test_duplicate_preserves_live_socket(self):
        self.start()
        second = self.launch()
        self.assertEqual(second.wait(timeout=2), 1)
        second.stdout.close()
        second.stderr.close()
        self.connect().sendall(frame())
        self.assertEqual(self.read(), message())

    def test_crash_recovery_and_cleanup(self):
        self.start()
        self.process.kill()
        self.process.wait()
        self.process.stdout.close()
        self.process.stderr.close()
        self.assertTrue(os.path.exists(self.path))
        self.start()
        self.connect().sendall(frame())
        self.assertEqual(self.read(), message())
        self.process.terminate()
        self.assertEqual(self.process.wait(timeout=2), 0)
        self.assertFalse(os.path.exists(self.path))

    def test_symlink_and_permissions(self):
        victim = self.runtime / "victim"
        victim.write_text("preserve me")
        os.symlink(victim, self.path)
        self.process = self.launch()
        self.assertEqual(self.process.wait(timeout=2), 1)
        self.assertEqual(victim.read_text(), "preserve me")
        self.assertTrue(os.path.islink(self.path))

    def test_public_runtime_rejected(self):
        self.runtime.chmod(0o755)
        self.process = self.launch()
        self.assertEqual(self.process.wait(timeout=2), 1)
        self.assertFalse(os.path.exists(self.path))

    def test_schema(self):
        for key, value in [("version", True), ("sequence", True), ("sequence", 2**53),
                           ("session_id", 12), ("video_state", []), ("browser_focused", 1)]:
            with self.assertRaises(ValueError):
                normalize({**message(), key: value})

    def test_flood_coalesced(self):
        self.start()
        client = self.connect()
        client.sendall(b"".join(frame(n) for n in range(1, 101)))
        observed = []
        deadline = time.monotonic() + 1
        while time.monotonic() < deadline:
            if select.select([self.process.stdout], [], [], 0.1)[0]:
                observed.append(self.read()["sequence"])
        self.assertGreater(len(observed), 0)
        self.assertLessEqual(len(observed), 4)
        self.assertEqual(observed[-1], 100)

    def test_qml_handoff_and_unload(self):
        config = self.runtime / "config"
        helper_dir = config / "browser-extension/native-host"
        helper_dir.mkdir(parents=True)
        for name in ("context_receiver.py", "context_protocol.py"):
            shutil.copyfile(HOST / name, helper_dir / name)
        shutil.copyfile(ROOT / "BrowserContext.qml", config / "BrowserContext.qml")
        harness = (ROOT / "tests/qml/browser-context.qml").read_text()
        (config / "shell.qml").write_text(harness.replace('import "../.."', 'import "."'))
        env = {**os.environ, "XDG_RUNTIME_DIR": str(self.runtime),
               "QT_QPA_PLATFORM": "offscreen", "QT_QUICK_BACKEND": "software",
               "QT_QPA_PLATFORMTHEME": "", "QT_STYLE_OVERRIDE": "Basic"}
        self.process = subprocess.Popen(
            ["/usr/bin/qs", "--no-color", "-p", str(config / "shell.qml")],
            env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        deadline = time.monotonic() + 3
        while not os.path.exists(self.path):
            if self.process.poll() is not None or time.monotonic() > deadline:
                self.fail("QML did not start receiver: " + b"".join(self.process.communicate(timeout=3)).decode())
            time.sleep(0.01)
        child_file = Path(f"/proc/{self.process.pid}/task/{self.process.pid}/children")
        children = child_file.read_text().split()
        self.assertTrue(children)
        client = self.connect()
        client.sendall(frame(private_title="do not render"))
        stdout, stderr = self.process.communicate(timeout=5)
        log = (stdout + stderr).decode()
        self.assertEqual(self.process.returncode, 0, log)
        lines = [line.split("RECEIVER_CONTEXT ", 1)[1] for line in log.splitlines()
                 if "RECEIVER_CONTEXT " in line]
        self.assertEqual([json.loads(line) for line in lines], [message()])
        self.closed(client)
        for pid in children:
            self.assertFalse(Path(f"/proc/{pid}").exists(), "receiver survived QML unload")


if __name__ == "__main__":
    unittest.main(verbosity=2)

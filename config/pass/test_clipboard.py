"""macOS GUI smoke checks. Overwrites the clipboard with synthetic text only."""

import json
from pathlib import Path
import subprocess
import time
import unittest
import uuid


HELPER = Path(__file__).parents[1] / "vicinae/passwords/assets/clipboard.js"
INSPECT = '''
ObjC.import("AppKit");
function run(argv) {
  var board = $.NSPasteboard.generalPasteboard;
  var types = ObjC.deepUnwrap(board.types) || [];
  return JSON.stringify({
    matches: ObjC.unwrap(board.stringForType("public.utf8-plain-text")) === argv[0],
    concealed: types.indexOf("org.nspasteboard.ConcealedType") !== -1,
    transient: types.indexOf("org.nspasteboard.TransientType") !== -1,
    empty: types.length === 0,
    actualLength: Number(board.stringForType("public.utf8-plain-text").length),
    expectedLength: argv[0].length,
    generation: Number(board.changeCount)
  });
}
'''


def jxa(*args, **kwargs):
    result = subprocess.run(
        ["/usr/bin/osascript", "-l", "JavaScript", *map(str, args)],
        capture_output=True, text=True, timeout=10, **kwargs,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip())
    return result.stdout.strip()


class ClipboardTests(unittest.TestCase):
    def setUp(self):
        self.fixture = "dotfiles-passmenu-synthetic-" + uuid.uuid4().hex
        self.generation = jxa(HELPER, "copy", input=self.fixture)
        self.addCleanup(self.clear_current_fixture)

    def clear_current_fixture(self):
        jxa(HELPER, "clear", self.generation, "1")

    def inspect(self, expected):
        return json.loads(jxa("-e", INSPECT, expected))

    def test_content_and_confidential_markers(self):
        result = self.inspect(self.fixture)
        self.assertTrue(result["matches"], result)
        self.assertTrue(result["concealed"])
        self.assertTrue(result["transient"])

    def test_clears_after_timeout(self):
        jxa(HELPER, "clear", self.generation, "1")
        self.assertTrue(self.inspect("")["empty"])

    def test_old_timer_preserves_subsequent_copy(self):
        timer = subprocess.Popen(
            ["/usr/bin/osascript", "-l", "JavaScript", str(HELPER), "clear", self.generation, "2"],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
        )
        time.sleep(0.2)
        replacement = self.fixture + "-replacement"
        self.generation = jxa(HELPER, "copy", input=replacement)
        _, stderr = timer.communicate(timeout=10)
        self.assertEqual(timer.returncode, 0, stderr.decode())
        result = self.inspect(replacement)
        self.assertTrue(result["matches"], result)


if __name__ == "__main__":
    unittest.main()

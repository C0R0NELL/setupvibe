"""Exercise the Desktop step runner without installing tools or touching services."""

import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


DESKTOP = (Path(__file__).resolve().parents[1] / "desktop.sh").read_text()
RUNNER = re.search(r"^run_section\(\) \{\n.*?^\}", DESKTOP, re.MULTILINE | re.DOTALL).group()
SUMMARY = DESKTOP.split("# --- FINALIZATION ---\n", 1)[1]


class DesktopStdinTests(unittest.TestCase):
    def run_fixture(self, first_step, *, piped=True):
        with tempfile.TemporaryDirectory(prefix="setupvibe-stdin-") as directory:
            environment = os.environ | {"REAL_HOME": directory, "BREW_PREFIX": directory}
            script = """set -o pipefail
BLUE= BOLD= NC= GREEN= RED= YELLOW= CYAN=
IS_LINUX=true
STEPS=(one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty)
STEP_STATUS=()
INSTALL_FAILED=false
resolve_brew_prefix() { :; }
path_prepend_once() { :; }
path_deduplicate() { :; }
""" + RUNNER + "\n"
            script += "first_step() {\n" + first_step + "\n}\n"
            script += "later_step() { echo LATER_STEP_COMPLETED; }\n"
            script += "run_section 0 first_step\n"
            script += "".join(f"run_section {index} later_step\n" for index in range(1, 20))
            script += SUMMARY
            if piped:
                result = subprocess.run(
                    ["bash"], input=script, text=True, capture_output=True,
                    env=environment, timeout=10,
                )
            else:
                path = Path(directory) / "installer.sh"
                path.write_text(script)
                result = subprocess.run(
                    ["bash", str(path)], text=True, capture_output=True,
                    env=environment, timeout=10,
                )
            consumed = Path(directory) / "consumed-input"
            return result, consumed.read_bytes() if consumed.exists() else None

    def test_stdin_reader_cannot_consume_remaining_steps(self):
        for piped in (True, False):
            with self.subTest(piped=piped):
                result, consumed = self.run_fixture(
                    'cat > "$REAL_HOME/consumed-input"\necho FIRST_STEP_COMPLETED',
                    piped=piped,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(consumed, b"")
                self.assertIn("FIRST_STEP_COMPLETED", result.stdout)
                self.assertEqual(result.stdout.count("LATER_STEP_COMPLETED"), 19)
                self.assertEqual(result.stdout.count("✔ OK"), 20)
                self.assertIn("SetupVibe Desktop Completed Successfully!", result.stdout)

    def test_explicit_input_pipe_still_works(self):
        result, _ = self.run_fixture("printf 'EXPLICIT_INPUT\\n' | cat")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("EXPLICIT_INPUT", result.stdout)
        self.assertIn("SetupVibe Desktop Completed Successfully!", result.stdout)

    def test_intermediate_failure_is_not_hidden(self):
        result, _ = self.run_fixture("false\necho SHOULD_NOT_RUN")
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("SHOULD_NOT_RUN", result.stdout)
        self.assertEqual(result.stdout.count("LATER_STEP_COMPLETED"), 19)
        self.assertEqual(result.stdout.count("✘ Error"), 1)
        self.assertIn("SetupVibe Desktop completed with errors.", result.stderr)
        self.assertNotIn("SetupVibe Desktop Completed Successfully!", result.stdout)


if __name__ == "__main__":
    unittest.main()

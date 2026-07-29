from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from check_outputs import parse_log  # noqa: E402


class ParseLogTests(unittest.TestCase):
    def write_log(self, text: str) -> Path:
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        path = Path(directory.name) / "run.log"
        path.write_text(text)
        return path

    def test_valid_residual_history(self) -> None:
        path = self.write_log(
            "n= 1 udiff= 1.0E+00 (1,1) vdiff= 5.0E-01 (1,1)\n"
            "n= 2 udiff= 1.0E-04 (1,1) vdiff= 2.0E-04 (1,1)\n"
        )
        summary = parse_log(path)
        self.assertTrue(summary.valid)
        self.assertEqual(summary.final_step, 2)
        self.assertAlmostEqual(summary.final_residual or 0.0, 2.0e-4)

    def test_false_zero_after_explosion_is_rejected(self) -> None:
        path = self.write_log(
            "n= 1 udiff= 1.0E+02 (1,1) vdiff= 1.0E+02 (1,1)\n"
            "n= 2 udiff= 1.0E+40 (1,1) vdiff= 1.0E+39 (1,1)\n"
            "n= 3 udiff= 0.0E+00 (1,1) vdiff= 0.0E+00 (1,1)\n"
            "Converged after time step 3\n"
        )
        summary = parse_log(path)
        self.assertFalse(summary.valid)
        self.assertTrue(summary.explosive_growth)
        self.assertTrue(summary.zero_after_explosion)

    def test_explicit_nan_is_rejected(self) -> None:
        path = self.write_log("n= 1 udiff= NaN (1,1) vdiff= 1.0E+00 (1,1)\n")
        summary = parse_log(path)
        self.assertFalse(summary.valid)
        self.assertTrue(summary.explicit_nonfinite_text)


if __name__ == "__main__":
    unittest.main()
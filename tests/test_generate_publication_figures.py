from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import generate_publication_figures as figures  # noqa: E402


class ExampleOutputTests(unittest.TestCase):
    def test_example_output_falls_back_to_generated_run_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory_name:
            directory = Path(directory_name)
            examples = directory / "examples"
            runs = directory / "runs"
            archived = examples / "re20_cd" / "reference"
            generated = runs / "re20_cd"
            archived.mkdir(parents=True)
            generated.mkdir(parents=True)
            expected_path = generated / "step2-psi.dat"
            expected_path.write_text("0.0 0.0 1.0\n")

            with patch.object(figures, "EXAMPLES", examples), patch.object(figures, "RUN_OUTPUTS", runs):
                path = figures.example_output("cd20", "step2-psi.dat")

            self.assertEqual(path, expected_path)


if __name__ == "__main__":
    unittest.main()

import base64
import gzip
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from build_addon import ROOT, build
from build_talent_data import git_blob_sha, lua_string


class TalentPackagingTests(unittest.TestCase):
    def test_lua_string_escapes(self):
        self.assertEqual(lua_string('T"\\\n'), '"T\\"\\\\\\n"')
        self.assertEqual(lua_string("à"), '"à"')
        self.assertEqual(lua_string("\x07"), '"\\007"')

    def test_approved_website_pin(self):
        pin = json.loads((ROOT / "config" / "talent-data.json").read_text())
        self.assertEqual(
            pin["source_repository"], "CosmicCuddle/Naxxramas-Resource-Hub"
        )
        self.assertEqual(len(pin["source_commit"]), 40)
        for key in ("talents_git_blob_sha", "visuals_git_blob_sha"):
            self.assertEqual(len(pin[key]), 40)
        self.assertEqual(git_blob_sha(b"hello"), "b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0")

    def test_package_has_one_correct_addon_folder(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = build(Path(tmp))
            with zipfile.ZipFile(archive) as z:
                files = set(z.namelist())
                self.assertEqual(
                    files,
                    {
                        "NTalentCalculator/NTalentCalculator.toc",
                        "NTalentCalculator/Data.lua",
                        "NTalentCalculator/Engine.lua",
                        "NTalentCalculator/Progression.lua",
                        "NTalentCalculator/UI.lua",
                    },
                )
                toc = z.read("NTalentCalculator/NTalentCalculator.toc").decode()
                self.assertIn("## OptionalDeps: NCore", toc)
                self.assertIn("## SavedVariables: NTalentCalculatorDB", toc)
                data = z.read("NTalentCalculator/Data.lua").decode()
                self.assertIn("NTalentCalculatorData", data)


if __name__ == "__main__":
    unittest.main()

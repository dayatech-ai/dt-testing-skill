import hashlib
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from scripts.release import build, next_version, plan


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_semantic_version_rules(self):
        for messages, expected in [
            (["fix: bug"], (1, 2, 4)),
            (["perf(core): faster"], (1, 2, 4)),
            (["feat: new", "fix: bug"], (1, 3, 0)),
            (["feat!: changed"], (2, 0, 0)),
            (["refactor: changed\n\nBREAKING CHANGE: removed API"], (2, 0, 0)),
            (["docs: guide", "test: coverage", "chore: tooling"], None),
        ]:
            with self.subTest(messages=messages):
                self.assertEqual(next_version((1, 2, 3), messages), expected)
        self.assertEqual(next_version((0, 0, 0), ["feat: first"]), (0, 1, 0))

    def test_plan_with_real_git_history(self):
        def git(*args):
            return subprocess.check_output(["git", "-C", str(self.root), *args], text=True).strip()
        git("init", "-q")
        git("config", "user.name", "Test")
        git("config", "user.email", "test@example.invalid")
        def commit(message):
            git("-c", "commit.gpgsign=false", "commit", "--allow-empty", "-qm", message)
        with patch("scripts.release.git", side_effect=git):
            commit("docs: initial")
            self.assertEqual(plan(), "")
            commit("feat: initial skill")
            self.assertEqual(plan(), "v0.1.0")
            git("tag", "v0.1.0")
            self.assertEqual(plan(), "v0.1.0")
            commit("docs: update")
            self.assertEqual(plan(), "")
            commit("fix: runner")
            self.assertEqual(plan(), "v0.1.1")

    def test_repository_embedded_in_both_installers(self):
        build("v1.2.3", self.root / "dist", repo="owner/repo")
        for name in ("install.sh", "install.ps1"):
            content = (self.root / "dist" / name).read_text()
            self.assertIn("owner/repo", content)
            self.assertNotIn("__DT_RELEASE_REPO__", content)

    def test_package_assets_and_size(self):
        build("v1.2.3", self.root / "dist")
        dist = self.root / "dist"
        self.assertEqual({p.name for p in dist.iterdir()}, {"install.sh", "install.ps1", "dt-testing.zip", "SHA256SUMS"})
        with zipfile.ZipFile(dist / "dt-testing.zip") as archive:
            self.assertIn("dt-testing/references/workflow.md", archive.namelist())
            self.assertNotIn("dt-testing/README.md", archive.namelist())
            self.assertEqual(archive.read("dt-testing/VERSION"), b"1.2.3\n")
        self.assertLess((dist / "install.sh").stat().st_size, 16 * 1024)
        for line in (dist / "SHA256SUMS").read_text().splitlines():
            digest, name = line.split()
            self.assertEqual(hashlib.sha256((dist / name).read_bytes()).hexdigest(), digest)


if __name__ == "__main__":
    unittest.main()

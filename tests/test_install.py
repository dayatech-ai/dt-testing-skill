import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

from scripts.release import ROOT, build

INSTALLER = ROOT / 'scripts/install.sh'
SOURCE = ROOT / 'skills' / 'dt-testing'
SKILLS_SOURCE = ROOT / 'skills'


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / 'my project'
        self.project.mkdir()
        self.env = os.environ.copy()
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.env['PATH'] = str(self.bin) + os.pathsep + self.env['PATH']

    def run_install(self, *args, success=True, global_scope=False):
        scope = ['--global'] if global_scope else ['--project', str(self.project)]
        result = subprocess.run(['bash', str(INSTALLER), *scope, *args], cwd=self.root,
                                env=self.env, capture_output=True, text=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def fake_command(self, name, content):
        path = self.bin / name
        path.write_text('#!/usr/bin/env bash\nset -eu\n' + content)
        path.chmod(0o755)

    def mock_release(self):
        dist = self.root / 'dist'
        build('v1.2.3', dist)
        self.env['FIXTURE_DIST'] = str(dist)
        self.env['CURL_LOG'] = str(self.root / 'curl.log')
        self.fake_command('curl', '''
output= url=
while (($#)); do
  case "$1" in
    -o) output=$2; shift 2 ;;
    --connect-timeout|--max-time|--max-filesize|-w) shift 2 ;;
    https://*) url=$1; shift ;;
    *) shift ;;
  esac
done
printf '%s\\n' "$url" >> "$CURL_LOG"
case "$url" in
  https://github.com/owner/repo/releases/latest) printf 'https://github.com/owner/repo/releases/tag/v1.2.3' ;;
  https://github.com/owner/repo/releases/download/v1.2.3/*) cp "$FIXTURE_DIST/${url##*/}" "$output" ;;
  *) exit 22 ;;
esac
''')
        return dist

    def mock_release_with_skills(self, names):
        # Package a fake ROOT with several skills, so the install.sh under test
        # (the real, checked-in script) can be exercised against a multi-skill release.
        fake_root = self.root / 'fake-repo'
        for name in names:
            skill = fake_root / 'skills' / name
            (skill / 'references').mkdir(parents=True)
            (skill / 'SKILL.md').write_text(f'---\nname: {name}\n---\n# {name}\n')
        (fake_root / 'scripts').mkdir(parents=True)
        for installer in ('install.sh', 'install.ps1'):
            shutil.copy(ROOT / 'scripts' / installer, fake_root / 'scripts' / installer)
        dist = self.root / 'dist'
        with patch('scripts.release.ROOT', fake_root):
            build('v1.2.3', dist)
        self.env['FIXTURE_DIST'] = str(dist)
        self.env['CURL_LOG'] = str(self.root / 'curl.log')
        self.fake_command('curl', '''
output= url=
while (($#)); do
  case "$1" in
    -o) output=$2; shift 2 ;;
    --connect-timeout|--max-time|--max-filesize|-w) shift 2 ;;
    https://*) url=$1; shift ;;
    *) shift ;;
  esac
done
printf '%s\\n' "$url" >> "$CURL_LOG"
case "$url" in
  https://github.com/owner/repo/releases/latest) printf 'https://github.com/owner/repo/releases/tag/v1.2.3' ;;
  https://github.com/owner/repo/releases/download/v1.2.3/*) cp "$FIXTURE_DIST/${url##*/}" "$output" ;;
  *) exit 22 ;;
esac
''')
        return dist

    def test_default_local_install_includes_every_skill_under_skills_dir(self):
        self.run_install('--agent', 'codex')
        installed = {p.name for p in (self.project / '.agents/skills').iterdir()}
        expected = {p.name for p in SKILLS_SOURCE.iterdir() if p.is_dir() and (p / 'SKILL.md').is_file()}
        self.assertEqual(installed, expected)

    def test_remote_install_defaults_to_every_skill_in_the_release(self):
        self.mock_release_with_skills(['alpha', 'beta'])
        self.run_install('--repo', 'owner/repo', '--agent', 'codex')
        base = self.project / '.agents/skills'
        self.assertTrue((base / 'alpha/SKILL.md').is_file())
        self.assertTrue((base / 'beta/SKILL.md').is_file())

    def test_skill_flag_installs_only_the_requested_subset(self):
        self.mock_release_with_skills(['alpha', 'beta'])
        self.run_install('--repo', 'owner/repo', '--agent', 'codex', '--skill', 'alpha')
        base = self.project / '.agents/skills'
        self.assertTrue((base / 'alpha/SKILL.md').is_file())
        self.assertFalse((base / 'beta').exists())

    def test_skill_flag_accepts_a_comma_separated_list(self):
        self.mock_release_with_skills(['alpha', 'beta', 'gamma'])
        self.run_install('--repo', 'owner/repo', '--agent', 'codex', '--skill', 'alpha,gamma')
        base = self.project / '.agents/skills'
        self.assertTrue((base / 'alpha').exists())
        self.assertTrue((base / 'gamma').exists())
        self.assertFalse((base / 'beta').exists())

    def test_unknown_skill_name_is_rejected(self):
        self.mock_release_with_skills(['alpha'])
        result = self.run_install('--repo', 'owner/repo', '--agent', 'codex', '--skill', 'missing', success=False)
        self.assertIn('Unknown skill', result.stderr)
        self.assertEqual(list(self.project.iterdir()), [])

    def test_release_pipe_install_and_repeat_without_parameters(self):
        dist = self.mock_release()
        build('v1.2.3', dist, repo='owner/repo')
        self.env['HOME'] = str(self.project)
        (self.project / '.claude').mkdir()
        # Invoke the actual release asset through stdin, like curl | bash.
        for attempt in range(2):
            result = subprocess.run(['bash'], input=(dist / 'install.sh').read_text(),
                                    cwd=self.root, env=self.env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('Already up to date:' if attempt else 'Installed:', result.stdout)
        self.assertFalse((self.project / '.claude/skill-backups').exists())
        self.assertTrue((self.project / '.claude/skills/dt-testing/VERSION').is_file())

    def test_project_all_complete_skill_and_shared_destination(self):
        result = self.run_install('--agent', 'all')
        self.assertEqual(result.stdout.count('Installed:'), 3)
        expected = {p.relative_to(SOURCE): p.read_bytes() for p in SOURCE.rglob('*') if p.is_file()}
        for path in ('.claude/skills', '.agents/skills', '.opencode/skills'):
            target = self.project / path / 'dt-testing'
            self.assertEqual({p.relative_to(target): p.read_bytes() for p in target.rglob('*') if p.is_file()}, expected)

    def test_global_destinations(self):
        # Test subprocess home is isolated; never writes to the real user home.
        self.env['HOME'] = str(self.project)
        self.run_install('--agent', 'all', global_scope=True)
        for path in ('.claude/skills', '.gemini/config/skills', '.config/opencode/skills', '.agents/skills'):
            self.assertTrue((self.project / path / 'dt-testing/SKILL.md').is_file())

    def test_each_agent(self):
        for agent in ('claude-code', 'antigravity', 'opencode', 'codex'):
            with self.subTest(agent=agent):
                self.run_install('--agent', agent, '--dry-run')
        self.assertEqual(list(self.project.iterdir()), [])

    def test_collision_prevents_partial_install(self):
        existing = self.project / '.agents/skills/dt-testing'
        existing.mkdir(parents=True)
        marker = existing / 'custom.txt'
        marker.write_text('keep')
        self.run_install('--agent', 'all', success=False)
        self.assertEqual(marker.read_text(), 'keep')
        self.assertFalse((self.project / '.claude').exists())

    def test_invalid_arguments(self):
        for args in [('--agent',), ('--agent', 'unknown'), ('--agent', 'codex', '--version', '../bad'),
                     ('--agent', 'codex', '--repo', 'https://bad'), ('--agent', 'codex', '--global')]:
            with self.subTest(args=args):
                self.run_install(*args, success=False)
        self.assertEqual(list(self.project.iterdir()), [])

    def test_remote_update_preserves_backup_and_metadata(self):
        self.mock_release()
        self.run_install('--repo', 'owner/repo', '--agent', 'codex')
        target = self.project / '.agents/skills/dt-testing'
        (target / 'custom.md').write_text('local edit')
        self.run_install('--repo', 'owner/repo', '--agent', 'codex', '--update')
        self.assertFalse((target / 'custom.md').exists())
        backups = list((self.project / '.agents/skill-backups').glob('*/dt-testing/custom.md'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), 'local edit')
        self.assertEqual(json.loads((target / '.release.json').read_text()), {'repo': 'owner/repo', 'version': 'v1.2.3'})

    def test_pinned_version_and_remote_dry_run(self):
        self.mock_release()
        self.run_install('--repo', 'owner/repo', '--version', '1.2.3', '--agent', 'all', '--dry-run')
        self.assertEqual(list(self.project.iterdir()), [])
        urls = (self.root / 'curl.log').read_text()
        self.assertNotIn('/latest', urls)
        self.assertIn('/download/v1.2.3/skills.zip', urls)

    def test_checksum_failure_keeps_old_install(self):
        dist = self.mock_release()
        self.run_install('--agent', 'codex')
        target = self.project / '.agents/skills/dt-testing/SKILL.md'
        previous = target.read_bytes()
        (dist / 'SHA256SUMS').write_text('bad  skills.zip\n')
        result = self.run_install('--repo', 'owner/repo', '--agent', 'codex', '--update', success=False)
        self.assertIn('checksum', result.stderr)
        self.assertEqual(target.read_bytes(), previous)

    def test_archive_traversal_rejected(self):
        dist = self.mock_release()
        with zipfile.ZipFile(dist / 'skills.zip', 'w') as archive:
            archive.writestr('dt-testing/../../escape', 'bad')
        digest = hashlib.sha256((dist / 'skills.zip').read_bytes()).hexdigest()
        (dist / 'SHA256SUMS').write_text(digest + '  skills.zip\n')
        result = self.run_install('--repo', 'owner/repo', '--agent', 'codex', success=False)
        self.assertIn('Unsafe', result.stderr)
        self.assertEqual(list(self.project.iterdir()), [])

    def test_failed_replacement_restores_old_install(self):
        self.run_install('--agent', 'codex')
        target = self.project / '.agents/skills/dt-testing/custom.md'
        target.write_text('keep')
        self.env['REAL_MV'] = shutil.which('mv')
        self.fake_command('mv', '''
case "$1" in */.dt-testing-*/dt-testing) exit 1 ;; esac
exec "$REAL_MV" "$@"
''')
        self.run_install('--agent', 'codex', '--update', success=False)
        self.assertEqual(target.read_text(), 'keep')

    def test_symlink_destination_rejected(self):
        parent = self.project / '.agents/skills'
        parent.mkdir(parents=True)
        (parent / 'dt-testing').symlink_to(SOURCE, target_is_directory=True)
        self.run_install('--agent', 'codex', '--update', success=False)
        self.assertTrue((parent / 'dt-testing').is_symlink())


if __name__ == '__main__':
    unittest.main()

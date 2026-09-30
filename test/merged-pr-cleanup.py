#!/usr/bin/env python3

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMMAND = ROOT / ".bin/git-cleanup-merged-pr"


class CleanupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.remote = self.root / "remote.git"
        self.env = os.environ | {
            "GIT_CONFIG_GLOBAL": os.devnull,
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_AUTHOR_NAME": "Test",
            "GIT_AUTHOR_EMAIL": "test@example.com",
            "GIT_COMMITTER_NAME": "Test",
            "GIT_COMMITTER_EMAIL": "test@example.com",
        }
        self.git("init", "--bare", str(self.remote))
        self.git("init", "-b", "main")
        self.git("remote", "add", "origin", str(self.remote))
        self.git("commit", "--allow-empty", "-m", "Initial")
        self.git("push", "origin", "main")
        self.worktree = self.repo / ".worktrees/deploy"
        self.git("worktree", "add", "-b", "feature", str(self.worktree))
        (self.worktree / "feature.txt").write_text("feature\n")
        self.git("-C", str(self.worktree), "add", ".")
        self.git("-C", str(self.worktree), "commit", "-m", "Feature")
        self.head = self.git("rev-parse", "feature").stdout.strip()
        self.git("push", "origin", "feature")
        self.git("merge", "--squash", "feature")
        self.git("commit", "-m", "Squash feature")
        self.git("push", "origin", "main")
        self.pr = {
            "merged": True,
            "head": {
                "ref": "feature",
                "sha": self.head,
                "repo": {"full_name": "example/repo"},
            },
            "base": {"ref": "main", "repo": {"full_name": "example/repo"}},
        }
        self.fixture = self.root / "pr.json"
        fake_bin = self.root / "bin"
        fake_bin.mkdir()
        gh = fake_bin / "gh"
        gh.write_text(
            "#!/usr/bin/env python3\n"
            "import os, sys\n"
            "if sys.argv[1] == 'repo':\n"
            '    print(\'{"nameWithOwner": "example/repo"}\')\n'
            "elif sys.argv[1:] == ['api', 'repos/example/repo/pulls/108']:\n"
            "    print(open(os.environ['PR_FIXTURE']).read())\n"
            "else:\n"
            "    sys.exit('Unexpected gh arguments: ' + repr(sys.argv[1:]))\n"
        )
        gh.chmod(0o755)
        self.env |= {
            "PATH": f"{fake_bin}:{self.env['PATH']}",
            "PR_FIXTURE": str(self.fixture),
        }

    def git(self, *args, check=True):
        return subprocess.run(
            ["git", *args],
            cwd=self.repo,
            env=self.env,
            text=True,
            capture_output=True,
            check=check,
        )

    def cleanup(self, *args):
        self.fixture.write_text(json.dumps(self.pr))
        return subprocess.run(
            [str(COMMAND), "--repo", str(self.repo), "108", *args],
            env=self.env,
            text=True,
            capture_output=True,
            check=False,
        )

    def assert_preserved(self, result, reason):
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn(reason, result.stderr)
        self.assertTrue(self.worktree.is_dir())
        self.assertEqual(self.git("rev-parse", "feature").returncode, 0)
        self.assertIn(
            "refs/heads/feature",
            self.git("ls-remote", "origin", "refs/heads/feature").stdout,
        )

    def test_cleans_squash_merged_pr(self):
        result = self.cleanup("--delete-remote")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.worktree.exists())
        self.assertNotEqual(
            self.git(
                "rev-parse", "--verify", "refs/heads/feature", check=False
            ).returncode,
            0,
        )
        self.assertEqual(
            self.git("ls-remote", "origin", "refs/heads/feature").stdout, ""
        )

    def test_keeps_remote_unless_requested(self):
        result = self.cleanup()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(
            self.head, self.git("ls-remote", "origin", "refs/heads/feature").stdout
        )

    def test_refuses_unmerged_pr(self):
        self.pr["merged"] = False
        self.assert_preserved(self.cleanup("--delete-remote"), "not merged")

    def test_refuses_dirty_worktree(self):
        for path in ("feature.txt", "untracked.txt"):
            with self.subTest(path=path):
                target = self.worktree / path
                target.write_text("unsaved work\n")
                self.assert_preserved(self.cleanup("--delete-remote"), "not clean")
                if path == "feature.txt":
                    self.git("-C", str(self.worktree), "restore", path)
                else:
                    target.unlink()

    def test_refuses_locked_worktree(self):
        self.git("worktree", "lock", str(self.worktree))
        self.assert_preserved(self.cleanup("--delete-remote"), "Cannot remove worktree")

    def test_refuses_new_local_commit(self):
        self.git(
            "-C", str(self.worktree), "commit", "--allow-empty", "-m", "Later work"
        )
        self.assert_preserved(self.cleanup("--delete-remote"), "Local branch tip")

    def test_refuses_changed_remote_tip(self):
        self.git("push", "origin", "main:refs/heads/feature", "--force")
        self.assert_preserved(self.cleanup("--delete-remote"), "Remote branch tip")

    def test_refuses_base_branch(self):
        self.pr["base"]["ref"] = "feature"
        self.assert_preserved(self.cleanup("--delete-remote"), "protected branch")

    def test_refuses_fork_pr(self):
        self.pr["head"]["repo"]["full_name"] = "other/repo"
        self.assert_preserved(self.cleanup("--delete-remote"), "fork")

    def test_refuses_different_push_destination(self):
        self.git("remote", "set-url", "--push", "origin", str(self.root / "other.git"))
        self.assert_preserved(self.cleanup("--delete-remote"), "push URL")

    def test_preserves_remote_updated_during_push(self):
        later_head = self.git("rev-parse", "main").stdout.strip()
        hook = self.repo / ".git/hooks/pre-push"
        hook.write_text(
            f'#!/bin/sh\ngit --git-dir="{self.remote}" update-ref '
            f"refs/heads/feature {later_head}\n"
        )
        hook.chmod(0o755)
        result = self.cleanup("--delete-remote")
        self.assert_preserved(result, "rejected")
        self.assertIn(
            later_head, self.git("ls-remote", "origin", "refs/heads/feature").stdout
        )

    def test_accepts_already_deleted_remote(self):
        self.git("push", "origin", "--delete", "feature")
        result = self.cleanup("--delete-remote")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.worktree.exists())


class PermissionTests(unittest.TestCase):
    def test_allows_cleanup_entry_point(self):
        settings = json.loads((ROOT / ".claude/settings.json").read_text())
        self.assertIn(
            "Bash(~/.bin/git-cleanup-merged-pr *)", settings["permissions"]["allow"]
        )


if __name__ == "__main__":
    unittest.main()

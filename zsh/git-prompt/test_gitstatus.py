# -*- coding: utf-8 -*-
import unittest

from mock import patch, Mock

from gitstatus import open_git_status
from gitstatus import get_status_vector
from gitstatus import ahead_behind, index_state


class GitStatusProcessTestCase(unittest.TestCase):
    @patch("gitstatus.Popen")
    def test_open_git_status(self, pipe_open_cls_mock):
        status = "## branch\n M zsh/test.py\n"
        popen_mock = Mock()
        popen_mock.returncode = 0
        popen_mock.communicate.return_value = (status, None)
        pipe_open_cls_mock.return_value = popen_mock

        results = open_git_status()

        self.assertListEqual(
            [u"## branch", u" M zsh/test.py"],
            results.splitlines(),
        )

    @patch("gitstatus.sys")
    @patch("gitstatus.Popen")
    def test_open_git_status__fail(self, pipe_open_cls_mock, sys_mock):
        popen_mock = Mock()
        popen_mock.returncode = 1
        popen_mock.communicate.return_value = (" ", None)
        pipe_open_cls_mock.return_value = popen_mock

        open_git_status()

        self.assertTrue(sys_mock.exit.called)

    def test_get_status_vector__upto_date_and_clean(self):
        expected = dict(branch="branch-name", ahead=0, behind=0, untracked=0,
                        staged=0, changed=0, conflicts=0)
        self.assertDictEqual(expected, get_status_vector("## branch-name"))

    def test_get_status_vector__ahead(self):
        expected = dict(branch="master", ahead=1, behind=0, untracked=0,
                        staged=0, changed=0, conflicts=0)
        self.assertDictEqual(
            expected,
            get_status_vector("## master...origin/master [ahead 1]")
        )

    def test_get_status_vector__behind(self):
        expected = dict(branch="master", ahead=0, behind=1, untracked=0,
                        staged=0, changed=0, conflicts=0)
        self.assertDictEqual(
            expected,
            get_status_vector("## master...origin/master [behind 1]")
        )

    def test_get_status_vector__ahead_and_behind(self):
        expected = dict(branch="master", ahead=2, behind=3, untracked=0,
                        staged=0, changed=0, conflicts=0)
        self.assertDictEqual(
            expected,
            get_status_vector("## master...origin/master [ahead 2, behind 3]")
        )

    def test_get_status_vector__untracked(self):
        expected = dict(branch=None, ahead=0, behind=0, untracked=1, staged=0,
                        changed=0, conflicts=0)
        self.assertDictEqual(
            expected,
            get_status_vector("?? zsh/git-prompt/tests_gitstatus.py")
        )

    def test_get_status_vector__staged(self):
        expected = dict(branch=None, ahead=0, behind=0, untracked=0, staged=1,
                        changed=0, conflicts=0)
        self.assertDictEqual(
            expected,
            get_status_vector("M  zsh/git-prompt/README.rst")
        )

    def test_get_status_vector__changed(self):
        expected = dict(branch=None, ahead=0, behind=0, untracked=0, staged=0,
                        changed=1, conflicts=0)
        self.assertDictEqual(
            expected,
            get_status_vector(" M zsh/git-prompt/README.rst")
        )

    def test_get_status_vector__conflicts(self):
        expected = dict(branch=None, ahead=0, behind=0, untracked=0, staged=0,
                        changed=0, conflicts=1)
        self.assertDictEqual(
            expected,
            get_status_vector("UU zsh/git-prompt/README.rst")
        )


class GitStatusDisplayTestCase(unittest.TestCase):
    def test_ahead_behind__upto_date(self):
        self.assertEqual(u"", ahead_behind(0, 0))

    def test_ahead_behind__ahead(self):
        self.assertEqual(u"↑1", ahead_behind(1, 0))

    def test_ahead_behind__behind(self):
        self.assertEqual(u"↓2", ahead_behind(0, 2))

    def test_ahead_behind__mismatched(self):
        self.assertEqual(u"↑2↓3", ahead_behind(2, 3))

    def test_index_state__clean(self):
        self.assertEqual(u"✔ ", index_state(0, 0, 0, 0))

    def test_index_state__untracked(self):
        self.assertEqual(u"…", index_state(2, 0, 0, 0))

    def test_index_state__staged(self):
        self.assertEqual(u"●3", index_state(0, 3, 0, 0))

    def test_index_state__changed(self):
        self.assertEqual(u"✚4", index_state(0, 0, 4, 0))

    def test_index_state__conflicts(self):
        self.assertEqual(u"✖5", index_state(0, 0, 0, 5))

    def test_index_state__order(self):
        self.assertEqual(u"✖3●1✚2", index_state(0, 1, 2, 3))


if __name__ == "__main__":
    unittest.main()
# -*- coding: utf-8 -*-
import unittest
try:
    from unittest.mock import patch, Mock
except ImportError:
    from mock import patch, Mock

from gitstatus import open_git_status
from gitstatus import get_status_vector
from gitstatus import ahead_behind, index_state
from gitstatus import term_color, tcolors


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
        self.assertEqual(term_color(u"↑1", tcolors.AHEAD), ahead_behind(1, 0))

    def test_ahead_behind__behind(self):
        self.assertEqual(term_color(u"↓2", tcolors.BEHIND), ahead_behind(0, 2))

    def test_ahead_behind__mismatched(self):
        self.assertEqual(
            term_color(u"↑2", tcolors.AHEAD) + term_color(u"↓3", tcolors.BEHIND),
            ahead_behind(2, 3)
        )

    def test_index_state__clean(self):
        self.assertEqual(
            term_color(u"✔ ", tcolors.CLEAN),
            index_state(0, 0, 0, 0)
        )

    def test_index_state__untracked(self):
        self.assertEqual(
            term_color(u"…", tcolors.UNTRACKED),
            index_state(2, 0, 0, 0)
        )

    def test_index_state__staged(self):
        self.assertEqual(
            term_color(u"●3", tcolors.STAGED),
            index_state(0, 3, 0, 0)
        )

    def test_index_state__changed(self):
        self.assertEqual(
            term_color(u"✚4", tcolors.CHANGED),
            index_state(0, 0, 4, 0)
        )

    def test_index_state__conflicts(self):
        self.assertEqual(
            term_color(u"✖5", tcolors.CONFLICT),
            index_state(0, 0, 0, 5)
        )

    def test_index_state__order(self):
        self.assertEqual(
            "".join([
                term_color(u"✖3", tcolors.CONFLICT),
                term_color(u"●1", tcolors.STAGED),
                term_color(u"✚2", tcolors.CHANGED),
            ]),
            index_state(0, 1, 2, 3)
        )



if __name__ == "__main__":
    unittest.main()

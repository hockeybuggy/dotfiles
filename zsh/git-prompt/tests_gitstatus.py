from mock import patch, Mock
from unittest import TestCase
from gitstatus import get_status_vector
from gitstatus import ahead_behind, index_state


class GitStatusProcessTestCase(object):
    @patch("gitstatus.Popen")
    def test_open_git_status(self, pipe_open_cls_mock):
        status = StringIO("## single-git-call-prompt\n M zsh/git-prompt/tests_gitstatus.py")
        popen_mock = Mock()
        popen_mock.returncode.return_value = 0
        popen_mock.communicate.return_value = (status, None)
        pipe_open_cls_mock.return_value = popen_mock

        filelike = open_git_status()
        filelike.splitlines()
        # TODO improve

    @patch("gitstatus.sys")
    @patch("gitstatus.Popen")
    def test_open_git_status__fail(self, sys_mock, pipe_open_cls_mock):
        popen_mock = Mock()
        popen_mock.returncode.return_value = 1
        pipe_open_cls_mock.return_value = popen_mock

        open_git_status()

        self.assertTrue(self.sys_mock.called)

    def test_process_file(self):
        self.fail() # TODO improve

    def test_get_status_vector__ahead(self):
        self.assertTupleEqual(
            (1, 0, 0, 0, 0, 0),
            get_status_vector("## branch-name")
        )

    def test_get_status_vector__behind(self):
        self.assertTupleEqual(
            (0, 1, 0, 0, 0, 0),
            get_status_vector("## branch-name")
        )

    def test_get_status_vector__untracked(self):
        self.assertTupleEqual(
            (0, 0, 1, 0, 0, 0),
            get_status_vector("?? zsh/git-prompt/tests_gitstatus.py")
        )

    def test_get_status_vector__staged(self):
        self.assertTupleEqual(
            (0, 0, 0, 1, 0, 0),
            get_status_vector("M  zsh/git-prompt/README.rst")
        )

    def test_get_status_vector__changed(self):
        self.assertTupleEqual(
            (0, 0, 0, 0, 1, 0),
            get_status_vector(" M zsh/git-prompt/gitstatus.py")
        )
    def test_get_status_vector__conflicts(self):
        self.assertTupleEqual(
            (0, 0, 0, 0, 0, 1),
            get_status_vector("U  zsh/git-prompt/README.rst")
        )


class GitStatusDisplayTestCase(object):
    def test_ahead_behind__upto_date(self):
        self.assertEqual(u"", ahead_behind(0, 0))

    def test_ahead_behind__ahead(self):
        self.assertEqual(u"↓1", ahead_behind(1, 0))

    def test_ahead_behind__behind(self):
        self.assertEqual(u"↑2", ahead_behind(0, 2))

    def test_ahead_behind__mismatched(self):
        self.assertEqual(u"↓2↑3", ahead_behind(2, 3))


    def test_index_state__clean(self):
        self.assertEqual(u"✔ ", index_state(0, 0, 0, 0))

    def test_index_state__untracked(self):
        self.assertEqual(u"…", index_state(2, 0, 0, 0))

    def test_index_state__staged(self):
        self.assertEqual(u"●3", index_state(0, 3, 0, 0))

    def test_index_state__changed(self):
        self.assertEqual(u"✚4", index_state(0, 0, 4, 0))

    def test_index_state__conflicts(self):
        self.assertequal(u"✖5", index_state(0, 0, 0, 5))

    def test_index_state__order(self):
        self.assertEqual(u"✖1●2✚3", index_state(0, 1, 2, 3))

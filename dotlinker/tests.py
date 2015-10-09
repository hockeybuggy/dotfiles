import os
import shutil
import unittest
from os.path import join

from dotlinker import Dotlinker


BASE_DIR = os.path.dirname(os.path.realpath(__file__))
DOT_DIR = os.path.join(BASE_DIR, "test_fixtures/fake_dotfiles")
TARGET_DIR = os.path.join(BASE_DIR, "test_fixtures/fake_target")

print(TARGET_DIR)

class DotlinkerTestCase(unittest.TestCase):
    def setUp(self):
        if os.path.exists(TARGET_DIR):
            shutil.rmtree(TARGET_DIR)
        os.mkdir(TARGET_DIR)

    def test_link(self):
        subject = Dotlinker(DOT_DIR, TARGET_DIR)
        # check target_dir exists and is empty
        os.path.exists(TARGET_DIR)
        self.assertEqual([], os.listdir(TARGET_DIR))

        subject.link()  # link it

        expected = ["bashrc", "linked_file", "vim", "vimrc"]
        self.assertEqual(expected, os.listdir(TARGET_DIR))
        print(join(TARGET_DIR, "bashrc"))
        self.assertTrue(os.path.isfile(join(TARGET_DIR, "bashrc")))
        self.assertTrue(os.path.isfile(join(TARGET_DIR, "vimrc")))
        self.assertTrue(os.path.isfile(join(TARGET_DIR, "linked_file")))
        self.assertTrue(os.path.isdir(join(TARGET_DIR, "vim")))


if __name__ == "__main__":
    unittest.main()

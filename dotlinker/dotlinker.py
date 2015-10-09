import os
import os.path
from os.path import join


class Dotlinker(object):
    def __init__(self, dot_dir, target_dir):
        self.dot_dir = dot_dir
        self.target_dir = target_dir
        self.suffix = ".symlink"

    def link(self):
        self._walk_and_link()

    def _walk_and_link(self, filename="", directory=""):
        print(directory)
        for filename in os.listdir(join(self.dot_dir, directory, filename)):
            # print(filename)
            if filename.endswith(self.suffix):
                self._link_file(filename, directory=directory)
            elif os.path.isdir(join(self.dot_dir, directory, filename)):
                self._walk_and_link(filename="", directory=join(directory, filename))

    def dot_path(self, directory, filename):
        return join(self.dot_dir, directory, filename)

    def target_path(self, filename):
        return join(self.target_dir, filename)

    def _link_file(self, filename, directory=""):
        target_name = filename[:-len(self.suffix)]
        file_path = self.dot_path(directory, filename)
        target_path = self.target_path(target_name)
        link_message = "Linking {} to {}".format(file_path, target_path)
        os.symlink(file_path, target_path)
        print(link_message)

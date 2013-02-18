#!/usr/bin/python
#  encoding: utf-8
"""
Creates symlinks from one directory to another
"""

from _dotlinker import Linker
import argparse

parser = argparse.ArgumentParser(description="Creates symlinks from one directory to another")
parser.add_argument("-i", "--interactive", action="store_true") #dest="mode", action="store_const", default=""

#TODO possible args: clean, backup, ask

def main():
    """
    Creates an instance of the dotlinker and runs it
    """
    dot = Linker(parser.parse_args())
    dot.link()

if __name__ == "__main__":
    main()


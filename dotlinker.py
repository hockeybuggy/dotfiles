#!/usr/bin/python
#  encoding: utf-8
"""
Creates symlinks from one directory to another
"""

from _dotlinker import Linker
import _dotlinker.argparse

parser = argparse.ArgumentParser(description="Creates symlinks from my home to my dotfiles")
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument("-i", "--interactive", action="store_true")
group.add_argument("-a", "--automatic", action="store_true")
parser.add_argument("-c", "--clean-backups", dest="clean", action="store_true", \
        help="Removed all 'backup' files in the home directory")

#TODO possible args: backup

def main():
    """
    Creates an instance of the dotlinker and runs it
    """
    args = parser.parse_args()
    dot = Linker()
    if args.interactive:
        dot.interactive_linker()
    elif args.automatic:
        dot.automatic_linker()

    if args.clean:
        dot.clean_backups()

if __name__ == "__main__":
    main()


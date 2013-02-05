#!/usr/bin/python
#  encoding: utf-8
"""
Runs the dotlinker
"""

from dotlinker import Linker

def main():
    """
    Creates an instance of the dotlinker and runs it
    """
    dot = Linker()
    dot.link()

if __name__ == "__main__":
    main()


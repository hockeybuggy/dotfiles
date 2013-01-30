#!/usr/bin/python

import json

groupFileStr = "link_groups.json"

class Linker:
    groupsStr = ""
    def __init__(self):
        r = open(groupFileStr)
        text = ""
        for line in r:
            text += line.strip()
        self.groupsStr = json.dumps(text)

    def link(self):
        print self.groupsStr
        groups = json.loads(self.groupsStr)
        print groups.__class__.__name__
    #for group in groups:
        #print group

    def askYesNo(self):
        yesPreferance = True
        if yesPreferance:
            print "[Y/n]"
        else:
            print "[y/N]"
        # TODO get user input


if __name__ == "__main__":
    l = Linker()
    l.link()


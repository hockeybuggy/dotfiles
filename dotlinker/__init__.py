#!/usr/bin/python

#Filename: __init__.py
#Author: Douglas Anderson
#Created: 2013/02/04

import json
import os

thisDir = "dotlinker/"
configFile = "config.json"
configDir = os.path.realpath(thisDir + configFile)

class Linker:
    config = None
    def __init__(self):
        r = open(configDir)
        configStr = ""
        for line in r:
            configStr += line.strip()
        self.config = json.loads(configStr)

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

    def __str__(self):
        #return "Linker test"
        return json.dumps(self.config, indent=4)


if __name__ == "__main__":
    l = Linker()
    l.link()


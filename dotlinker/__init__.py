#!/usr/bin/python

#Filename: __init__.py
#Author: Douglas Anderson
#Created: 2013/02/04

import json
import os
from dotlinker.Ask import YesNoSorta

thisDir = "dotlinker/"
configFile = "config.json"
configPath = os.path.realpath(thisDir + configFile)
homePath = os.path.expanduser("~")
class Linker:
    config = None

    def __init__(self):
        r = open(configPath)
        configStr = ""
        for line in r:
            configStr += line.strip()
        self.config = json.loads(configStr)


    def link(self):
        subGroups = self.config["groups"]
        print "Dotlinker... Rock it"
        for group in self.config["groups"]:
            print "\nGroup:", group
            groupVals = subGroups[group]
            #print json.dumps(groupVals, indent=4)
            linkKeys = []
            linkKeyStr = ""
            for key in groupVals:
                if key != "default":
                    linkKeys.append(key)
                    linkKeyStr += key + " "
            print "    ", linkKeyStr
            ans = YesNoSorta("Would you like to link this group?", groupVals["default"])
            if ans == "y":
                self.linkGroup(linkKeys, groupVals)
            elif ans == "n":
                print "Not Linking the Group"
            elif ans == "s":
                self.linkSome(linkKeys, groupVals)


    def linkGroup(self, keys, group):
            print "link the group"
            for key in keys:
                val = group[key]
                print val


    def linkSome(self, keys, group):
            print "link the members of the group on a individual basis"
            for key in keys:
                val = group[key]
                print val
                # key is the name of the dotfile
                # val is the name of the link
                self.checkForFile( os.path.join(homePath, val))

# TODO zshrc is misspelled on purpose.. FIX

    def checkForFile(self, fn):
        print fn
        if os.path.exists(fn):
            ans = Ask.YesNo("This file already exists. Attempt to move it?")
            if ans == "y":
                self.moveExistingFile(fn)
            elif ans == "n":
                print "Not Moving file"

    def checkForExistingLink(self):
        pass

    def moveExistingFile(self, fn):
        pass

    def createLink(self):
        pass

    def __str__(self):
        #return "Linker test"
        return json.dumps(self.config, indent=4)



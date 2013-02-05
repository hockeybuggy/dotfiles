#!/usr/bin/python

#Filename: __init__.py
#Author: Douglas Anderson
#Created: 2013/02/04

import json
import os, sys
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
            for key in keys:
                val = group[key]
                targetPath = os.path.join(homePath, val)
                sourcePath = os.path.join(os.path.realpath(""), key)
                if self.checkForFile(targetPath):
                    # TODO check to see if it is a link
                    ans = Ask.YesNo(targetPath + " already exists. Attempt to move it and create a link?")
                    if ans == "y":
                        self.moveExistingFile(targetPath)
                        self.createLink(sourcePath, targetPath)
                    elif ans == "n":
                        print "Not Creating a link."
                else:
                    self.createLink(sourcePath, targetPath)


    def linkSome(self, keys, group):
            for key in keys:
                val = group[key]
                targetPath = os.path.join(homePath, val)
                sourcePath = os.path.join(os.path.realpath(""), key)
                if self.checkForFile(targetPath):
                    # TODO check to see if it is a link
                    ans = Ask.YesNo(targetPath + " already exists. Attempt to move it and create a link?")
                    if ans == "y":
                        self.moveExistingFile(targetPath)
                        self.createLink(sourcePath, targetPath)
                    elif ans == "n":
                        print "Moving existing file or not Creating a link."
                else:
                    ans = Ask.YesNo(targetPath + " does not exists. Create a link?", default="y")
                    if ans == "y":
                        self.createLink(sourcePath, targetPath)
                    elif ans == "n":
                        print "Not Creating a link."


# TODO zshrc is misspelled on purpose.. FIX

    def checkForFile(self, fn):
        if os.path.exists(fn):
            return(True)
        return(False)

    def checkForExistingLink(self):
        pass

    def moveExistingFile(self, fn):
        target = fn + ".bak"
        if not self.checkForFile(target):
            try:
                os.rename(fn, target)
            except:
                print "Could not move the file", fn, "to", target
                sys.exit(1)
        else:
            # This protection is required to protect from the methods silent overwrite
            print "Error. The file", target, "already exists. Clean up and rerun the program."
            sys.exit(1)

    def createLink(self, source, target):
        #print "SRC", source
        #print "TARGET", target
        try:
            os.symlink(source, target)
        except:
            print "Error. Could not create symlink from", source, "to", target
            sys.exit(1)



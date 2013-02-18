#!/usr/bin/python
"""
Filename: __init__.py
Author: Douglas Anderson
Created: 2013/02/04

Reads the config and asks the user for input to decide what files to link
"""

import json
import os, sys
from _dotlinker.Ask import yes_no_sorta, yes_no

class Linker:
    thisDir = "_dotlinker/"
    configFile = "config.json"
    configPath = os.path.realpath(thisDir + configFile)
    homePath = os.path.expanduser("~")
    args = None
    config = None

    def __init__(self, args):
        read = open(self.configPath)
        configStr = ""
        for line in read:
            configStr += line.strip()
        self.config = json.loads(configStr)
        read.close()
        self.args = args

    def link(self):
        if self.args.interactive:
            self.interactive_linker()
        else:
            self.automatic_linker()

    def interactive_linker(self):
        subGroups = self.config["groups"]
        print "Dotlinker running in interactive mode... Rocking"
        for group in subGroups:
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
            ans = yes_no_sorta("Would you like to link this group?", groupVals["default"])
            if ans == "y":
                self.link_group(linkKeys, groupVals)
            elif ans == "n":
                print "Not Linking the Group"
            elif ans == "s":
                self.link_some(linkKeys, groupVals)

    def automatic_linker(self):
        print "Dotlinker running in automatic mode... Rocking"

    def link_group(self, keys, group):
        for key in keys:
            val = group[key]
            target_path = os.path.join(self.homePath, val)
            source_path = os.path.join(os.path.realpath(""), key)
            if self.check_for_file(target_path):
                ans = yes_no(target_path + " already exists. Attempt to move it and create a link?")
                if ans == "y":
                    self.move_existing_file(target_path)
                    self.create_link(source_path, target_path)
                elif ans == "n":
                    print "Not Creating a link."
            else:
                self.create_link(source_path, target_path)


    def link_some(self, keys, group):
        for key in keys:
            val = group[key]
            target_path = os.path.join(self.homePath, val)
            source_path = os.path.join(os.path.realpath(""), key)
            if self.check_for_file(target_path):
                ans = yes_no(target_path + " already exists. Attempt to move it and create a link?")
                if ans == "y":
                    self.move_existing_file(target_path)
                    self.create_link(source_path, target_path)
                elif ans == "n":
                    print "Moving existing file or not Creating a link."
            else:
                ans = Ask.yes_no(target_path + " does not exists. Create a link?", default="y")
                if ans == "y":
                    self.create_link(source_path, target_path)
                    print "Link Created."
                elif ans == "n":
                    print "Not Creating a link."

    def check_for_file(self, fn):
        if os.path.exists(fn):
            return(True)
        return(False)

    def check_for_existing_link(self):
        pass

    def move_existing_file(self, fn):
        target = fn + ".bak"
        if not self.check_for_file(target):
            try:
                os.rename(fn, target)
            except:
                print "Could not move the file", fn, "to", target
                sys.exit(1)
        else:
            # This protection is required to protect from the methods silent overwrite
            print "Error. The file", target, "already exists. Clean up and rerun the program."
            sys.exit(1)

    def create_link(self, source, target):
        #print "SRC", source
        #print "TARGET", target
        try:
            os.symlink(source, target)
        except:
            print "Error. Could not create symlink from", source, "to", target
            sys.exit(1)



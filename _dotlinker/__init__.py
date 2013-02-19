#!/usr/bin/python
"""
Filename: __init__.py
Author  : Douglas Anderson

Reads the config and asks the user for input to decide what files to link
"""

import os, sys, re, json
from _dotlinker.Ask import yes_no_sorta, yes_no

class Linker:
    thisDir = "_dotlinker/"
    configFile = "config.json"
    configPath = os.path.realpath(thisDir + configFile)
    homeDir = os.path.expanduser("~")
    config = None

    def __init__(self):
        read = open(self.configPath)
        configStr = ""
        for line in read:
            configStr += line.strip()
        self.config = json.loads(configStr)
        read.close()

    def interactive_linker(self):
        print "Dotlinker running in interactive mode... Rocking"
        groups = self.config["groups"]
        for groupKey in groups:
            print "\nGroup:", groupKey
            group = groups[groupKey]
            ans = yes_no_sorta("Would you like to link this group?", group["default"])
            if ans == "y":
                self.link_group_gentle(group)
            elif ans == "n":
                print "Not Linking the Group"
            elif ans == "s":
                self.link_some(group)

    def automatic_linker(self):
        print "Dotlinker running in automatic mode... Rocking"
        groups = self.config["groups"]
        for groupKey in groups:
            group = groups[groupKey]
            if group["default"] == "y":
                print "Linking", groupKey
                self.link_group_force(group)

    def get_group_keys(self, group):
        linkKeys = []
        linkKeyStr = ""
        for key in group:
            if key != "default":
                linkKeys.append(key)
                linkKeyStr += key + " "
        print "\t", linkKeyStr
        return linkKeys

    def link_group_gentle(self, group):
        keys = self.get_group_keys(group)
        for key in keys:
            target_path = os.path.join(self.homeDir, group[key])
            source_path = os.path.join(os.path.realpath(""), key)
            if self.check_for_file(target_path):
                self.resolve_conflict(source_path, target_path)
            else:
                self.create_link(source_path, target_path)

    def link_group_force(self, group):
        keys = self.get_group_keys(group)
        for key in keys:
            target_path = os.path.join(self.homeDir, group[key])
            source_path = os.path.join(os.path.realpath(""), key)
            if self.check_for_file(target_path):
                os.remove(target_path)
            self.create_link(source_path, target_path)

    def link_some(self, group):
        keys = self.get_group_keys(group)
        for key in keys:
            val = group[key]
            target_path = os.path.join(self.homeDir, val)
            source_path = os.path.join(os.path.realpath(""), key)
            if self.check_for_file(target_path):
                self.resolve_conflict(source_path, target_path)
            else:
                ans = Ask.yes_no(target_path + " does not exists. Create a link?", default="y")
                if ans == "y":
                    self.create_link(source_path, target_path)
                    print "Link Created."
                elif ans == "n":
                    print "Not Creating a link."

    def resolve_conflict(self, source, target):
        ans = yes_no(target + " already exists. Attempt to move it and create a link?")
        if ans == "y":
            self.move_existing_file(target)
            self.create_link(source, target)
        elif ans == "n":
            print "Not moving existing file and not Creating a link."

    def check_for_file(self, fn):
        if os.path.exists(fn):
            return(True)
        return(False)

    def check_for_existing_link(self):
        #TODO check to see if the file that exists is the file that this would create anyways
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
            print "Error. The file", target, "already exists. Clean up .bak files or run with the -c flag."
            sys.exit(1)


    def create_link(self, source, target):
        #print "SRC", source
        #print "TARGET", target
        try:
            os.symlink(source, target)
        except:
            print "Error. Could not create symlink from", source, "to", target
            sys.exit(1)

    def clean_backups(self):
        print "Cleaning"
        done_shit_all = True
        ex = re.compile(r".*.bak")
        for fn in os.listdir(self.homeDir):
            if ex.match(fn):
                done_shit_all = False
                print "\tRemoving", fn
                os.remove(os.path.join(self.homeDir, fn))
        if done_shit_all:
            print "\tDid not remove any files during clean"


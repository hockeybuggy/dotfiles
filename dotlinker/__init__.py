#!/usr/bin/python

#Filename: __init__.py
#Author: Douglas Anderson
#Created: 2013/02/04

import json
import os
from dotlinker.Ask import YesNoSorta

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
        subGroups = self.config["groups"]
        for group in self.config["groups"]:
            print "Group:", group
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
                print "link the group"
            elif ans == "n":
                print "don't link the group"
            elif ans == "s":
                print "link the members of the group on a individual basis"




    def __str__(self):
        #return "Linker test"
        return json.dumps(self.config, indent=4)



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
        for group in self.config["groups"]:
            print group


    def __str__(self):
        #return "Linker test"
        return json.dumps(self.config, indent=4)



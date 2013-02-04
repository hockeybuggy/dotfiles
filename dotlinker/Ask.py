
#Filename: Ask.py
#Author: Douglas Anderson
#Created: 2013/02/04


def YesNo(message, default='n'):
    default = default.lower()
    if default == "y":
        options = "[Y/n]"
    elif default == "n":
        options = "[y/N]"
    else:
        options = "[y/n]"
    while True:
        inStr = raw_input(message + options).lower()
        if inStr == "":
            return(default)
        elif inStr == "y" or inStr == "n":
            return(inStr)
    return(None)

def YesNoSorta(message, default='n'):
    default = default.lower()
    if default == "y":
        options = "[Y/n/s]"
    elif default == "n":
        options = "[y/N/s]"
    elif default == "s":
        options = "[y/n/S]"
    else:
        options = "[y/n/s]"
    while True:
        inStr = raw_input(message + options).lower()
        if inStr == "":
            return(default)
        elif inStr == "y" or inStr == "x" or inStr == "s":
            return(inStr)
    return(None)


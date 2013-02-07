"""
Filename: Ask.py
Author: Douglas Anderson
Created: 2013/02/04

Asks the user questions and return a normalized single character
"""

def yes_no(message, default='n'):
    """
    Asks the users the message as a question then prompts for input and loop
    until valid. Returns 'y' or 'n' for a response
    """
    default = default.lower()
    if default == "y":
        options = "[Y/n]"
    elif default == "n":
        options = "[y/N]"
    else:
        options = "[y/n]"
    while True:
        instr = raw_input(message + options).lower()
        if instr == "":
            return(default)
        elif instr == "y" or instr == "n":
            return(instr)
    return(None)


def yes_no_sorta(message, default='n'):
    """
    Asks the users the message as a question then prompts for input and loop
    until valid. Returns 'y' or 'n' or 's' for a response
    """
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
        instr = raw_input(message + options).lower()
        if instr == "":
            return(default)
        elif instr == "y" or instr == "n" or instr == "s":
            return(instr)
    return(None)


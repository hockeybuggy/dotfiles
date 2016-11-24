#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function
import sys
import re
import shlex
from subprocess import Popen, PIPE, check_output

# This is from Kentaro Wada's modifications of Olivier Verdier's
# "zsh-git-prompt": https://git.io/vXNYp


def get_tagname_or_hash():
    """return tagname if exists else hash"""
    cmd = 'git log -1 --format="%h%d"'
    output = check_output(shlex.split(cmd)).decode('utf-8').strip()
    hash_, tagname = None, None
    # get hash
    m = re.search('\(.*\)$', output)
    if m:
        hash_ = output[:m.start()-1]
    # get tagname
    m = re.search('tag: .*[,\)]', output)
    if m:
        tagname = 'tags/' + output[m.start()+len('tag: '): m.end()-1]

    if tagname:
        return tagname
    elif hash_:
        return hash_
    return None


def index_state(untracked, staged, changed, conflicts):
    return " ".join([
        str(staged),
        str(conflicts),
        str(changed),
        str(untracked),
    ])


def ahead_behind(ahead, behind):
    # Accepts two ints representing the number of commits ahead and the number
    # of commits behind the remote.
    # Returns a string that is a visual representation of the
    return ""


def open_git_status():
    """
    `git status --porcelain --branch` can collect all information
    branch, remote_branch, untracked, staged, changed, conflicts, ahead, behind
    """
    po = Popen(['git', 'status', '--porcelain', '--branch'], stdout=PIPE, stderr=PIPE)
    stdout, _ = po.communicate()
    if po.returncode != 0:
        sys.exit(0)  # Not a git repository
    return stdout


def get_status_vector(line):
    """
    Accepts a line of status and produces a vector representing
    (ahead, behind, untracked, staged, changed, conflicts)
    """
    branch = None
    untracked, staged, changed, conflicts = [], [], [], []
    ahead, behind = 0, 0
    st = (line[0], line[1], line[2:])

    if st[0] == '#' and st[1] == '#':
        if re.search('Initial commit on', st[2]):
            branch = st[2].split(' ')[-1]
        elif re.search('no branch', st[2]):  # detached status
            branch = get_tagname_or_hash()
        elif len(st[2].strip().split('...')) == 1:
            branch = st[2].strip()
        else:
            # current and remote branch info
            branch, rest = st[2].strip().split('...')
            if len(rest.split(' ')) == 1:
                # remote_branch = rest.split(' ')[0]
                pass
            else:
                # ahead or behind
                divergence = ' '.join(rest.split(' ')[1:])
                divergence = divergence.lstrip('[').rstrip(']')
                for div in divergence.split(', '):
                    if 'ahead' in div:
                        ahead = int(div[len('ahead '):].strip())
                    elif 'behind' in div:
                        behind = int(div[len('behind '):].strip())
    elif st[0] == '?' and st[1] == '?':
        untracked.append(st)
    else:
        if st[1] == 'M':
            changed.append(st)
        if st[0] == 'U':
            conflicts.append(st)
        elif st[0] != ' ':
            staged.append(st)
    return (branch, ahead, behind, staged, untracked, changed, conflicts)


stdout = open_git_status()

# collect git status information
status_vectors = [
    get_status_vector(line)
    for line in stdout.decode('utf-8').splitlines()
]

# TODO this isn't great replace the lists and tuples with a dict
branch = [status[0] for status in status_vectors if status[0]][0]

ahead = sum(status[1] for status in status_vectors)
behind = sum(status[2] for status in status_vectors)

staged = sum(len(status[3]) for status in status_vectors)
untracked = sum(len(status[4]) for status in status_vectors)
changed = sum(len(status[5]) for status in status_vectors)
conflicts = sum(len(status[6]) for status in status_vectors)


output = ''.join([
    "(",
    branch,
    " | ",
    ahead_behind(ahead, behind),
    index_state(untracked, staged, changed, conflicts),
    ")",
])

print(output)

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from __future__ import print_function
import sys
import re
import shlex
from subprocess import Popen, PIPE, check_output

# This is based on Kentaro Wada's modifications of Olivier Verdier's
# "zsh-git-prompt": https://git.io/vXNYp

COLOR_OUTPUT = True


class tcolors:
    _RED =  '\033[0;31m'  # What the colours look like with Solarized on
    _BLUE = '\033[0;34m'
    _CYAN = '\033[0;36m'
    _PURPLE = '\033[1;35m'
    _PINK = '\033[0;35m'
    _GREEN = '\033[0;32m'
    _YELLOW = '\033[0;33m'
    _GREY = '\033[92m'

    RESET = '\033[0m'
    SEPARATOR = _GREY

    BRANCH = _PURPLE
    AHEAD = _CYAN
    BEHIND = _PINK

    CONFLICT = _RED
    STAGED = _GREEN
    CHANGED = _BLUE
    UNTRACKED = _YELLOW
    CLEAN = _GREEN


def term_color(message, color_code):
    if not COLOR_OUTPUT:
        return message
    return color_code + message + tcolors.RESET


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
        tagname = u'tags/' + output[m.start()+len('tag: '): m.end()-1]

    if tagname:
        return tagname
    elif hash_:
        return hash_
    return None


def index_state(untracked, staged, changed, conflicts):
    state = u""  # TODO this name sucks
    if conflicts:
        state += term_color(u"✖{}".format(conflicts), tcolors.CONFLICT)
    if staged:
        state += term_color(u"●{}".format(staged), tcolors.STAGED)
    if changed:
        state += term_color(u"✚{}".format(changed), tcolors.CHANGED)
    if untracked:
        state += term_color(u"…", tcolors.UNTRACKED)
    if not state:
        state = term_color(u"✔ ", tcolors.CLEAN)
    return state


def ahead_behind(ahead, behind):
    # Accepts two ints representing the number of commits ahead and the number
    # of commits behind the remote. Returns a string that is a visual
    # representation of how ahead or behind it is
    state = u""  # TODO this name sucks
    if ahead:
        state += term_color(u"↑{}".format(ahead), tcolors.AHEAD)
    if behind:
        state += term_color(u"↓{}".format(behind), tcolors.BEHIND)
    return state


def open_git_status():
    """
    `git status --porcelain --branch` can collect all information
    branch, remote_branch, untracked, staged, changed, conflicts, ahead, behind
    """
    po = Popen(["git", "status", "--porcelain", "--branch"], stdout=PIPE, stderr=PIPE)
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
                # remote_branch = rest.split(' ')[0]  # This was here before me
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

    return dict(
        branch=branch,
        ahead=ahead,
        behind=behind,
        staged=len(staged),
        untracked=len(untracked),
        changed=len(changed),
        conflicts=len(conflicts),
    )


stdout = open_git_status()

# collect git status information
status_vectors = [
    get_status_vector(line) for line in stdout.decode("utf-8").splitlines()
]

branch_name = [status["branch"] for status in status_vectors if status["branch"]][0]
branch = term_color(branch_name, tcolors.BRANCH)


ahead = sum(status["ahead"] for status in status_vectors) + 1
behind = sum(status["behind"] for status in status_vectors) + 1

staged = sum(status["staged"] for status in status_vectors) + 1
untracked = sum(status["untracked"] for status in status_vectors) + 1
changed = sum(status["changed"] for status in status_vectors) + 1
conflicts = sum(status["conflicts"] for status in status_vectors) + 1


output = u"".join([
    term_color(u"(", tcolors.SEPARATOR),
    branch,
    ahead_behind(ahead, behind),
    term_color(u"|", tcolors.SEPARATOR),
    index_state(untracked, staged, changed, conflicts),
    term_color(u")", tcolors.SEPARATOR),
])

print(output)

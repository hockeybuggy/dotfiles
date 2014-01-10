#!/bin/bash

tmux has-session -t work

if [ $? != 0 ]
then
    tmux new-session -s work -n editor -d
    tmux new-window -t work:3 -n server
    tmux select-window -t work:1
fi

tmux -2 attach-session -t work

#!/bin/bash

tmux new-session -s work -n editor -d
tmux new-window -t work:3 -n server

tmux select-window -t work:1
tmux -2 attach-session -t work

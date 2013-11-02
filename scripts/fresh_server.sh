#!/bin/bash

echo "Installing the basics"

sudo apt-get install g++ make checkinstall rxvt-unicode-256color
echo ' _______     _________ _    _  ____  _   _ '
echo '|  __ \ \   / /__   __| |  | |/ __ \| \ | |'
echo '| |__) \ \_/ /   | |  | |__| | |  | |  \| |'
echo '|  ___/ \   /    | |  |  __  | |  | | . ` |'
echo '| |      | |     | |  | |  | | |__| | |\  |'
echo '|_|      |_|     |_|  |_|  |_|\____/|_| \_|'

sudo apt-get install python2.7 python-dev python-doc

echo ' _   _  ____  _____  ______   _     '
echo '| \ | |/ __ \|  __ \|  ____| (_)    '
echo '|  \| | |  | | |  | | |__     _ ___ '
echo '| . ` | |  | | |  | |  __|   | / __|'
echo '| |\  | |__| | |__| | |____ _| \__ \'
echo '|_| \_|\____/|_____/|______(_) |___/'
echo '                            _/ |    '
echo '                           |__/     '

sudo add-apt-repository ppa:chris-lea.node.js
sudo apt-get update
sudo apt-get install nodejs

echo '  _______      ____  __ '
echo ' |  __ \ \    / /  \/  |'
echo ' | |__) \ \  / /| \  / |'
echo ' |  _  / \ \/ / | |\/| |'
echo ' | | \ \  \  /  | |  | |'
echo ' |_|  \_\  \/   |_|  |_|'

\curl -L https://get.rvm.io | bash

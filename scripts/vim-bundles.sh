#!/bin/sh

echo 'Updating vim plugins...'

vim "+call dein#install()"

echo 'Done.'

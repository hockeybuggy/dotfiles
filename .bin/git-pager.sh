#!/bin/bash
# Smart git pager that uses diff-so-fancy if available, falls back to less

if command -v diff-so-fancy > /dev/null 2>&1; then
  diff-so-fancy | less --tabs=4 -RFX
else
  less --tabs=4 -RFX
fi

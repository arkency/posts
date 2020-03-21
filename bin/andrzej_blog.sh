#!/bin/sh

set -e
set -x

./bin/new_post -b -c \
  -t "$1" \
  -a "Andrzej Krzywda" \
  -e /Applications/iA\ Writer.app/Contents/MacOS/iA\ Writer

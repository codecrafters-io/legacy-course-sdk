#!/bin/sh
set -e

mkdir /tmp/app

HOME=$(mktemp -d)
XDG_CACHE_HOME="$HOME"
CODECRAFTERS_SUBMISSION_DIR=/tmp/app

export HOME
export XDG_CACHE_HOME
export CODECRAFTERS_SUBMISSION_DIR

cp -R /app/. $CODECRAFTERS_SUBMISSION_DIR
cd $CODECRAFTERS_SUBMISSION_DIR

test -d /app-cached && cp -p -R /app-cached/. $CODECRAFTERS_SUBMISSION_DIR
test -f /codecrafters-precompile.sh && /bin/sh /codecrafters-precompile.sh > /dev/null

exec /tester/test.sh

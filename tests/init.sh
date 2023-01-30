#!/bin/sh
set -e

rm -rf /tmp/app
cp -r /app /tmp/app
cd /tmp/app

CODECRAFTERS_SUBMISSION_DIR=/tmp/app

test -d /app-cached && cp -p -R /app-cached/. "$CODECRAFTERS_SUBMISSION_DIR"
test -f /codecrafters-precompile.sh && /bin/sh /codecrafters-precompile.sh > /dev/null

exec /tester/test.sh

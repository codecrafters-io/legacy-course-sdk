#!/bin/sh
set -e

test -d /app-cached && cp -R /app-cached/. /app
test -f /codecrafters-precompile.sh && /bin/sh /codecrafters-precompile.sh > /dev/null

exec /tester/test.sh

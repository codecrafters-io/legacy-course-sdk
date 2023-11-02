#!/bin/sh
set -e

CODECRAFTERS_SUBMISSION_DIR=/app

test -d /app-cached && cp -p -R /app-cached/. "$CODECRAFTERS_SUBMISSION_DIR"
test -f /codecrafters-precompile.sh && /bin/sh /codecrafters-precompile.sh | sed 's/^/[compile] /'

exec /tester/test.sh

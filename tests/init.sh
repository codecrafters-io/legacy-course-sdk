#!/bin/sh
set -e

if test -d /app-cached; then
  for x in /app-cached/* /app-cached/.[!.]* /app-cached/..?*; do
    if [ -e "$x" ]; then mv -- "$x" /app/; fi
  done
fi

test -f /codecrafters-precompile.sh && /bin/sh /codecrafters-precompile.sh > /dev/null

exec /tester/test.sh

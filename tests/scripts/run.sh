#!/bin/sh
# Runs every script test in this folder; exits non-zero if any fails.
here="$(cd "$(dirname "$0")" && pwd)"
status=0
for t in "$here"/*.test.sh; do "$t" || status=1; done
exit "$status"

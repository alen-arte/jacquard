# Shared setup for tests/scripts/*.test.sh (POSIX sh). Each test starts with: . "$(dirname "$0")/lib.sh"
# Gives: here (the tests folder), kit (the kit root), tmp (a scratch folder removed on exit), fail <message>,
# a git identity and config isolated from the user's, and finish <suite name> as the last line.
here="$(cd "$(dirname "$0")" && pwd)"
kit="$(cd "$here/../.." && pwd)"
tmp="$(mktemp -d)" || exit 1
trap 'rm -rf "$tmp"' EXIT
export GIT_AUTHOR_NAME=Tester GIT_AUTHOR_EMAIL=tester@example.com GIT_COMMITTER_NAME=Tester GIT_COMMITTER_EMAIL=tester@example.com
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
fails=0
fail() { echo "✗ $1"; fails=$((fails + 1)); }
finish() { [ "$fails" = 0 ] && echo "✓ $1: all cases pass" && exit 0; echo "✗ $1: $fails failing"; exit 1; }

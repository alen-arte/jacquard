#!/bin/sh
# Tests for scripts/session-start.sh, the SessionStart hook. Run from anywhere: tests/scripts/session-start.test.sh
# Exits 0 when every case passes; prints one line per failure.
. "$(dirname "$0")/lib.sh"
start="$kit/scripts/session-start.sh"
guard="$kit/scripts/away-guard.sh"
[ -x "$start" ] || { echo "✗ $start missing or not executable"; exit 1; }

export CLAUDE_PROJECT_DIR="$tmp"
unset CLAUDECODE CLAUDE_CODE_ENTRYPOINT CLAUDE_CODE_REMOTE
export JACQUARD_AGENT=1   # a session that marks itself as Claude, as the template's env does
marker="$tmp/.local/away/.away-active"
installed="$(awk '/^## [0-9]+\.[0-9]+\.[0-9]+/ { print $2; exit }' "$kit/CHANGELOG.md")"
mkdir -p "$tmp/.local"
behind() { printf '%s\n' '- **Phase:** 1 · **Kit version:** 0.0.1' > "$tmp/.local/index.md"; }
# go <script> <session id> <source> [env…]: output in $out, status in $st
go() { s="$1" id="$2" src="$3"; shift 3; out="$(printf '{"session_id":"%s","source":"%s"}' "$id" "$src" | env "$@" "$s" .local 2>/dev/null)"; st=$?; }
reminder='Jacquard: this project is on kit 0.0.1; the installed kit is '

# H1 · A stretch of work that starts in a project behind the kit gets one reminder line, and the hook succeeds
behind
go "$start" s9 startup
[ "$st" = 0 ] || fail "H1 the hook must exit 0 (got $st)"
case "$out" in "$reminder"*"offer /jacquard-update"*) ;; *) fail "H1 a project behind gets one reminder line (got: $out)";; esac
[ "$(printf '%s\n' "$out" | grep -c .)" = 1 ] || fail "H1 exactly one line of context (got: $out)"
go "$start" s9 resume
case "$out" in "$reminder"*) ;; *) fail "H1b a resumed session gets the reminder too (got: $out)";; esac

# H2 · No reminder on compaction, after /clear, in a cloud session, or when the project is up to date
for src in compact clear; do
  go "$start" s9 "$src"; [ -z "$out" ] || fail "H2 no reminder on $src (got: $out)"
done
go "$start" s9 startup CLAUDE_CODE_REMOTE=true
[ -z "$out" ] || fail "H2 no reminder in a cloud session (got: $out)"
printf '%s\n' "- **Kit version:** $installed" > "$tmp/.local/index.md"
go "$start" s9 startup
[ -z "$out" ] || fail "H2 a project up to date gets nothing (got: $out)"

# H3 · The Away part: the Away session resumed, cleared or forked starts in Present; compaction and other sessions keep it
for src in resume clear fork startup; do
  CLAUDE_CODE_SESSION_ID=s1 "$guard" on .local >/dev/null 2>&1
  go "$start" s1 "$src"
  [ ! -e "$marker" ] || fail "H3 the Away session's $src must clear the marker"
done
CLAUDE_CODE_SESSION_ID=s1 "$guard" on .local >/dev/null 2>&1
go "$start" s1 compact
[ -e "$marker" ] || fail "H3 compaction must keep the marker"
go "$start" s2 startup
[ -e "$marker" ] || fail "H3 another session starting must keep the marker"
rm -f "$marker"

# H4 · Each job on its own: when the Away part fails, the reminder still comes, and the hook still succeeds
copy="$tmp/kitcopy"; mkdir -p "$copy/scripts"
cp "$kit/CHANGELOG.md" "$copy/"; cp "$kit/scripts/session-start.sh" "$kit/scripts/common.sh" "$kit/scripts/kit-version.sh" "$copy/scripts/"
printf '#!/bin/sh\necho broken >&2\nexit 1\n' > "$copy/scripts/away-guard.sh"; chmod +x "$copy/scripts/"*.sh
behind
go "$copy/scripts/session-start.sh" s9 startup
[ "$st" = 0 ] || fail "H4 a failing job must not fail the hook (got $st)"
case "$out" in "$reminder"*) ;; *) fail "H4 the reminder must come even when the Away part fails (got: $out)";; esac

# H5 · Settings made before session-start.sh name away-guard.sh session-start: it does every job
CLAUDE_CODE_SESSION_ID=s1 "$guard" on .local >/dev/null 2>&1
out="$(printf '{"session_id":"s1","source":"resume"}' | "$guard" session-start .local 2>/dev/null)"
[ ! -e "$marker" ] || fail "H5 the old entry must still clear the Away session's marker"
case "$out" in "$reminder"*) ;; *) fail "H5 the old entry must still give the reminder (got: $out)";; esac

# H6 · Misuse: no local folder is a usage error that prints nothing as context
out="$(printf '{}' | "$start" 2>/dev/null)"; st=$?
[ "$st" = 2 ] && [ -z "$out" ] || fail "H6 no local folder must exit 2 and print nothing"

# H8 · A session with none of the Claude markers gets one warning line first (the push guard relies on them); never in
# a cloud session; any one marker is enough
printf '%s\n' "- **Kit version:** $installed" > "$tmp/.local/index.md"
go "$start" s9 startup JACQUARD_AGENT=
case "$out" in "Jacquard: this session does not mark itself as Claude"*) ;; *) fail "H8 no Claude marker: one warning line (got: $out)";; esac
go "$start" s9 startup JACQUARD_AGENT= CLAUDE_CODE_REMOTE=true
[ -z "$out" ] || fail "H8 no warning in a cloud session (got: $out)"
for v in CLAUDECODE=1 CLAUDE_CODE_ENTRYPOINT=cli; do
  go "$start" s9 startup JACQUARD_AGENT= "$v"; [ -z "$out" ] || fail "H8 $v alone marks Claude (got: $out)"
done

# H7 · The permissions template runs this dispatcher on SessionStart, and nothing else there
template="$kit/templates/project/claude-settings.local.template.json"
start_hooks="$(awk '/"SessionStart": \[/ { on = 1; next } on && /^    \]/ { exit } on' "$template")"
printf '%s\n' "$start_hooks" | grep -qF '"command": "\"$HOME/.claude/jacquard/scripts/session-start.sh\" \"{{LOCAL_FOLDER}}\""' || fail "H7 the template's SessionStart must run session-start.sh"
[ "$(printf '%s\n' "$start_hooks" | grep -c '"command"')" = 1 ] || fail "H7 one SessionStart command: new jobs go in session-start.sh"

finish "session-start"

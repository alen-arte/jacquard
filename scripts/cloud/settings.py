# Jacquard cloud bridge: the cloud session's .claude/settings.json, from the computer's permissions (one source: the
# repo's settings.local.json) plus the kit's bootstrap and the Away guard. Called by cloud.sh prepare.
# Usage: settings.py <settings.local.json> <settings.json to write> <local folder>
import json, shlex, sys

src, dst, local_folder = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    perms = json.load(open(src)).get("permissions", {})
except FileNotFoundError:
    perms = {}
local = ("~/repos", "/home/", "~/.cache")              # rules about this computer's own paths do not apply there
# the framework is reached there both as ~/.claude/jacquard (a link) and as the kit folder itself
mapped = lambda rules: [v for r in rules if not any(x in r for x in local)
                        for v in dict.fromkeys([r, r.replace("~/.claude/jacquard/", "**/.cloud-kit/jacquard/")])]
# the kit changes on the computer only (only Edit rules are consulted for writes); the kit branch never reaches main
kit_files = ("~/.claude/jacquard/**", "**/.cloud-kit/jacquard/**", "**/.cloud-kit/personal/**", "**/.cloud-kit/bootstrap.sh",
             "**/.cloud-kit/local-folder", "**/.claude/settings.json", "**/CLAUDE.local.md")
no_main = [f"Bash(git push {p})" for b in ("main", "master") for p in (f"* {b}", f"* {b}:*", f"*:{b}", f"*:refs/heads/{b}")]
deny = mapped(perms.get("deny", [])) + [f"Edit({p})" for p in kit_files] + no_main
guard = lambda event: [{"hooks": [{"type": "command", "timeout": 10,
    "command": '[ "$CLAUDE_CODE_REMOTE" = true ] || exit 0; sh "$HOME/.claude/jacquard/scripts/away-guard.sh" %s %s' % (event, shlex.quote(local_folder))}]}]
json.dump({
    "permissions": {"deny": list(dict.fromkeys(deny)), "ask": mapped(perms.get("ask", []))},
    "hooks": {
        "SessionStart": [{"hooks": [{"type": "command", "timeout": 20, "command": 'sh "$CLAUDE_PROJECT_DIR/.cloud-kit/bootstrap.sh"'}]}],
        "PermissionRequest": guard("permission"),
        "Elicitation": guard("elicitation"),
    },
}, open(dst, "w"), indent=2, ensure_ascii=False)

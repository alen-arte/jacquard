# Jacquard cloud bridge: the cloud session's .claude/settings.json, from the computer's permissions (one source: the
# repo's settings.local.json) plus the kit's bootstrap and the Away guard. Called by cloud.sh prepare.
# Usage: settings.py <settings.local.json> <settings.json to write> <local folder>
import json, sys

src, dst, local_folder = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    perms = json.load(open(src)).get("permissions", {})
except FileNotFoundError:
    perms = {}
local = ("~/repos", "/home/", "~/.cache")              # rules about this computer's own paths do not apply there
# the framework is reached there both as ~/.claude/jacquard (a link) and as the kit folder itself
mapped = lambda rules: [v for r in rules if not any(x in r for x in local)
                        for v in dict.fromkeys([r, r.replace("~/.claude/jacquard/", "**/.cloud-kit/jacquard/")])]
deny = mapped(perms.get("deny", [])) + [f"{t}({p}/**)" for t in ("Edit", "Write") for p in ("~/.claude/jacquard", "**/.cloud-kit/jacquard", "**/.cloud-kit/personal")]
guard = lambda event: [{"hooks": [{"type": "command", "timeout": 10,
    "command": '[ "$CLAUDE_CODE_REMOTE" = true ] || exit 0; sh "$HOME/.claude/jacquard/scripts/away-guard.sh" %s "%s"' % (event, local_folder)}]}]
json.dump({
    "permissions": {"deny": list(dict.fromkeys(deny)), "ask": mapped(perms.get("ask", []))},
    "hooks": {
        "SessionStart": [{"hooks": [{"type": "command", "timeout": 20, "command": 'sh "$CLAUDE_PROJECT_DIR/.cloud-kit/bootstrap.sh"'}]}],
        "PermissionRequest": guard("permission"),
        "Elicitation": guard("elicitation"),
    },
}, open(dst, "w"), indent=2, ensure_ascii=False)

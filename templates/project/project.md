---
name: {{PROJECT_SLUG}}-project
description: "Facts about this project: product, people and boundaries, stack, commands, environments, what is irreversible here. Read when a task needs them."
---

# Project facts

## Product

- **What it is:** {{PRODUCT}}
- **For whom:** {{AUDIENCE}}
- **Devices and context of use:** {{DEVICES_AND_CONTEXT}}
- **Domain risks:** {{DOMAIN_RISKS}} (money, health, privacy, minors… or "none")

## People and boundaries

- **Starting point:** {{A|B|C|D}}
- **The user's role:** {{USER_ROLE}} · **Who decides:** {{DECIDER}}
- **Collaborators and the areas they own:** {{COLLABORATORS_OR_NONE}}
- **Boundary rule:** connecting to their code is allowed; changing what it does is a note for its owner. Notes go to: {{NOTES_LOCATION, default "only in reports"}}
- **Shared files Claude may write to** (outside the local folder): {{SHARED_WRITABLE, default none}}

## Planning and design sources

- **Planning:** {{OWN_ROADMAP | EXTERNAL_READ_ONLY_PATH}}
- **Design:** {{OWN_MANUAL | EXTERNAL_PATH | NOT_YET}}

## Stack

Verified in official documentation on {{DATE}}; recheck when upgrading.

{{STACK_TABLE}}

## Commands

| Purpose | Command |
|---|---|
| Install | {{INSTALL}} |
| Dev server / preview | {{DEV}} (URL: {{PREVIEW_URL}}) |
| Automatic checks | {{CHECKS}} |
| Unit tests | {{UNIT}} |
| End-to-end tests | {{E2E}} |
| Build | {{BUILD}} |
| Visual check (`render_check`) | {{RENDER_CHECK, default "none"; e.g. "<preview command> + <headless capture command>", see `~/.claude/jacquard/core/visual-qa.md`}} |

## Code limits

"Core default" uses the value in core standards › Scalability; change values here, never in the code.

- **File size:** warn at {{FILE_WARN, default "core default"}} lines · cap at {{FILE_CAP, default "core default"}} · **Function size:** flag past {{FUNCTION_FLAG, default "core default"}} lines
- **Areas** (modules or folders, for counting refactor debt): {{AREAS, default "set in the walking skeleton"}}
- **Where configuration, tokens and copy live:** {{CONFIG_PATHS, each in backticks, e.g. "`src/config/`, `src/styles/tokens.css`, `src/copy/`"; default "set in the walking skeleton"}}
- **Files exempt from the code limits:** {{SIZE_EXEMPT, globs in backticks, e.g. "`src/generated/*`"; default "generated files and fixtures"}}
- **Names that repeat by convention** (not reported as duplicates): {{REPEATED_NAMES, each in backticks, e.g. the framework's required exports; default "none"}}
- **Folders that run separately** (cannot share code with the rest, so names are not compared across them): {{SEPARATE_FOLDERS, folders or globs, each in backticks, e.g. "`supabase/functions/`"; default "none"}}
- **Per-frame budget** (code that runs every frame): {{FRAME_BUDGET_MS, default "none"}}

The kit's `structure-check.sh` reads this section: the file warning and cap numbers, and the values in backticks on the configuration, exempt, repeated-names and separate-folders lines. Function size is not measured by it.

## Environments

{{ENVIRONMENTS, default "none yet"}} (production changes always need the user's explicit OK)

## Git

- **Shared main branch:** {{MAIN}} · **Push to main:** {{ALLOWED_ON_REQUEST | FORBIDDEN}}
- **Branch convention from collaborators, if any:** {{BRANCH_CONVENTION, default none}}
- **Cloud remote** (only with `cloud_sync: on`, `core/git.md` › Cloud sync): {{CLOUD_REMOTE, default "`origin`"; a separate private remote only when origin is shared with other people, also set in the repo's local git config `jacquard.cloudRemote`}}

## Irreversible here

Beyond the core list: {{PROJECT_IRREVERSIBLES, from the stack and domain risks, confirmed in the proposal; default none}}

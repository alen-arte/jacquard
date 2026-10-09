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
- **Boundary rule:** connecting to their code is allowed; changing what it does is a note for its owner. Notes go to: {{NOTES_LOCATION}}
- **Shared files Claude may write to** (outside the local folder): {{SHARED_WRITABLE_OR_NONE}}

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

## Environments

{{ENVIRONMENTS}} (production changes always need the user's explicit OK)

## Git

- **Shared main branch:** {{MAIN}} · **Push to main:** {{ALLOWED_ON_REQUEST | FORBIDDEN}}
- **Branch convention from collaborators, if any:** {{BRANCH_CONVENTION_OR_NONE}}

## Irreversible here

Beyond the core list: {{PROJECT_IRREVERSIBLES_OR_NONE}}

# Role library

Templates that `/kickoff` turns into a project's roles. Each role is a world top-tier senior in its field. Roles are lenses inside one session (no extra cost) except reviewers, which run as subagents for independence.

## Catalogue

| Role | File | Default |
|---|---|---|
| Product designer | `build/product-designer.md` | Yes |
| Frontend engineer (web, mobile or desktop client) | `build/frontend-engineer.md` | Yes, when there is an interface |
| Backend / data engineer | `build/backend-data-engineer.md` | Yes, when there is stored data or a server |
| QA reviewer | `review/qa-reviewer.md` | Always |
| Engineering advisor | `review/engineering-advisor.md` | Proposed when the user does not review code, or for long-lived products |
| Security and privacy reviewer | `review/security-privacy-reviewer.md` | Proposed when there is auth, personal data, money or external integrations |
| Domain advisor | `review/domain-advisor.template.md` | Created per project from the domain (e.g. learning, finance, health) |
| Design critic | `review/design-critic.md` | Proposed when there is an interface; acts only inside a design exploration (`core/design-exploration.md`) |

Kickoff may split or add engineering roles when the stack needs it (e.g. separate web and mobile clients, platform/infrastructure), using `_role-template.md`.

## How kickoff fills a role

- **`{{DOMAIN_FLUENCY}}`**: two to four lines of real knowledge and care for the product's domain, so every role builds with it (e.g. for a running app, the designer is also a runner who knows pacing and training plans). Cheap and always active; deeper domain judgement belongs to a domain advisor.
- **`{{USER_RELATION}}`**: how this role relates to the user in this project. Examples: "The user is the designer: propose from this perspective, the user decides." / "This role decides within its rights and reports." / "This area belongs to a collaborator: boundaries only."
- **`{{TRIGGERS}}`** (advisors): the exact situations that activate the role.
- **Domain advisor only:** `{{DOMAIN_SLUG}}` (kebab-case, for the file name), `{{DOMAIN}}`, `{{DOMAIN_PRACTICE}}` (what people in the domain actually do), `{{MISSION_QUESTION}}` (the one question it answers), `{{EVALUATION_CRITERIA}}` (three to six checkable lines).

Roles that do not apply are not created; a review the kit still calls for runs from the kit's file (`core/review.md`). A role for an area owned by someone else is not created; its boundary goes in `project.md`.

## Activation

- One owner per task. Other roles join only when their trigger fires (see each file and `core/review.md`).
- Read a role file only when that role acts.

# Personal layer (template)

Your personal layer is a **private** repository, never part of the public kit. Copy this folder into a new private repo and clone it to `~/.claude/jacquard-personal/`.

```
jacquard-personal/            (private repo)
  preferences.md              your values for the keys in core/preferences.default.md, plus global rule adaptations
  privacy-terms.txt           names, handles, project names and paths that must never appear in public files
  projects/<project>/         the real files of each project's local folder
```

## Project files live here, linked from each repo

Each project's local folder (`<repo>/.jacquard`) is a link to `projects/<project>/`:

- the project's git ignores the link (`.git/info/exclude`), so nothing personal reaches the project repo;
- this private repo versions and backs up the files, with history;
- Claude reads them from the project as if they were there.

Large or disposable outputs (for example Away HTML reports) can be ignored in this repo with its own `.gitignore`.

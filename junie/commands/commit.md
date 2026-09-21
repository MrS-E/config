---
description: Commit the current changes as a series of small, logically encapsulated commits with short, precise messages
allowPromptArgument: true
---

Commit the current working-tree changes, following these rules exactly.

## Scope

$prompt

If the scope above is empty, commit everything that is currently changed and untracked (excluding generated files, build artifacts and secrets).

## Commit rules

- **Short but precise messages.** Describe the change concretely — what was changed and where. One clear sentence, not a paragraph.
- **Do not classify the commit.** No `refactor:`, `fix:`, `feat:`, `chore:` or any other type prefix. Plain descriptive messages only.
- **Small commits, more of them.** Prefer several small commits over one big one. Never make a commit that is too large.
- **One logical change per commit.** Each commit must be a small, self-contained, logically encapsulated change that stands on its own and could be reverted independently.
- **DO NOT CO-AUTHOR YOURSELF.** Never add a `Co-authored-by` trailer or any other attribution for the assistant. The commit must have the user as the sole author.

## Procedure

1. Inspect the changes (`git status`, `git diff`, `git diff --staged`) and group them into logical units.
2. Decide the order of the commits so each one is coherent on its own.
3. For each group: stage only the files/hunks that belong to it, then commit with its own short, precise message.
4. Do not push. Do not amend or rebase existing commits unless the user explicitly asks.
5. Finish with a short summary listing each commit hash and its message.

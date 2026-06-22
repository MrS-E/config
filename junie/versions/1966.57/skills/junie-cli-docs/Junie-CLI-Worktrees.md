# Worktrees

<show-structure for="chapter" depth="3" />

Junie CLI integrates with [git worktrees](https://git-scm.com/docs/git-worktree) to help you work on multiple
tasks in the same repository without branch conflicts. You can use existing worktrees, create new ones with
predefined names, and switch between them — all without leaving Junie.

A git worktree is a linked checkout of the same repository in a separate directory. Each worktree has its own
working tree and index, so you can have different branches checked out simultaneously. Junie makes it easy to
manage worktrees and switch the agent between them.

## The /worktree command

Run `/worktree` to open the worktree menu. From there you can:

- **Switch to an existing worktree** — select one of the worktrees already created for this repository.
- **Create a new worktree** — Junie creates a new git worktree with a predefined name
  (`<project>-junie-wt-01`, `-02`, and so on) as a sibling directory of your project.
- **Switch back to the original project** — return to the main working directory.

After switching, the agent completely resets its state to the new worktree. This makes `/worktree` ideal for
use before starting a new task.

### Typical workflow

1. Pre-create a few worktrees so that build caches are ready in each one.
2. When you start a new task, run `/worktree` and switch to one of the prepared worktrees.
3. Prompt Junie to create a branch and rebase to fresh `main`.
4. Work on the task in the worktree while the original directory stays untouched.

### Transferring uncommitted changes

If your current working directory has uncommitted changes when you switch to a worktree, Junie asks whether to
transfer them or start clean:

- **Transfer changes** — Junie uses `git stash` to move uncommitted changes from the source directory to the
  target worktree.
- **Start clean** — the worktree starts with no uncommitted changes.

If the stash cannot be applied cleanly (for example, due to conflicts), Junie reports the issue and leaves the
changes in the stash so you can resolve them manually.

## Concurrent session detection

When a second Junie instance starts on the same project directory, Junie detects the conflict and reminds you
about possible issues with two agents operating on the same files. It then offers to switch to a worktree so
each instance works in its own isolated directory.

This serves two purposes:

- **Workspace management** — prevents two agents from making conflicting changes to the same files.
- **Onboarding** — helps you discover worktree support in Junie if you haven't used it before.

## Auto worktree detection

If the agent navigates to a worktree directory during a session — whether because you prompted it to or a shell
command changed the working directory — Junie detects the switch and offers to restart with a clean task in the
new worktree.

Accepting the restart:

- Prevents the agent from continuing to operate on files in the old worktree.
- Switches the Junie project to the new directory, which affects where Junie looks for the `.junie` folder,
  loads skills, reads MCP configurations, and so on.

## Limitations

- Worktree support requires a git repository. It is not available for projects that are not tracked by git.
- Worktree directories are created as siblings of the project directory (for example,
  `../my-project-junie-wt-01`). Make sure the parent directory is writable.

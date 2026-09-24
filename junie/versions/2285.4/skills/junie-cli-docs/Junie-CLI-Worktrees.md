# Parallel sessions and worktrees

<show-structure for="chapter" depth="3" />

<tldr>
  Start another live session with <code>/new</code>, switch sessions with <code>/history</code>, and isolate file changes with <code>/worktree</code>.
</tldr>

Junie can keep multiple live sessions in one interactive terminal. You can start another task, let existing
sessions continue in the background, and switch back to them later without losing their scrollback or current state.

Parallel sessions share the file system of the project or worktree they are running in. When you want several sessions
to make code changes at the same time, use [Git worktrees](https://git-scm.com/docs/git-worktree) so each task works in
its own checkout.

## Start another session

Use `/new` when you want to start another task without quitting the current Junie instance. The current session stays
live in the background, and Junie opens a new interactive session.

To start with text already in the prompt, add it after the command:

```text
/new update the tests for the payment flow
```

Use this workflow when you need to keep one task available while you investigate or work on another one:

1. Start a task in Junie.
2. Run `/new` or `/new <prompt>` to open another live session.
3. Work in the new session while the previous live session stays available in Task history.
4. Use `/history` to switch between live sessions when you need to return to another task.

## Switch with Task history

Run `/history` to open **Task history**. It lists live sessions from the current Junie instance together with saved
sessions from previous runs. Start typing to search the list, select a row to open that session, or press `Esc` to return
to the current session.

Task history shows the task name, project, and status or last activity time.

| Status | Meaning |
|--------|---------|
| `Working…` | The live session is currently running a task. |
| `Awaiting input` | The live session is waiting for your reply, approval, or another interactive choice. |
| `Ready` | The live session is idle and ready to continue. |
| Relative time, such as `5m ago` | The row is a saved session that is not currently live in this Junie instance. |
{width="706"}

Switching to a live session does not restart it. Junie brings that session to the foreground with its existing
conversation and terminal output preserved.

### Cross-process sessions

Task history can also show live sessions that are open in another Junie instance. These rows are dimmed and cannot
be opened from the current instance.

To continue one of those sessions, switch to the terminal where that Junie instance is running. This prevents two
terminal UIs from controlling the same live session at the same time.

## Use worktrees to isolate file changes

Parallel sessions do not isolate files by themselves. If two sessions work in the same project directory, they can edit
the same files and overwrite each other's changes. For simultaneous code changes, give each task its own Git worktree.

A Git worktree is a linked checkout of the same repository in a separate directory. Each worktree has its own working
tree and index, so different branches can be checked out simultaneously.

### The `/worktree` command

Run `/worktree` to open the worktree menu. From there you can:

- **Switch to an existing worktree**: select one of the worktrees already created for this repository.
- **Create a new worktree**: Junie creates a new Git worktree with a predefined name, such as
  `<project>-junie-wt-01`, `<project>-junie-wt-02`, and so on, as a sibling directory of your project.
- **Switch back to the original project**: return to the main working directory.

After switching, Junie resets the current session state for the new worktree. Use `/worktree` before starting a new
task or at the beginning of a new live session.

### Safe parallel-work workflow

1. Start a separate live session with `/new`.
2. In that session, run `/worktree` and switch to an existing worktree or create a new one.
3. Ask Junie to create or switch to the branch for that task.
4. Work on the task in that worktree while other sessions use their own directories.
5. Use `/history` to switch between the live sessions.

If you often work this way, pre-create a few worktrees so build caches are ready before you start parallel tasks.

### Transferring uncommitted changes

If the current working directory has uncommitted changes when you switch to a worktree, Junie asks whether to move
them to the target workspace or start clean:

- **Transfer changes to workspace**: Junie uses `git stash` to move uncommitted changes from the source directory to
  the target worktree.
- **Start with a clean workspace**: the target worktree starts with no uncommitted changes.

If the stash cannot be applied cleanly, for example because of conflicts, Junie reports the issue and leaves the
changes in the stash so you can resolve them manually.


## Limitations

- Worktree support requires a git repository. It is not available for projects that are not tracked by git.
- Worktree directories are created as siblings of the project directory, for example `../my-project-junie-wt-01`. Make
  sure the parent directory is writable.

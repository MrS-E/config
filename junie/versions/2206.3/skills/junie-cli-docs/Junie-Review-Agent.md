# Code review agent

<show-structure for="chapter" depth="3" />

<tldr>Slash command to invoke local code review: <code>/review</code></tldr>

Junie's code review feature uses a tailored subagent with optimized resource consumption for code review tasks:
instead of running a full agent session, it uses a more focused system prompt and a subset of read-only tools,
focusing on the changed lines of code.

> Local code review can only be run on projects in Git repositories.
> {style="note"}

Use local code review when you want to get a quick sanity check before opening a pull request,
review your own changes after a long coding session, or review your current branch against `main`.


## How it works

To run a local review of code changes, Junie CLI:

* **Loads the relevant code diff** according to the user-defined request scope.
* **Uses a focused prompt and toolset**: the agent can open files and search the project to understand context, but it never edits files, runs builds or tests, creates files, or commits and pushes changes.
* **Follows your guidelines and skills**: the agent reads project guidelines and any code-review-related [agent skills](Agent-Skills.md) and applies their instructions.
* **Supports follow-ups**: the review runs as its own session that can be resumed, so you can ask follow-up questions such as *"Is the fix I just pushed good enough?"* without re-explaining the context.


## Usage

### Standard checks

When you invoke the `/review` slash command, Junie CLI detects the Git state of your project and opens a wizard with available review targets:

- **From Main**: compares your current branch against `main`. Shown only when a `main` branch exists, and you are not currently on it.
- **Last Commit**: reviews the changes introduced in the most recent commit.
- **Unstaged Changes**: reviews the code you have modified but not yet committed.

![](review_wizard.png){width="706" border-effect="line"}

### Custom instructions

You can scope the review to a specific concern or set of changes by adding plain-text instructions after the command:

```console
/review focusing on performance and memory leaks
```

```console
/review the last two commits
```

Junie CLI will prioritize your instructions while still performing its standard review checks.

## Navigating review results

Junie CLI presents the findings in a dedicated review screen where you can:

* Browse the list of suggestions grouped by file.
* View the relevant code context for each of the suggestions.
* Accept or dismiss suggestions one by one, or select several suggestions and accept or dismiss them at once.

Critical findings, such as security vulnerabilities, crashes, data loss, or correctness issues that break functionality,
are prefixed with a `[CRITICAL]` label. When a fix is simple and safe, Junie CLI includes a ready-to-apply code suggestion.

Closing the review screen finishes the review and returns you to the task screen, keeping the review as part of the same
session history.

## Also available in

- **Headless mode**: Use the `--review` flag with the `junie` command in your terminal. You can optionally provide
  a natural language description to guide the review.

  ```console
  # Review current changes in the repository
  junie --review
  
  # Review changes with specific instructions
  junie --review "Check for potential null pointer exceptions in the new logic"
  
  # Compare with a specific branch
  junie --review "Compare my changes with the develop branch"
  ```
- **GitHub CI/CD pipelines**: To trigger Junie's code review agent on opened or updated GitHub pull requests, use the
  [Junie GitHub Action](Junie-on-GitHub.md) for automated code reviews.
  See the [cookbook](Automated-code-reviews.md) for details.
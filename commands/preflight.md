---
description: Review the current changes for what a reviewer would flag before you open the PR.
argument-hint: "[base-branch-or-ref]"
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
---

# PR Pre-flight

Review the changes about to go into a pull request and flag what a reviewer
would nitpick — before it's public. This is not a full code review: only
report things a reasonable reviewer would actually comment on.

## 0. Repo-specific config (optional)

If a `.preflight.md` file exists at the repository root, read it first — it
may add extra checks, exclude paths from review (e.g. a `vendor/` or
`generated/` directory), or override a default below (e.g. a different size
threshold, an error-handling convention specific to this repo). It's plain
prose, not a schema — apply it as additional instructions alongside the
checks below, and where it conflicts with a default here, the repo config
wins — except an ignore rule never suppresses a hardcoded secret found in
newly added code; a path exclusion means "don't style-review this", not
"don't flag a live credential leaking here."

## 1. Get the diff

- If `$ARGUMENTS` names a branch/ref, diff against it: `git diff $ARGUMENTS...HEAD`.
- Otherwise, find the default branch (`git symbolic-ref refs/remotes/origin/HEAD`,
  falling back to whichever of `main`/`master` exists) and diff the current
  branch against it: `git diff <default>...HEAD`.
- Also include anything not yet committed (`git diff` and `git diff --staged`)
  — that's going in the PR too.
- If there's no diff at all (clean tree, nothing ahead of the default branch),
  say so and stop. Don't invent findings.
- If the default branch can't be determined and no argument was given, fall
  back to `git diff HEAD` (uncommitted changes only) and say that's what you
  did.

## 2. Scope the review

If the diff touches more than ~15 files or ~800 changed lines, state that
size up front unconditionally (file count, line count) before any findings,
then focus depth on the files with the most logic changes — skip generated
files, lockfiles, vendored code, and pure renames — rather than reviewing
everything shallowly. Name which files you deprioritized and why, even if
the whole diff turns out to be low-risk filler.

## 3. Check each touched file against its own neighborhood

Read the touched file's unchanged portions and 1-2 sibling files in the same
directory to learn the local convention *as it actually is here*, not an
abstract style guide, then flag deviations:

- **Naming drift** — a new function/variable that doesn't match the naming
  pattern already used nearby.
- **Error-handling drift** — a new code path that skips error handling every
  sibling in the same file already does (e.g. every other DB call here checks
  an error, this one doesn't).
- **Missing tests** — non-trivial new logic (a branch, a loop, a parser, a new
  function) in a file that has a sibling test file which wasn't touched.

## 4. Check every changed file for these, regardless of neighborhood

- Leftover debug output (`console.log`, `print(`, `debugger`, commented-out
  code blocks).
- `TODO`/`FIXME`/`XXX` added with no ticket reference or explanation.
- Hardcoded secrets, tokens, API keys, or `.env` values.
- Unused imports or variables introduced by this diff (not pre-existing ones).

## 5. Report

One line per finding: `file:line — what's wrong — one-sentence fix`. Group by
file. Order by severity (secrets and missing error handling first, style nits
last). Skip categories with nothing to report — don't pad the output to look
thorough. If nothing at all was found, say that plainly in one line.

# PR Pre-flight

A Claude Code plugin that reviews your changes for what a reviewer would
flag — before you open the PR. Not a full code review: it only reports the
things a reasonable reviewer would actually comment on.

It catches:

- **Convention drift** — naming or error-handling that doesn't match the
  file's own neighborhood (read from the surrounding unchanged code and
  sibling files, not an abstract style guide).
- **Missing tests** — non-trivial new logic in a file that has a sibling
  test file which wasn't touched.
- **Leftover debug output** — `console.log`, `print(`, `debugger`,
  commented-out code.
- **Unexplained `TODO`/`FIXME`** — added with no ticket or explanation.
- **Hardcoded secrets** — API keys, tokens, `.env` values.
- **Unused imports/variables** introduced by the diff.

## Install

```
/plugin install pr-preflight@github Samanyu-dev/pr-preflight
```

Or for local development:

```
claude --plugin-dir /path/to/pr-preflight
```

## Usage

```
/pr-preflight:preflight
```

Diffs your current branch against the repo's default branch (auto-detected
from `origin/HEAD`, falling back to a local `main`/`master`), plus anything
uncommitted. To diff against a specific ref instead:

```
/pr-preflight:preflight some-branch
```

If there's nothing to review (clean tree, no commits ahead of default), it
says so and stops — it won't invent findings.

On a large diff (~15+ files or ~800+ changed lines), it states the size up
front and focuses depth on the files with real logic changes, naming what it
deprioritized (generated files, lockfiles, vendored code, pure renames).

## Repo-specific config

Drop a `.preflight.md` at your repo root to extend or override the defaults.
It's plain prose — read and applied by the command itself, not parsed by a
schema:

```md
# Repo preflight config

- Ignore everything under `vendor/` — third-party code we don't own.
- We use `snake_case` for function names in `src/`, not camelCase.
- Treat diffs under 1500 lines as "small" — our files are just long.
```

One rule never bends: a path exclusion silences *style* review for that
path, but a hardcoded secret found in newly-added code is always flagged
regardless of `.preflight.md`.

Don't want to write it by hand? Generate a starting point instead:

```
/pr-preflight:init
```

Scans the repo for its dominant naming convention, where tests actually
live (sibling files vs. a separate `test/` directory), and any tracked
vendored/generated directories, then writes `.preflight.md` from what it
found — not a generic template. If the naming convention is genuinely
mixed, it says so rather than forcing a rule. Won't overwrite an existing
`.preflight.md` unless you pass `--force`.

## Reminder before you push or open a PR

The plugin also installs a hook: right before Claude runs `git push` or
`gh pr create`, it surfaces a one-line reminder to run
`/pr-preflight:preflight` first, if you haven't this session. It doesn't
block the command — it's a permission-confirm prompt with the reminder as
the reason, so you can approve and continue immediately. Any other command
is untouched; the hook only reacts to those two.

## Why this and not just asking Claude to "review my diff"

A generic review prompt checks against a style guide it's guessing at. This
one reads the actual file and its siblings first, so what it flags is a real
deviation from how *this* code already looks — not a generic lint pass.

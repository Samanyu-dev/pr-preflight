---
description: Apply the safe, mechanical fixes from a preflight review directly, and report what's left for a human decision.
argument-hint: "[base-branch-or-ref]"
allowed-tools: ["Bash", "Read", "Grep", "Glob", "Edit"]
---

# PR Pre-flight: fix

Run the same review as `/pr-preflight:preflight` (same diff-scoping rules:
get the diff, respect `.preflight.md`, scope large diffs the same way), but
instead of only reporting findings, apply the ones that are mechanical and
safe to change without a design decision. Leave everything else as a report.

## Safe to auto-fix — apply directly with Edit

- Leftover debug output (`console.log`, `print(`, `debugger` statements,
  commented-out code blocks) — remove the line/block.
- Unused imports or variables introduced by this diff — remove them.

## Never auto-fix — report only, same as `/pr-preflight:preflight`

- **Hardcoded secrets** — deleting the line doesn't rotate the credential,
  and it may already be compromised; this needs a human to rotate it, not an
  automated edit. Report it exactly as `/pr-preflight:preflight` would.
- **Missing tests** — writing a test the author didn't ask for is a design
  decision, not a mechanical fix.
- **Naming/error-handling drift** — the "right" fix depends on intent (was
  this deliberate?); don't guess and rewrite someone's logic.
- **Unexplained `TODO`/`FIXME`** — removing or resolving it requires knowing
  what it meant; just report it.

## Report

After applying the safe fixes, report:

- **Applied**: one line per fix, `file:line — what was removed`.
- **Left for you**: the remaining findings, formatted exactly like
  `/pr-preflight:preflight`'s report (grouped by file, severity order).

If nothing safe to fix was found, say so and just show the
`/pr-preflight:preflight`-style report. If there's no diff at all, say so and
stop, same as the base command.

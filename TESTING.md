# Testing

There's no automated harness — `commands/preflight.md` is a prompt, not a
script, so "testing" means running it against fixture repos with known
issues and checking the output. Do this after any change to the command:

```
claude --plugin-dir /path/to/pr-preflight -p "/pr-preflight:preflight <ref>" \
  --allowedTools "Bash,Read,Grep,Glob"
```

run from inside a scratch git fixture (never a real repo you care about).

Scenarios covered so far, each confirmed to produce the expected finding:

1. **Basic diff** — a file with a new function missing error handling that
   every sibling function has, plus a leftover `console.log`, an unexplained
   `TODO`, a hardcoded secret, and no added test. All five were flagged;
   nothing else was invented.
2. **Clean tree, no origin remote** — correctly reports nothing to review
   instead of guessing.
3. **No-arg fallback** — with no origin remote, falls back to a local
   `main`/`master` and diffs against it.
4. **Huge diff** (20 files, 900 lines of filler) — states size up front
   unconditionally, correctly identifies filler vs. real logic, still caught
   a real bug (invalid syntax) buried in the filler.
5. **`.preflight.md` config** — a path exclusion (`vendor/`) suppressed style
   findings there, a custom naming rule was applied, and a secret in the
   excluded path was still flagged (exclusions don't silence secrets).

`/pr-preflight:init` gets the same treatment:

```
claude --plugin-dir /path/to/pr-preflight -p "/pr-preflight:init [--force]" \
  --allowedTools "Bash,Read,Grep,Glob,Write"
```

6. **Consistent camelCase JS repo**, `test/` dir mirroring `src/`, tracked
   `vendor/leftpad/` — all three detected and written correctly; without
   `--force` a second run refused to overwrite and printed the existing file;
   `--force` regenerated it and additionally noted an untested source file.
7. **Genuinely mixed naming** (snake_case/PascalCase/camelCase in one file)
   — reported as mixed with no majority instead of forcing a rule; sibling
   `*.test.py` layout detected; exclusion section omitted (nothing found)
   rather than padded.

## Hooks

`hooks/hooks.json` + `hooks/preflight-reminder.sh` can't be verified by
reading the prose — a hook either matches the actual JSON schema Claude Code
enforces or it silently fails validation. Verify with `--debug-file` and
`--include-hook-events`, grepping the log for `Hook PreToolUse`:

```
claude --plugin-dir /path/to/pr-preflight --debug-file /tmp/debug.log \
  --include-hook-events -p "Run this exact bash command and report its exit code: git push" \
  --allowedTools "Bash"
grep -i "Hook PreToolUse" /tmp/debug.log
```

8. **First attempt failed validation** — `permissionDecision: "suggest"` +
   `additionalContext` isn't valid for `PreToolUse` (only `allow`/`deny`/
   `ask`/`defer` + `permissionDecisionReason`/`updatedInput` are). The debug
   log printed the exact expected schema; fixed to `permissionDecision: "ask"`
   + `permissionDecisionReason`.
9. **`git push`** and **`gh pr create --title x --body y`** — both matched;
   the model's own transcript shows it received the reminder text via the
   permission-ask reason and reported it back, rather than the raw command
   output.
10. **Unrelated command** (`ls`) — no `Hook PreToolUse` log line at all, i.e.
    no prompt/friction added for anything that isn't a push or PR creation.

## `/pr-preflight:fix`

Same fixture-repo method, with `Edit` added to `--allowedTools`.

11. **Mixed diff** (unused import + `console.log` + secret + TODO + missing
    error handling, no test for the new function) — the two mechanical
    issues (unused import, `console.log`) were removed via `Edit` and listed
    under "Applied"; the secret, TODO, and error-handling drift were left
    untouched and reported under "Left for you", exactly as intended. The
    secret line was never edited.
12. **Known limitation observed**: in that same run, "missing test for the
    new function" wasn't surfaced in "Left for you", even though a
    same-fixture run of the base `/pr-preflight:preflight` command did catch
    it. This is model run-to-run variance in what gets surfaced, not a
    prompt/schema bug — the category is explicitly listed in `fix.md`'s
    "never auto-fix" list. Worth a spot-check after any future prompt change
    to `fix.md`, but not something a prompt tweak reliably fixes.

## Fan-out (`file-group-reviewer` subagent, large diffs)

13. **Dispatch mechanism, isolated** — a minimal prompt telling Claude to
    dispatch the `file-group-reviewer` subagent on one file confirmed real
    dispatch (`--debug-file` showed `agentType=pr-preflight:file-group-reviewer`,
    a real turn count, a real completion), and it correctly caught a planted
    `console.log`. It also correctly reported it had no Bash to fetch the
    diff itself — confirming the parent command must pass each file's hunk
    inline, as designed.
14. **End-to-end, three escalating fixtures** — 20 files/66 lines, 20
    files/264 lines, then 80 files/1104 lines, each with 2 real planted bugs
    (a secret + debug output + missing error handling, and a second missing-
    error-handling case) buried among filler. In all three, `preflight`
    stated the size up front as required, but chose **not** to fan out —
    judging it could review everything directly without losing depth — and
    still caught both planted bugs correctly every time, plus reasonable
    extra findings (dead code, a duplication nit) no test asked for.
15. **Why fan-out didn't trigger**: the model's own context window is large
    enough that even an 1100-line, 80-file diff is comfortably reviewable in
    one pass; the size thresholds in `preflight.md` are stated as guidance,
    not a hard trigger, so the model reasonably treats them that way. Fan-out
    is a safety valve for a diff big/varied enough that direct reading
    genuinely isn't feasible — verified functional in isolation (#13), but
    not reproduced end-to-end without an even larger, hand-varied fixture
    than was practical to script here. If this ever needs re-verifying,
    don't bother scaling up a generated fixture further (a repeated pattern
    is trivially easy for the model to verify without reading it all,
    regardless of file count) — use a real large PR diff with genuinely
    distinct logic per file instead.

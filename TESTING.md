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

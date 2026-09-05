#!/bin/bash
# Non-blocking PreToolUse hook: reminds about /pr-preflight:preflight before a
# push or PR creation. Never denies the command — exits 0 with no output for
# every command that isn't a match.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+create'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: "Reminder: run /pr-preflight:preflight before this push/PR if you have not already this session."
    }
  }'
fi
exit 0

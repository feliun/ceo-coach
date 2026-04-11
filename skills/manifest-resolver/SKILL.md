---
type: reference
status: active
created: 01-03-2026
tags: [context, skill, ceo-coach, config, manifest]
---
# Skill: Manifest Resolver

Purpose:
Resolve config file paths for any ceo-coach domain before command execution by reading the manifest.yaml registry.

When to use:
- Before any `ceo-coach:*` decorator command that needs config files
- Before any `ceo-coach` command that needs config files
- Standalone for debugging config resolution (`Invoke manifest-resolver for domain: ceo-coach`)

---

## Context

The ceo-coach plugin resolves configs via a hardcoded 2-step lookup:
`./path` → `~/.claude/path`. This skill **overrides** that lookup by reading a
central manifest (`agents/ceo-coach/commands/manifest.yaml`) and resolving paths from there.

This means config files can live anywhere — `system/memory/`, project root, `~/.claude/`,
or any future location — without modifying plugin code.

## Algorithm

1. **Read** `agents/ceo-coach/commands/manifest.yaml`
2. **Select the domain** from the calling command's namespace (e.g., `ceo-coach:review` → domain `ceo-coach`)
3. **For each config key** in that domain:
   a. Iterate through the `paths` array in order
   b. Expand `~` to the user's home directory
   c. Resolve relative paths against the project root
   d. **Check existence:**
      - For `format: directory` → check the directory exists AND contains at least one file matching the expected pattern (`.md` for contacts)
      - For `format: yaml` or `format: markdown` → check the file exists and is readable
   e. **Return the first match** as the resolved path
   f. If no path matches and `required: true` → flag as ❌ with fix instructions
   g. If no path matches and `required: false` → flag as ⚠️ optional, skip

## Output

After resolution, emit a compact status block that the calling command can reference:

```
Config resolution (ceo-coach):
  ✅ rocks             → system/memory/config/rocks.yaml
  ✅ calendar-rules    → system/memory/principles/Calendar rules.md
  ⚠️ delegation-log   → not found (optional, skipping)
  ✅ leadership-framework → references/leadership-framework.md
```

If ALL configs resolve successfully, collapse to a single line:
```
Config: all resolved (4/4 from system/memory/)
```

## Integration with graceful-degradation

This skill runs **before** the plugin's `graceful-degradation` skill. When a
`ceo-coach:*` decorator command invokes manifest-resolver:

1. Manifest-resolver resolves the actual file paths
2. The decorator command then invokes the original plugin command
3. The plugin's graceful-degradation skill runs its own checks — but the config
   files are already symlinked/resolved, so it finds them at the expected locations

**Key point:** The decorator commands handle the path override. The plugin commands
don't need to know about the manifest — they just see files at the paths they expect.

## Error Handling

- If `manifest.yaml` itself is missing → report error and fall back to plugin defaults
- If a required config is missing from all paths → report ❌ with the reference template path
- Never hard-fail the entire command over a missing optional config
- Always continue to the calling command with whatever was resolved

## Standalone Usage

To debug config resolution without running a full command:

```
Invoke manifest-resolver for domain: ceo-coach
```

This prints the full resolution table without delegating to any command.

---

## Anti-patterns

- Do NOT hard-fail the entire command over a missing optional config — continue with whatever was resolved
- Do NOT bypass the manifest by hardcoding config paths — always resolve through manifest.yaml
- Do NOT skip checking directory contents for `format: directory` configs — an empty directory is different from a missing one

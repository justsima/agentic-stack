# Security & Privacy

This repo is designed to be **published safely**. What that means in practice:

## What never ships
- **No API keys / secrets.** The public Exa and Context7 endpoints need no key.
  agentmemory runs locally. If you later add keyed services, put keys in a local
  `.env` or your tool's secret store — never in a committed file.
- **No personal data.** The wiki (`wiki-scaffold/`) and memory are **empty
  templates**. `job-application-helper` reads a **git-ignored** `references/profile.md`
  that you create locally from `profile.template.md`.

## The safety hooks (agentic-config)
- `block-dangerous.sh` — blocks destructive bash before it runs.
- `block-secrets.sh` — blocks writing obvious secrets/keys into files.
- `session-context.sh` — injects recent context at session start.
- `verify-before-stop.sh` — nudges verification before claiming done.

The recommended-settings fragment keeps `defaultMode: default` (not
`bypassPermissions`) and ships a destructive-command **deny-list** as a safety net.

## If you're adapting this from your own setup
Before publishing a fork, scan for leaks:
```bash
grep -rinE 'sk-[a-z0-9]{12,}|api[_-]?key|secret|token|bearer ' . \
  | grep -vE 'placeholder|YOUR_|example|\.template|_what|README'
```
And confirm no real `profile.md`, no real wiki content, and no keys in any
`settings*.json` you include.

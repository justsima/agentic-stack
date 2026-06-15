# Contributing to agentic-stack

Thanks for helping make this better! 🙌

## Add or change a plugin
1. Put it under `plugins/<name>/` with a `.claude-plugin/plugin.json`.
2. List it in `.claude-plugin/marketplace.json`.
3. Run `claude plugin validate .` — it must pass.
4. Skills go in `plugins/<name>/skills/<name>/SKILL.md` so they stay portable to Cursor/Codex/Antigravity.

## The one sacred rule
**Ship the engine, never the data.** No API keys, no secrets, no personal content.
- Personal files belong in git-ignored locations (e.g. `references/profile.md`).
- Run the leak check before pushing:
  ```bash
  grep -rinE 'sk-[a-z0-9]{12,}|api[_-]?key|secret|token|bearer ' . \
    | grep -vE 'placeholder|YOUR_|example|\.template|README|block-secrets'
  ```

## Quick local test
```bash
./install.sh --dry-run        # preview the installer
claude plugin validate .      # validate manifests
```

## Style
- Keep skills procedural and tool-agnostic where possible.
- Match the existing voice: concise, benefit-first, no fluff.

Open a PR with the template checklist. New `market-scout` categories and new tool adapters are especially welcome.

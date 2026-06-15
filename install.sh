#!/usr/bin/env bash
# ============================================================================
#  agentic-stack installer
#  Seamless setup for Claude Code: plugins + MCP servers + wiki scaffold.
#  Required MCPs: exa (public), agentmemory, context7.  Optional: the rest.
#  Safe to re-run. Nothing here needs sudo. No secrets are written.
# ============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MKT="agentic-stack"                       # marketplace name (see .claude-plugin/marketplace.json)
WIKI_DIR="${AGENTIC_WIKI_DIR:-$HOME/agentic-wiki}"
RESEARCH_DIR="${AGENTIC_RESEARCH_DIR:-$HOME/research}"

# ---- pretty output -------------------------------------------------------
if [ -t 1 ]; then B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; R=$'\033[31m'; X=$'\033[0m'; else B=""; G=""; Y=""; C=""; R=""; X=""; fi
say()  { printf '%s\n' "$*"; }
hdr()  { printf '\n%s\n' "${B}${C}== $* ==${X}"; }
ok()   { printf '%s\n' "${G}✓${X} $*"; }
warn() { printf '%s\n' "${Y}!${X} $*"; }
err()  { printf '%s\n' "${R}✗${X} $*"; }
have() { command -v "$1" >/dev/null 2>&1; }
ask()  { # ask "Question?" default(Y/N) -> returns 0 for yes
  local q="$1" def="${2:-Y}" ans hint="[Y/n]"; [ "$def" = "N" ] && hint="[y/N]"
  if [ "${ASSUME_YES:-0}" = "1" ]; then [ "$def" = "N" ] && return 1 || return 0; fi
  read -r -p "$(printf '%s %s ' "$q" "$hint")" ans || true
  ans="${ans:-$def}"; case "$ans" in [Yy]*) return 0;; *) return 1;; esac
}

say "${B}agentic-stack — installer${X}"
say "Repo: $REPO_DIR"
[ "${1:-}" = "-y" ] && { ASSUME_YES=1; warn "running non-interactive (-y): required=yes, optional=default"; }

# ---- 0. environment ------------------------------------------------------
hdr "Checking environment"
have claude && ok "Claude Code CLI found" || warn "Claude Code CLI ('claude') not found — I'll print in-app commands you can paste instead."
have node && ok "node $(node -v 2>/dev/null)" || warn "node/npx missing — needed for agentmemory + searxng (https://nodejs.org)"
have docker && ok "docker found (enables local SearXNG)" || warn "docker not found — SearXNG (optional) needs it"
have git && ok "git found" || warn "git missing"

# helper: add an MCP server (http or stdio), degrade gracefully
mcp_http() { # name url
  if have claude; then claude mcp add --scope user --transport http "$1" "$2" >/dev/null 2>&1 && ok "MCP '$1' added" || warn "couldn't auto-add '$1'; in Claude Code run:  /mcp add $1 (HTTP) $2"; \
  else say "   in Claude Code:  claude mcp add --scope user --transport http $1 $2"; fi
}
mcp_stdio() { # name -- cmd args...
  local n="$1"; shift; shift
  if have claude; then claude mcp add --scope user "$n" -- "$@" >/dev/null 2>&1 && ok "MCP '$n' added" || warn "couldn't auto-add '$n'; run:  claude mcp add --scope user $n -- $*"; \
  else say "   in Claude Code:  claude mcp add --scope user $n -- $*"; fi
}

# ---- 1. plugins ----------------------------------------------------------
hdr "Plugins (skills, agents, commands, hooks)"
say "This bundles: ${B}ultradeep${X}, ${B}market-scout${X}, ${B}llm-council${X}, ${B}adhd${X}, ${B}job-application-helper${X}, ${B}agentic-config${X}."
if have claude; then
  claude plugin marketplace add "$REPO_DIR" >/dev/null 2>&1 && ok "marketplace '$MKT' registered (local)" \
    || warn "marketplace add failed; in Claude Code run:  /plugin marketplace add $REPO_DIR"
fi
PLUGINS=(ultradeep market-scout llm-council adhd job-application-helper agentic-config)
for p in "${PLUGINS[@]}"; do
  if ask "  Install plugin '${B}$p${X}'?" Y; then
    if have claude; then claude plugin install "$p@$MKT" >/dev/null 2>&1 && ok "$p installed" || warn "auto-install failed; in Claude Code:  /plugin install $p@$MKT"; \
    else say "   in Claude Code:  /plugin install $p@$MKT"; fi
  fi
done

# ultradeep reads + self-learns into a TUNABLE program.md at a writable user path.
# Seed it from the bundled default so both reading and the Phase-9.5 write-back work.
if [ -f "$REPO_DIR/plugins/ultradeep/deep-research/program.md" ]; then
  mkdir -p "$HOME/.claude/deep-research"
  if [ ! -f "$HOME/.claude/deep-research/program.md" ]; then
    cp "$REPO_DIR/plugins/ultradeep/deep-research/program.md" "$HOME/.claude/deep-research/program.md" \
      && ok "seeded ~/.claude/deep-research/program.md (ultradeep's tunable config — edit it to tune)"
  else ok "~/.claude/deep-research/program.md already present (left as-is)"; fi
fi

# ---- 2. REQUIRED MCP servers --------------------------------------------
hdr "Required MCP servers  (Exa public · agentmemory · Context7)"
say "These power the research skills and are installed by default."
mcp_http  exa "https://mcp.exa.ai/mcp"
mcp_stdio agentmemory -- npx -y @agentmemory/agentmemory
mcp_http  context7 "https://mcp.context7.com/mcp"

# ---- 3. OPTIONAL MCP servers --------------------------------------------
hdr "Optional MCP servers"
if ask "  Add ${B}SearXNG${X} (unlimited self-hosted meta-search; needs Docker)?" N; then
  if have docker; then
    if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^searxng$'; then
      if ask "    Start a SearXNG Docker container on :8888 now?" Y; then
        docker run -d --name searxng -p 8888:8080 \
          -e "SEARXNG_SETTINGS__server__limiter=false" \
          -e "SEARXNG_SETTINGS__search__formats=[\"html\",\"json\"]" \
          searxng/searxng >/dev/null 2>&1 && ok "SearXNG container started on :8888" \
          || warn "couldn't start container — see https://github.com/searxng/searxng-docker"
      fi
    else ok "SearXNG container already running"; fi
    mcp_stdio searxng -- npx -y mcp-searxng
    warn "SearXNG MCP expects SEARXNG_URL=http://localhost:8888 (set it in the server's env if needed)."
  else warn "Docker not found; skipping SearXNG."; fi
fi
if ask "  Add ${B}Jina Reader${X} (URL → clean markdown; free, no key)?" N; then
  mcp_http jina "https://mcp.jina.ai/sse"
  warn "Verify the current Jina MCP endpoint at https://jina.ai if it doesn't connect."
fi

# ---- 4. OPTIONAL companion marketplaces (third-party deps) --------------
hdr "Optional companions (installed from their own official sources)"
say "These aren't part of this repo — they're great third-party deps the skills can use."
if ask "  Add ${B}claude-obsidian${X} (the wiki engine: ingest/query/save into an Obsidian vault)?" N; then
  if have claude; then
    claude plugin marketplace add "https://github.com/AgriciDaniel/claude-obsidian.git" >/dev/null 2>&1 \
      && ok "claude-obsidian marketplace added — install via /plugin" \
      || warn "in Claude Code:  /plugin marketplace add https://github.com/AgriciDaniel/claude-obsidian.git"
  else say "   in Claude Code:  /plugin marketplace add https://github.com/AgriciDaniel/claude-obsidian.git"; fi
fi
if ask "  Add ${B}graphify${X} (knowledge-graph generation, used by ultradeep's optional Phase 8)?" N; then
  warn "Install graphify per its README (e.g. pipx/uv); ultradeep degrades gracefully without it."
fi

# ---- 5. wiki scaffold + research dir ------------------------------------
hdr "Workspace (wiki scaffold + research dir)"
mkdir -p "$RESEARCH_DIR" && ok "scratch dir: $RESEARCH_DIR"
if [ ! -e "$WIKI_DIR/index.md" ]; then
  if ask "  Create an EMPTY wiki scaffold at ${B}$WIKI_DIR${X}? (skills file research here)" Y; then
    mkdir -p "$WIKI_DIR"; cp -R "$REPO_DIR/wiki-scaffold/." "$WIKI_DIR/" 2>/dev/null && ok "wiki scaffold created at $WIKI_DIR"
  fi
else ok "wiki already exists at $WIKI_DIR (left untouched)"; fi

# ---- 6. recommended settings --------------------------------------------
hdr "Recommended settings (optional)"
say "A safety permission-denylist + workflow flags live in:"
say "  ${C}$REPO_DIR/plugins/agentic-config/recommended-settings.json${X}"
say "Merge what you like into ${C}~/.claude/settings.json${X} (it ships no secrets and no bypassPermissions)."

# ---- 7. summary ----------------------------------------------------------
hdr "Done"
ok "Restart Claude Code (or run /plugin) to load everything."
say ""
say "Try:   ${B}/ultradeep${X} <question>   ·   ${B}/market-scout${X} best <product>   ·   ${B}/llm-council${X} <decision>   ·   ${B}/adhd${X} <problem>"
say "Cross-tool (Cursor/Codex/Copilot): see ${C}skills-portable/README.md${X}."
say "If any auto-step was skipped, the in-app ${B}/plugin${X} and ${B}claude mcp add${X} commands above do the same thing."

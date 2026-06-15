#!/usr/bin/env bash
# ============================================================================
#  agentic-stack installer  —  seamless setup for Claude Code
#  Plugins + MCP servers + wiki scaffold, with an interactive "what to install?".
#  Required MCPs: exa (public) · agentmemory · context7.   Optional: the rest.
#
#  Usage:
#    ./install.sh            interactive (recommended)
#    ./install.sh -y         non-interactive: required=yes, optional=no
#    ./install.sh --dry-run  print everything it WOULD do, change nothing
#    ./install.sh --help
#
#  Safe to re-run (idempotent). No sudo. Writes no secrets.
# ============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MKT="agentic-stack"
WIKI_DIR="${AGENTIC_WIKI_DIR:-$HOME/agentic-wiki}"
RESEARCH_DIR="${AGENTIC_RESEARCH_DIR:-$HOME/research}"
PROGRAM_DST="$HOME/.claude/deep-research/program.md"

DRY=0; ASSUME_YES=0
for a in "$@"; do case "$a" in
  -n|--dry-run) DRY=1 ;;
  -y|--yes) ASSUME_YES=1 ;;
  -h|--help) sed -n '3,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "unknown arg: $a (try --help)"; exit 2 ;;
esac; done

# ---- pretty output -------------------------------------------------------
if [ -t 1 ]; then B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; R=$'\033[31m'; X=$'\033[0m'; else B=""; G=""; Y=""; C=""; R=""; X=""; fi
say(){ printf '%s\n' "$*"; }
hdr(){ printf '\n%s\n' "${B}${C}== $* ==${X}"; }
ok(){ printf '%s\n' "${G}✓${X} $*"; }
warn(){ printf '%s\n' "${Y}!${X} $*"; }
have(){ command -v "$1" >/dev/null 2>&1; }
drynote(){ printf '   %s[dry-run]%s %s\n' "$Y" "$X" "$*"; }
ask(){ # ask "Q?" default(Y/N) -> 0=yes
  local q="$1" def="${2:-Y}" ans hint="[Y/n]"; [ "$def" = "N" ] && hint="[y/N]"
  if [ "$ASSUME_YES" = 1 ]; then [ "$def" = "N" ] && return 1 || return 0; fi
  read -r -p "$(printf '%s %s ' "$q" "$hint")" ans </dev/tty || true
  ans="${ans:-$def}"; case "$ans" in [Yy]*) return 0;; *) return 1;; esac
}

say "${B}agentic-stack — installer${X}    repo: $REPO_DIR"
[ "$DRY" = 1 ] && warn "DRY RUN — nothing will be changed."
[ "$ASSUME_YES" = 1 ] && [ "$DRY" = 0 ] && warn "non-interactive (-y): required=yes, optional=no"

# ---- 0. environment ------------------------------------------------------
hdr "Environment"
HAVE_CLAUDE=0; have claude && { HAVE_CLAUDE=1; ok "Claude Code CLI: $(claude --version 2>/dev/null)"; } || warn "no 'claude' CLI — I'll print the in-app commands to paste instead."
have node && ok "node $(node -v 2>/dev/null)" || warn "node/npx missing — needed for agentmemory + SearXNG (https://nodejs.org)"
have docker && ok "docker present (enables optional SearXNG)" || warn "docker not found — SearXNG (optional) needs it"

# ---- idempotency helpers + add helpers -----------------------------------
mcp_has(){ [ "$HAVE_CLAUDE" = 1 ] && claude mcp list 2>/dev/null | grep -qi "\b$1\b"; }
plugin_has(){ [ "$HAVE_CLAUDE" = 1 ] && claude plugin list 2>/dev/null | grep -qi "\b$1\b"; }
mcp_http(){ # name url
  if mcp_has "$1"; then ok "MCP '$1' already configured"; return; fi
  local cmd="claude mcp add --scope user --transport http $1 $2"
  if [ "$DRY" = 1 ]; then drynote "$cmd"; return; fi
  if [ "$HAVE_CLAUDE" = 1 ]; then claude mcp add --scope user --transport http "$1" "$2" >/dev/null 2>&1 && ok "MCP '$1' added" || warn "couldn't add '$1' — run manually:  $cmd"; else say "   manual:  $cmd"; fi
}
mcp_stdio(){ # name -- cmd args...
  local n="$1"; shift; shift
  if mcp_has "$n"; then ok "MCP '$n' already configured"; return; fi
  local cmd="claude mcp add --scope user $n -- $*"
  if [ "$DRY" = 1 ]; then drynote "$cmd"; return; fi
  if [ "$HAVE_CLAUDE" = 1 ]; then claude mcp add --scope user "$n" -- "$@" >/dev/null 2>&1 && ok "MCP '$n' added" || warn "couldn't add '$n' — run manually:  $cmd"; else say "   manual:  $cmd"; fi
}

# ---- 1. plugins ----------------------------------------------------------
hdr "Plugins (skills · agents · commands · hooks)"
say "Bundle: ${B}ultradeep market-scout llm-council adhd job-application-helper agentic-config${X}"
if [ "$DRY" = 1 ]; then drynote "claude plugin marketplace add $REPO_DIR"
elif [ "$HAVE_CLAUDE" = 1 ]; then
  claude plugin marketplace add "$REPO_DIR" >/dev/null 2>&1 && ok "marketplace '$MKT' registered" || warn "marketplace add failed — in Claude Code:  /plugin marketplace add $REPO_DIR"
else say "   manual (in Claude Code):  /plugin marketplace add $REPO_DIR"; fi

for p in ultradeep market-scout llm-council adhd job-application-helper agentic-config; do
  if ask "  Install '${B}$p${X}'?" Y; then
    if plugin_has "$p"; then ok "$p already installed"
    elif [ "$DRY" = 1 ]; then drynote "claude plugin install $p@$MKT -s user"
    elif [ "$HAVE_CLAUDE" = 1 ]; then claude plugin install "$p@$MKT" -s user >/dev/null 2>&1 && ok "$p installed" || warn "auto-install failed — in Claude Code:  /plugin install $p@$MKT"
    else say "   manual:  /plugin install $p@$MKT"; fi
  fi
done

# ultradeep self-tunes a program.md at a writable user path — seed it.
if [ -f "$REPO_DIR/plugins/ultradeep/deep-research/program.md" ]; then
  if [ -f "$PROGRAM_DST" ]; then ok "program.md already at $PROGRAM_DST (kept)"
  elif [ "$DRY" = 1 ]; then drynote "cp program.md -> $PROGRAM_DST"
  else mkdir -p "$(dirname "$PROGRAM_DST")" && cp "$REPO_DIR/plugins/ultradeep/deep-research/program.md" "$PROGRAM_DST" && ok "seeded ultradeep config -> $PROGRAM_DST (edit it to tune)"; fi
fi

# ---- 2. REQUIRED MCP servers --------------------------------------------
hdr "Required MCP servers  (Exa public · agentmemory · Context7 — free, no keys)"
mcp_http  exa "https://mcp.exa.ai/mcp"
mcp_stdio agentmemory -- npx -y @agentmemory/agentmemory
mcp_http  context7 "https://mcp.context7.com/mcp"

# ---- 3. OPTIONAL MCP servers --------------------------------------------
hdr "Optional MCP servers"
if ask "  Add ${B}SearXNG${X} (unlimited self-hosted meta-search; needs Docker)?" N; then
  if have docker; then
    if [ "$DRY" = 1 ]; then drynote "docker run -d --name searxng -p 8888:8080 searxng/searxng (+ json format)"; drynote "claude mcp add --scope user searxng -e SEARXNG_URL=http://localhost:8888 -- npx -y mcp-searxng"
    else
      if ! docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx searxng; then
        ask "    Start a SearXNG Docker container on :8888 now?" Y && {
          docker run -d --name searxng -p 8888:8080 \
            -e "SEARXNG_SETTINGS__server__limiter=false" \
            -e "SEARXNG_SETTINGS__search__formats=[\"html\",\"json\"]" \
            searxng/searxng >/dev/null 2>&1 && ok "SearXNG started on :8888" || warn "couldn't start — see github.com/searxng/searxng-docker"; }
      else ok "SearXNG container exists"; fi
      if mcp_has searxng; then ok "MCP 'searxng' already configured"; else
        claude mcp add --scope user searxng -e SEARXNG_URL=http://localhost:8888 -- npx -y mcp-searxng >/dev/null 2>&1 && ok "MCP 'searxng' added" || warn "add manually: claude mcp add --scope user searxng -e SEARXNG_URL=http://localhost:8888 -- npx -y mcp-searxng"; fi
    fi
  else warn "Docker not found; skipping SearXNG."; fi
fi
if ask "  Add ${B}Jina Reader${X} (URL → clean markdown; free, no key)?" N; then
  mcp_http jina "https://mcp.jina.ai/sse"
  warn "If Jina doesn't connect, verify its current MCP endpoint at https://jina.ai."
fi

# ---- 4. OPTIONAL companion marketplaces (third-party, official sources) --
hdr "Optional companions (from their own official repos)"
if ask "  Add ${B}claude-obsidian${X} wiki engine (ingest/query/save into an Obsidian vault)?" N; then
  url="https://github.com/AgriciDaniel/claude-obsidian.git"
  if [ "$DRY" = 1 ]; then drynote "claude plugin marketplace add $url"
  elif [ "$HAVE_CLAUDE" = 1 ]; then claude plugin marketplace add "$url" >/dev/null 2>&1 && ok "claude-obsidian marketplace added — install its plugins via /plugin" || warn "manual:  /plugin marketplace add $url"
  else say "   manual:  /plugin marketplace add $url"; fi
fi
ask "  Note about ${B}graphify${X} (optional KG for ultradeep Phase 8)?" N && warn "Install graphify per its README; ultradeep works fine without it."

# ---- 5. workspace --------------------------------------------------------
hdr "Workspace (research dir + empty wiki scaffold)"
if [ "$DRY" = 1 ]; then drynote "mkdir -p $RESEARCH_DIR"; drynote "cp -R wiki-scaffold/. $WIKI_DIR/ (if absent)"
else
  mkdir -p "$RESEARCH_DIR" && ok "scratch dir: $RESEARCH_DIR"
  if [ ! -e "$WIKI_DIR/index.md" ]; then
    ask "  Create an EMPTY wiki scaffold at ${B}$WIKI_DIR${X}?" Y && { mkdir -p "$WIKI_DIR"; cp -R "$REPO_DIR/wiki-scaffold/." "$WIKI_DIR/" && ok "wiki scaffold -> $WIKI_DIR"; }
  else ok "wiki exists at $WIKI_DIR (untouched)"; fi
fi

# ---- 6. recommended settings --------------------------------------------
hdr "Recommended settings (optional, manual merge)"
say "Safety denylist + workflow flags (no secrets, no bypassPermissions):"
say "  ${C}$REPO_DIR/plugins/agentic-config/recommended-settings.json${X}  →  merge into ${C}~/.claude/settings.json${X}"

# ---- 7. done -------------------------------------------------------------
hdr "Done"
[ "$DRY" = 1 ] && { say "Dry run complete — re-run without --dry-run to apply."; exit 0; }
ok "Restart Claude Code (or run /plugin) to load everything."
say ""
say "Try:  ${B}/ultradeep${X} <question>  ·  ${B}/market-scout${X} best <product>  ·  ${B}/llm-council${X} <decision>  ·  ${B}/adhd${X} <problem>"
say "Cross-tool (Cursor/Codex): ${C}skills-portable/README.md${X}.  Anything skipped? The manual commands above do the same."

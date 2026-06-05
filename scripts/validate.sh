#!/usr/bin/env bash
# Validate the Neovim config WITHOUT opening Neovim interactively.
# Runs four layers of checks and exits non-zero if any fail.
#
#   1. syntax  — every *.lua file parses (luajit)
#   2. load    — `nvim --headless` sources the config with no errors
#   3. types   — lua-language-server semantic check (catches DEPRECATED / outdated APIs)
#   4. format  — stylua formatting matches .stylua.toml
#
# Usage:  scripts/validate.sh            # check everything, report, exit 0/1
#         scripts/validate.sh --fix      # auto-apply stylua formatting, then check
#
# Tools come from Mason (installed via :Mason). No global installs needed.
set -uo pipefail

CFG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MASON="${HOME}/.local/share/nvim/mason/bin"
LUALS="${MASON}/lua-language-server"
STYLUA="${MASON}/stylua"
LOGDIR="$(mktemp -d)"
trap 'rm -rf "$LOGDIR"' EXIT

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
grn()   { printf '\033[32m%s\033[0m\n' "$*"; }
ylw()   { printf '\033[33m%s\033[0m\n' "$*"; }
hdr()   { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

cd "$CFG" || { red "cannot cd to $CFG"; exit 2; }
fail=0

# --- preflight: tools present? ---------------------------------------------
for t in "$LUALS" "$STYLUA"; do
  [ -x "$t" ] || { red "missing tool: $t  (run :Mason and install lua-language-server + stylua)"; exit 2; }
done
command -v luajit >/dev/null 2>&1 || { red "missing: luajit"; exit 2; }

# --- 1. syntax -------------------------------------------------------------
hdr "1/4 syntax (luajit parse)"
syn=0
while IFS= read -r f; do
  if ! err=$(luajit -bl "$f" 2>&1 >/dev/null); then
    red "  syntax error: $f"; printf '    %s\n' "$err"; syn=1
  fi
done < <(find . -name '*.lua' -not -path './.git/*')
[ $syn -eq 0 ] && grn "  all files parse" || fail=1

# --- 2. headless load ------------------------------------------------------
hdr "2/4 load (nvim --headless)"
load_out="$(nvim --headless '+qa' 2>&1)"
if [ -z "$load_out" ]; then
  grn "  config loads with no errors"
else
  red "  errors during startup:"; printf '%s\n' "$load_out" | sed 's/^/    /'; fail=1
fi

# --- 3. types / deprecations ----------------------------------------------
hdr "3/4 types + deprecations (lua-language-server)"
# Prefer a checked-in .luarc.json (user customisation); otherwise generate one
# so the validator is self-contained and survives a fresh clone. The library
# paths are what let luals see neovim's @deprecated annotations = outdated APIs.
if [ -f .luarc.json ]; then
  CFGPATH=".luarc.json"
else
  VIMRT="$(nvim --headless '+lua io.write(vim.env.VIMRUNTIME)' '+qa' 2>/dev/null)"
  CFGPATH="$LOGDIR/luarc.json"
  cat > "$CFGPATH" <<JSON
{
  "runtime.version": "LuaJIT",
  "runtime.path": ["lua/?.lua", "lua/?/init.lua"],
  "workspace.checkThirdParty": false,
  "workspace.library": ["${VIMRT}/lua", "${HOME}/.local/share/nvim/lazy"],
  "diagnostics.globals": ["vim"],
  "diagnostics.disable": ["undefined-doc-name"]
}
JSON
fi
if "$LUALS" --check . --configpath="$CFGPATH" --logpath="$LOGDIR" >"$LOGDIR/out" 2>&1; then
  grn "  no type errors or deprecated APIs"
else
  # luals prints diagnostics to stdout; surface them, strip progress spinner noise
  sed -E 's/\r/\n/g' "$LOGDIR/out" | grep -E 'Warning|Error|\.lua:[0-9]' | sed 's/^/  /' | head -60
  red "  lua-language-server found problems (deprecated API = outdated config — fix these)"
  fail=1
fi

# --- 4. formatting ---------------------------------------------------------
hdr "4/4 format (stylua)"
if [ "${1:-}" = "--fix" ]; then
  "$STYLUA" init.lua lua/ && grn "  formatted in place"
elif "$STYLUA" --check init.lua lua/ >"$LOGDIR/fmt" 2>&1; then
  grn "  formatting matches .stylua.toml"
else
  cat "$LOGDIR/fmt" | sed 's/^/  /' | head -40
  ylw "  formatting drift (run: scripts/validate.sh --fix)"
  fail=1
fi

# --- verdict ---------------------------------------------------------------
echo
if [ $fail -eq 0 ]; then grn "✓ config valid"; else red "✗ config has issues (see above)"; fi
exit $fail

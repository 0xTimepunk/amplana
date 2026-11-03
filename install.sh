#!/bin/bash
set -e

# Installs the Archon Claude Code plugin from this clone, using Claude Code's
# own plugin system. Does not touch your shell rc files.
#
#   ./install.sh                              install Archon only
#   ./install.sh --with-compound-engineering  also install the recommended
#                                             compound-engineering plugin

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WITH_CE=""
for arg in "$@"; do
    case "$arg" in
        --with-compound-engineering) WITH_CE="yes" ;;
        -h|--help) sed -n '4,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo -e "${RED}Unknown option: $arg${NC}"; exit 1 ;;
    esac
done

echo ""
echo "=================================="
echo "  Archon Plugin Installer"
echo "=================================="
echo ""

# Step 1: Check if Claude Code is installed
echo -n "Checking for Claude Code... "
if ! command -v claude &> /dev/null; then
    echo -e "${RED}NOT FOUND${NC}"
    echo ""
    echo "Claude Code is required. Install from:"
    echo "  https://claude.ai/code"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Step 2: Warn about the alias older versions of this script added
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [ -f "$rc" ] && grep -q "alias claude=.*plugin-dir.*archon" "$rc" 2>/dev/null; then
        echo -e "${YELLOW}Note: $rc still has the 'alias claude=... --plugin-dir ...archon' line from an older install.${NC}"
        echo "  It loads a second copy of the plugin. Remove it, or run ./uninstall.sh first."
        echo ""
    fi
done

# Step 3: Register this clone as a marketplace and install the plugin
echo "Adding the Archon marketplace from $SCRIPT_DIR ..."
claude plugin marketplace add "$SCRIPT_DIR"
echo ""
echo "Installing dev@archon ..."
claude plugin install dev@archon
echo -e "${GREEN}Archon installed.${NC}"

# Step 4: compound-engineering (recommended, optional)
if [ -z "$WITH_CE" ] && [ -t 0 ]; then
    echo ""
    echo "Archon works best with the compound-engineering plugin (research and review agents)."
    echo "Without it, Archon uses general-purpose agents for the same roles."
    read -r -p "Install compound-engineering now? [y/N] " reply
    case "$reply" in [yY]*) WITH_CE="yes" ;; esac
fi
if [ -n "$WITH_CE" ]; then
    echo ""
    echo "Installing compound-engineering ..."
    claude plugin install compound-engineering --marketplace EveryInc/compound-engineering-plugin
fi

# Step 5: Summary
echo ""
echo "=================================="
echo "  Installation Complete!"
echo "=================================="
echo ""
echo "Available commands:"
echo "  /dev:spec <feature-name> [brief]  Create feature specification (80% planning)"
echo "  /dev:work <spec-path>             Execute spec with adaptive agent teams (20% execution)"
echo ""
echo "Available skill (auto-triggers):"
echo "  dev:specifier                     Triggers on 'create a spec', 'plan a feature'"
echo ""
echo -e "${YELLOW}Optional setup (see README):${NC}"
echo "  Agent teams for Lean/Full tiers:  set CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"
echo "                                    (otherwise those tiers run as parallel subagents)"
echo "  Linear (--linear, reads and updates issues):"
echo "    claude mcp add --transport http linear https://mcp.linear.app/mcp"
echo "  Figma (--figma, needs a Dev or Full seat):"
echo "    claude mcp add --transport http figma https://mcp.figma.com/mcp"
if [ -z "$WITH_CE" ]; then
    echo "  compound-engineering (recommended):"
    echo "    claude plugin install compound-engineering --marketplace EveryInc/compound-engineering-plugin"
fi
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Start Claude Code in your project: claude"
echo "  2. Run: /dev:spec my-feature"
echo ""
echo "To uninstall, run: ./uninstall.sh"
echo ""

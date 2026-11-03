#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "=================================="
echo "  Amplana Plugin Uninstaller"
echo "=================================="
echo ""

if ! command -v claude &> /dev/null; then
    echo -e "${RED}Claude Code (claude) not found on PATH.${NC}"
    exit 1
fi

# Remove the plugin and the marketplace
echo -n "Uninstalling dev@amplana... "
if claude plugin uninstall dev@amplana > /dev/null 2>&1; then
    echo -e "${GREEN}REMOVED${NC}"
else
    echo -e "${GREEN}NOT INSTALLED${NC}"
fi

echo -n "Removing amplana marketplace... "
if claude plugin marketplace remove amplana > /dev/null 2>&1; then
    echo -e "${GREEN}REMOVED${NC}"
else
    echo -e "${GREEN}NOT FOUND${NC}"
fi

# Remove the install from before the rename to Amplana (dev@archon)
claude plugin uninstall dev@archon > /dev/null 2>&1 && echo "Removed legacy dev@archon."
claude plugin marketplace remove archon > /dev/null 2>&1 && echo "Removed legacy archon marketplace."

# Remove the shell alias that older versions of install.sh added
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [ -f "$rc" ] && grep -q "# Archon Claude Code plugin" "$rc" 2>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/# Archon Claude Code plugin/d' "$rc"
            sed -i '' '/alias claude=.*plugin-dir.*archon/d' "$rc"
        else
            sed -i '/# Archon Claude Code plugin/d' "$rc"
            sed -i '/alias claude=.*plugin-dir.*archon/d' "$rc"
        fi
        echo -e "Removed legacy Archon alias from $rc ${YELLOW}(open a new shell or run: unalias claude)${NC}"
    fi
done

echo ""
echo "=================================="
echo "  Uninstallation Complete!"
echo "=================================="
echo ""
echo "Removed: /dev:brief (and its /dev:spec alias), /dev:work, /dev:security-review and the dev:specifier skill."
echo ""
echo "Not touched:"
echo "  - compound-engineering (remove with: claude plugin uninstall compound-engineering)"
echo "  - Linear/Figma MCP servers you added (remove with: claude mcp remove linear / figma)"
echo "  - specs/ folders in your projects"
echo ""
echo "This script does not delete the plugin files. To remove them, delete this repository."
echo ""

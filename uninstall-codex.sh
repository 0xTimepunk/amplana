#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TARGET_PLUGIN_DIR="$HOME/plugins/amplana-codex"
MARKETPLACE_PATH="$HOME/.agents/plugins/marketplace.json"

echo ""
echo "=================================="
echo "  Amplana Codex Uninstaller"
echo "=================================="
echo ""

echo -n "Removing plugin symlink... "
if [ -L "$TARGET_PLUGIN_DIR" ]; then
    rm "$TARGET_PLUGIN_DIR"
    echo -e "${GREEN}REMOVED${NC}"
elif [ -e "$TARGET_PLUGIN_DIR" ]; then
    echo -e "${YELLOW}SKIPPED${NC}"
    echo "  $TARGET_PLUGIN_DIR exists but is not a symlink."
else
    echo -e "${GREEN}NOT FOUND${NC}"
fi

echo -n "Removing marketplace entry... "
if [ -f "$MARKETPLACE_PATH" ]; then
    python3 - "$MARKETPLACE_PATH" <<'PY'
import json
import sys

marketplace_path = sys.argv[1]

with open(marketplace_path, "r", encoding="utf-8") as f:
    data = json.load(f)

plugins = data.get("plugins", [])
data["plugins"] = [plugin for plugin in plugins if plugin.get("name") not in ("amplana-codex", "archon-codex")]

with open(marketplace_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
    echo -e "${GREEN}UPDATED${NC}"
else
    echo -e "${GREEN}NOT FOUND${NC}"
fi

echo ""
echo "=================================="
echo "  Uninstallation Complete!"
echo "=================================="
echo ""
echo "Removed:"
echo "  - Symlink at $TARGET_PLUGIN_DIR"
echo "  - amplana-codex marketplace entry from $MARKETPLACE_PATH"
echo ""

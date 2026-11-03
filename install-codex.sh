#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PLUGIN_DIR="$SCRIPT_DIR/plugins/amplana-codex"
TARGET_PLUGIN_DIR="$HOME/plugins/amplana-codex"
MARKETPLACE_DIR="$HOME/.agents/plugins"
MARKETPLACE_PATH="$MARKETPLACE_DIR/marketplace.json"

echo ""
echo "=================================="
echo "  Amplana Codex Installer"
echo "=================================="
echo ""

if [ ! -d "$SOURCE_PLUGIN_DIR" ]; then
    echo -e "${RED}Codex plugin source not found:${NC} $SOURCE_PLUGIN_DIR"
    exit 1
fi

echo -n "Checking for Codex home... "
if [ ! -d "$HOME/.codex" ]; then
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo "  Continuing anyway. Install Codex separately if needed."
else
    echo -e "${GREEN}OK${NC}"
fi

echo -n "Creating plugin directories... "
mkdir -p "$HOME/plugins"
mkdir -p "$MARKETPLACE_DIR"
echo -e "${GREEN}OK${NC}"

# Remove the symlink from before the rename to Amplana
if [ -L "$HOME/plugins/archon-codex" ]; then
    rm "$HOME/plugins/archon-codex"
    echo "Removed old ~/plugins/archon-codex symlink (Archon is now Amplana)."
fi

echo -n "Installing plugin symlink... "
if [ -L "$TARGET_PLUGIN_DIR" ]; then
    current_target="$(readlink "$TARGET_PLUGIN_DIR")"
    if [ "$current_target" = "$SOURCE_PLUGIN_DIR" ]; then
        echo -e "${GREEN}ALREADY LINKED${NC}"
    else
        rm "$TARGET_PLUGIN_DIR"
        ln -s "$SOURCE_PLUGIN_DIR" "$TARGET_PLUGIN_DIR"
        echo -e "${GREEN}UPDATED${NC}"
    fi
elif [ -e "$TARGET_PLUGIN_DIR" ]; then
    echo -e "${RED}BLOCKED${NC}"
    echo "  $TARGET_PLUGIN_DIR already exists and is not a symlink."
    echo "  Move it aside or remove it, then rerun this installer."
    exit 1
else
    ln -s "$SOURCE_PLUGIN_DIR" "$TARGET_PLUGIN_DIR"
    echo -e "${GREEN}LINKED${NC}"
fi

echo -n "Updating Codex marketplace... "
python3 - "$MARKETPLACE_PATH" <<'PY'
import json
import os
import sys

marketplace_path = sys.argv[1]
plugin_entry = {
    "name": "amplana-codex",
    "source": {
        "source": "local",
        "path": "./plugins/amplana-codex",
    },
    "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL",
    },
    "category": "Productivity",
}

if os.path.exists(marketplace_path):
    with open(marketplace_path, "r", encoding="utf-8") as f:
        data = json.load(f)
else:
    data = {
        "name": "local-plugins",
        "interface": {
            "displayName": "Local Plugins",
        },
        "plugins": [],
    }

data.setdefault("name", "local-plugins")
data.setdefault("interface", {})
data["interface"].setdefault("displayName", "Local Plugins")
plugins = data.setdefault("plugins", [])

plugins = [plugin for plugin in plugins if plugin.get("name") not in ("amplana-codex", "archon-codex")]
plugins.append(plugin_entry)
data["plugins"] = plugins

with open(marketplace_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
echo -e "${GREEN}UPDATED${NC}"

echo ""
echo "=================================="
echo "  Installation Complete!"
echo "=================================="
echo ""
echo "Installed:"
echo "  - Plugin symlink: $TARGET_PLUGIN_DIR"
echo "  - Marketplace entry: $MARKETPLACE_PATH"
echo ""
echo "Usage examples:"
echo "  Use Amplana to brief user authentication: <the requirements you have decided>."
echo "  Use Amplana to execute specs/user-authentication/technical-spec.md."
echo ""
echo -e "${YELLOW}If Codex is already open, restart it so it reloads local plugins.${NC}"
echo ""

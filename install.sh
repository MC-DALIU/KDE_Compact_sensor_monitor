#!/usr/bin/env bash
#
# Install / update / uninstall the "Compact Monitor" Plasma 6 widget.
#
#   ./install.sh               install (or update) and restart plasmashell
#   ./install.sh --no-restart  install without touching plasmashell
#   ./install.sh --uninstall   remove the widget
#
set -euo pipefail

PLUGIN_ID="org.mcdaliu.compactmonitor"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/$PLUGIN_ID"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "error: kpackagetool6 was not found. Install the KDE Plasma development tools" >&2
    echo "       (the 'kpackage' package on Arch, 'kpackagetool6' elsewhere) first." >&2
    exit 1
fi

if [ ! -d "$PACKAGE_DIR" ]; then
    echo "error: package directory not found: $PACKAGE_DIR" >&2
    exit 1
fi

restart_plasmashell() {
    echo "Restarting plasmashell ..."
    if systemctl --user restart plasma-plasmashell 2>/dev/null; then
        echo "Done. (重新启动 plasmashell 完成)"
        return
    fi
    if command -v kquitapp6 >/dev/null 2>&1 && command -v plasmashell >/dev/null 2>&1; then
        kquitapp6 plasmashell >/dev/null 2>&1 || true
        setsid plasmashell >/dev/null 2>&1 &
        echo "Done. (重新启动 plasmashell 完成)"
        return
    fi
    echo "warning: could not restart plasmashell automatically." >&2
    echo "         请手动执行:  systemctl --user restart plasma-plasmashell" >&2
    echo "         or log out and back in." >&2
}

case "${1:-}" in
    --uninstall)
        kpackagetool6 --type Plasma/Applet --remove "$PLUGIN_ID" >/dev/null 2>&1 || true
        echo "Removed $PLUGIN_ID."
        echo "已卸载；如果面板上还留着图标，右键移除即可。"
        restart_plasmashell
        exit 0
        ;;
    --no-restart)
        DO_RESTART=0
        ;;
    "")
        DO_RESTART=1
        ;;
    *)
        echo "error: unknown argument '$1' (try --no-restart or --uninstall)" >&2
        exit 1
        ;;
esac

# remove first so that no stale file survives an update
kpackagetool6 --type Plasma/Applet --remove "$PLUGIN_ID" >/dev/null 2>&1 || true
kpackagetool6 --type Plasma/Applet --install "$PACKAGE_DIR"

echo
echo "Installed: $PLUGIN_ID"
echo "Add it with: right-click the panel -> \"Add Widgets...\" -> search for \"Compact Monitor\"."
echo "添加方式：面板右键 ->「添加部件…」-> 搜索「紧凑监视器」。"

# plasmashell caches a widget's QML per plugin id, so a restart is required after
# installing or updating the package.
if [ "$DO_RESTART" = "1" ]; then
    restart_plasmashell
else
    echo
    echo "Remember to restart plasmashell before using it:"
    echo "  systemctl --user restart plasma-plasmashell"
fi

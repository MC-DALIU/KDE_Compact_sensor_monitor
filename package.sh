#!/usr/bin/env bash
#
# Build the distributable package file: the one to attach to a GitHub release
# and to upload to store.kde.org.
#
#   ./package.sh [output.plasmoid]
#
set -euo pipefail

PLUGIN_ID="org.mcdaliu.compactmonitor"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/$PLUGIN_ID"
OUTPUT="${1:-$SCRIPT_DIR/compact-monitor.plasmoid}"

if [ ! -d "$PACKAGE_DIR" ]; then
    echo "error: package directory not found: $PACKAGE_DIR" >&2
    exit 1
fi

# A .plasmoid is a zip archive whose *root* contains metadata.json and contents/.
# That is what KPackage (kpackagetool6) and the panel's "Install Widget From
# Local File..." dialog expect - they cannot install this repository's directory
# layout directly. The `zip` program is not installed everywhere, python3 is.
python3 - "$PACKAGE_DIR" "$OUTPUT" <<'PY'
import os
import sys
import zipfile

package_dir, output = sys.argv[1], sys.argv[2]

if os.path.exists(output):
    os.remove(output)

with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
    for root, dirs, files in os.walk(package_dir):
        dirs.sort()
        for name in sorted(files):
            path = os.path.join(root, name)
            archive.write(path, os.path.relpath(path, package_dir))

print("Built " + output + " containing:")
with zipfile.ZipFile(output) as archive:
    for name in archive.namelist():
        print("  " + name)
PY

echo
echo "Install it with:"
echo "  kpackagetool6 --type Plasma/Applet --install \"$OUTPUT\""
echo "or right-click the panel -> Add Widgets... -> Install Widget From Local File..."

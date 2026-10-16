#!/bin/bash
#
# SPDX-FileCopyrightText: 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Writes the update list for LineageOS's Updater app (lineage.updater.uri in device.mk) for a
# signed OTA zip that is published as a GitHub release asset.
#
# Usage: device/unihertz/jellystar/make-updater-json.sh <signed ota zip> [<release tag>]
#   The tag defaults to the build date from the file name (e.g. 20261012).
#   GITHUB_REPO overrides the repository (default osquera/lineageos_unihertz_jellystar).
# Output: updates.json in this repository. Commit and push it after uploading the
# zip to the release; the Updater fetches it from raw.githubusercontent.com.

set -euo pipefail

ZIP=${1:?usage: $0 <signed ota zip> [<release tag>]}
FILENAME=$(basename "$ZIP")
TAG=${2:-$(echo "$FILENAME" | sed -n 's/^lineage-[^-]*-\([0-9]\{8\}\)-.*/\1/p')}
[ -n "$TAG" ] || { echo "Cannot derive a release tag from $FILENAME, pass one" >&2; exit 1; }
REPO=${GITHUB_REPO:-osquera/lineageos_unihertz_jellystar}
OUT=$(dirname "$(readlink -f "$0")")/updates.json

unzip -p "$ZIP" META-INF/com/android/metadata | python3 -c '
import json, sys

zip_path, filename, url, sha256, size, out = sys.argv[1:]
meta = dict(line.split("=", 1) for line in sys.stdin.read().splitlines() if "=" in line)
if meta.get("pre-device") != "jellystar" or meta.get("ota-type") != "AB":
    sys.exit("Not a jellystar A/B OTA package")

# lineage-<version>-<date>-<type>-<device>-signed.zip
version, release_type = filename.split("-")[1], filename.split("-")[3]
update = {
    "datetime": int(meta["post-timestamp"]),
    "type": release_type,
    "version": version,
    "files": [{
        "filename": filename,
        "url": url,
        "sha256": sha256,
        "size": int(size),
        "os_patch_level": meta.get("post-security-patch-level"),
        "os_sdk_level": int(meta["post-sdk-level"]),
        "ota_property_files": meta["ota-property-files"].strip(),
    }],
}
with open(out, "w") as f:
    json.dump([update], f, indent=2)
    f.write("\n")
' "$ZIP" "$FILENAME" "https://github.com/$REPO/releases/download/$TAG/$FILENAME" \
    "$(sha256sum "$ZIP" | cut -d' ' -f1)" "$(stat -c %s "$ZIP")" "$OUT"

echo "Wrote $OUT for release $TAG"

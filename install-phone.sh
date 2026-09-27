#!/bin/bash
# iPhone 実機へ入れる（Watch アプリと文字盤の拡張も同梱。Watch へは Mac から直接入らないので、これで届ける。4-151・4-181）
set -eo pipefail
cd "$(dirname "$0")"
LINE=$(xcrun devicectl list devices 2>/dev/null | grep '(iPhone' | grep -vi 'unavailable' | head -1 || true)
[ -z "$LINE" ] && { echo "❌ iPhone が見えません（同じ Wi-Fi に置いてロックを解除してください）"; exit 1; }
DEV=$(echo "$LINE" | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
xcrun devicectl device info details --device "$DEV" --timeout 60 >/dev/null 2>&1 || true   # 話しかけて起こす（4-85）

# 実機に入る版の印。手で増やさない（4-145）
STAMP="b$(git rev-list --count HEAD 2>/dev/null || echo 0)$(git diff --quiet HEAD -- . 2>/dev/null || echo +) $(date '+%m/%d %H:%M')"
echo "→ 印: $STAMP"
xcodegen generate >/dev/null
xcodebuild -project DuoSlot.xcodeproj -scheme DuoSlot -configuration Debug \
  -destination "platform=iOS,id=$DEV" -destination-timeout 60 -derivedDataPath /tmp/sp-phone-device \
  SP_BUILD_STAMP="$STAMP" -allowProvisioningUpdates build 2>&1 | grep -E "error:|BUILD SUCCEEDED" | tee /tmp/sp-build.log
grep -q "BUILD SUCCEEDED" /tmp/sp-build.log || { echo "❌ ビルドが通っていないので入れません"; exit 1; }

APP=/tmp/sp-phone-device/Build/Products/Debug-iphoneos/DuoSlot.app
W=$(ls -d "$APP"/Watch/*.app)
echo "→ 同梱の Watch アプリの印: $(/usr/libexec/PlistBuddy -c 'Print SPBuildStamp' "$W/Info.plist")"
ls "$W/PlugIns"
xcrun devicectl device install app --device "$DEV" "$APP" 2>&1 | grep -E "bundleID|rror"
echo "   Watch アプリのいちばん下に「$STAMP」が出ていれば入れ替わっています"

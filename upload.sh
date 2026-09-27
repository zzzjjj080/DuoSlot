#!/bin/bash
# アーカイブを作って App Store Connect へ上げる。  ./upload.sh <ビルド番号>
# iOS アプリ（Watch アプリ同梱）としてアーカイブする（watchOS 単体では出せない。引き継ぎ書 4-91）。
set -eo pipefail
cd "$(dirname "$0")"
BUILD="${1:?ビルド番号を渡す（前より大きい数。同じ番号は上げ直せない）}"
security unlock-keychain -p intervaltimer ~/Library/Keychains/interval-dist.keychain-db 2>/dev/null || true
xcodegen generate >/dev/null

DIR=~/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)
mkdir -p "$DIR"; rm -rf "$DIR/DuoSlot.xcarchive"
echo "→ アーカイブ（ビルド $BUILD）"
xcodebuild -project DuoSlot.xcodeproj -scheme DuoSlot -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$DIR/DuoSlot.xcarchive" CURRENT_PROJECT_VERSION="$BUILD" -allowProvisioningUpdates archive 2>&1 \
  | grep -E "error:|ARCHIVE SUCCEEDED|ARCHIVE FAILED"

A="$DIR/DuoSlot.xcarchive/Products/Applications/DuoSlot.app"
W="$A/Watch/DuoSlot Watch App.app"
echo "→ 上げる前の点検"
echo "   版 $(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$A/Info.plist") ($(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$A/Info.plist"))・Watch ($(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$W/Info.plist"))"
printf "   拡張: "; ls "$W/PlugIns"
printf "   App Group・HealthKit: "; codesign -d --entitlements :- "$W" 2>/dev/null | grep -cE "group.com.zzzjjj080.DuoSlot|healthkit"
printf "   撮影モードの入口（0 であること）: "; strings "$W/DuoSlot Watch App" | grep -cE "DS_SHOT|DS_TIP_SAMPLE" || true
printf "   .storekit（0 であること）: "; find "$A" -name "*.storekit" | wc -l

if [ "${2:-}" = "--archive-only" ]; then echo "✅ アーカイブまで"; exit 0; fi
echo "→ 書き出してアップロード（App Store Connect の API キー）"
xcodebuild -exportArchive -archivePath "$DIR/DuoSlot.xcarchive" -exportOptionsPlist ExportOptions.plist \
  -exportPath "$DIR/DuoSlot-export" -allowProvisioningUpdates \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_CH8R5RJGXQ.p8 \
  -authenticationKeyID CH8R5RJGXQ -authenticationKeyIssuerID cfeb84ca-47e6-45b2-8c5f-192212240b6c \
  2>&1 | grep -E "error:|EXPORT SUCCEEDED|EXPORT FAILED|Upload"
echo "✅ 上げた。App Store Connect で処理が終わるのを待つ（10分ほど）"

#!/usr/bin/env python3
"""審査の連絡先とメモ（英日）。連絡先はワンタップタイマーの版から写す。
審査環境で挙動が変わる点（文字盤に置かないと本領が見えない・許可を断ると「No access」）を書く（引き継ぎ書 6節）。"""
import json, subprocess, sys
from pathlib import Path
HERE = Path(__file__).resolve().parent.parent
def asc(method, path, body=None):
    args = [str(HERE / "Tools-ASC.py"), method, path] + ([json.dumps(body, ensure_ascii=False)] if body else [])
    r = subprocess.run(args, capture_output=True, text=True)
    head = r.stdout.split("\n", 1)[0]
    print(method, path.split("?")[0], head)
    if not head.startswith("HTTP 2"): print(r.stdout[:1500]); sys.exit(1)
    return json.loads(r.stdout.split("\n", 1)[1] or "{}")

VER = "d34f7515-9c5c-4c82-8e89-fa3e6721ed67"
src_ver = asc("get", "/v1/apps/6811255797/appStoreVersions?limit=1")["data"][0]["id"]
c = asc("get", f"/v1/appStoreVersions/{src_ver}/appStoreReviewDetail")["data"]["attributes"]
NOTES = """[English]
Duo Slot is an Apple Watch app. Its main feature is a watch-face complication (accessoryRectangular) that shows two items side by side: any two of Battery, Steps and Next Event. The iPhone app only explains how to set it up.

How to review:
1. Install on an iPhone paired with an Apple Watch. Open "Duo Slot" on the Apple Watch once and allow Health (steps), Motion and Calendar access.
2. On the Apple Watch, touch and hold the watch face > Edit > swipe to the complications screen > tap the large rectangle (e.g. on the Modular, Modular Duo, Modular Ultra or Infograph Modular face) > choose Duo Slot > pick a pair such as "Steps | Battery". All six ordered pairs are listed.
3. Tap the left half of the complication: the watch app opens that item's screen. Tap the right half: the other item's screen opens.

Notes:
- If a permission is declined, that half shows "No access" (calendar) or "--" (steps). Nothing else changes.
- Next Event shows the current event or the next timed event within 36 hours; all-day events are not shown. With no events it shows "No events".
- No account, no server, no in-app purchases. The app does not connect to the internet; all data is read on the device and never leaves it.

[日本語]
Apple Watch のアプリです。主な機能は文字盤のコンプリケーション（大きい四角）で、電池・歩数・次の予定から2つを左右に並べて出します。iPhone のアプリは置き方の説明だけです。
確認手順：Watch で Duo Slot を一度開いて許可 → 文字盤を長押し →「編集」→ 大きい四角 → Duo Slot →「歩数 | 電池」などを選ぶ → 左半分・右半分を押すと、それぞれの画面が開きます。
許可を断った項目は「許可なし」「--」と出るだけです。課金はありません。通信はせず、情報は端末の外へ出ません。"""
print("メモの字数", len(NOTES))
assert len(NOTES) <= 4000
attrs = {"contactFirstName": c["contactFirstName"], "contactLastName": c["contactLastName"],
         "contactEmail": c["contactEmail"], "contactPhone": c["contactPhone"],
         "demoAccountRequired": False, "notes": NOTES}
cur = asc("get", f"/v1/appStoreVersions/{VER}/appStoreReviewDetail")
if cur.get("data"):
    rid = cur["data"]["id"]
    asc("patch", f"/v1/appStoreReviewDetails/{rid}", {"data": {"type": "appStoreReviewDetails", "id": rid, "attributes": attrs}})
else:
    asc("post", "/v1/appStoreReviewDetails", {"data": {"type": "appStoreReviewDetails", "attributes": attrs,
        "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": VER}}}}})

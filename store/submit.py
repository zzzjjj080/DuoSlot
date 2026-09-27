#!/usr/bin/env python3
"""ビルドを版に紐づけ、アプリの版と投げ銭（初回の課金）を同じ提出枠で審査に出す（引き継ぎ書 4章の reviewSubmissionItems）。
    python3 store/submit.py <ビルド番号> [--check]"""
import json, subprocess, sys
from pathlib import Path
HERE = Path(__file__).resolve().parent.parent
def asc(method, path, body=None, ok=False):
    args = [str(HERE / "Tools-ASC.py"), method, path] + ([json.dumps(body, ensure_ascii=False)] if body else [])
    r = subprocess.run(args, capture_output=True, text=True)
    head = r.stdout.split("\n", 1)[0]
    print(method, path.split("?")[0], head)
    if not head.startswith("HTTP 2"):
        print(r.stdout[:2000])
        if not ok: sys.exit(1)
        return None
    return json.loads(r.stdout.split("\n", 1)[1] or "{}")

APP, VER, IAP = "6816655833", "d34f7515-9c5c-4c82-8e89-fa3e6721ed67", "6816657739"
BUILD = sys.argv[1]
CHECK = "--check" in sys.argv
b = asc("get", f"/v1/builds?filter[app]={APP}&filter[version]={BUILD}&limit=5")["data"]
if not b or b[0]["attributes"]["processingState"] != "VALID":
    sys.exit(f"ビルド {BUILD} はまだ VALID ではない: {b[0]['attributes']['processingState'] if b else '届いていない'}")
asc("patch", f"/v1/appStoreVersions/{VER}/relationships/build", {"data": {"type": "builds", "id": b[0]["id"]}})
print("ビルドを紐づけた", BUILD)
print("課金の状態", asc("get", f"/v2/inAppPurchases/{IAP}")["data"]["attributes"]["state"])
if CHECK:
    sys.exit(0)
# 前に止まったときの空の提出枠は消せないので使い回す（引き継ぎ書 4章）
open_subs = asc("get", f"/v1/reviewSubmissions?filter[app]={APP}&filter[state]=READY_FOR_REVIEW")["data"]
sub = open_subs[0] if open_subs else asc("post", "/v1/reviewSubmissions", {"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
      "relationships": {"app": {"data": {"type": "apps", "id": APP}}}}})["data"]
asc("post", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems", "relationships": {
    "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub["id"]}},
    "appStoreVersion": {"data": {"type": "appStoreVersions", "id": VER}}}}}, ok=True)
iv = asc("get", f"/v2/inAppPurchases/{IAP}/versions", ok=True)
if iv and iv.get("data"):
    asc("post", "/v1/reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems", "relationships": {
        "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub["id"]}},
        "inAppPurchaseVersion": {"data": {"type": "inAppPurchaseVersions", "id": iv["data"][0]["id"]}}}}}, ok=True)
asc("patch", f"/v1/reviewSubmissions/{sub['id']}", {"data": {"type": "reviewSubmissions", "id": sub["id"], "attributes": {"submitted": True}}})
print("提出した", sub["id"])

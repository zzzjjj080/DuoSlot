#!/usr/bin/env python3
"""年齢制限・価格（無料）・配信地域（全地域）・カテゴリ・コンテンツ権利・著作権。引き継ぎ書 4-81 の手順。
何度走らせてもよい（作り済みのものは 409 で止まるだけ）。"""
import json, subprocess, sys
from pathlib import Path
HERE = Path(__file__).resolve().parent.parent
def asc(method, path, body=None, ok_conflict=False):
    args = [str(HERE / "Tools-ASC.py"), method, path] + ([json.dumps(body, ensure_ascii=False)] if body else [])
    r = subprocess.run(args, capture_output=True, text=True)
    head = r.stdout.split("\n", 1)[0]
    print(method, path.split("?")[0], head)
    if not head.startswith("HTTP 2"):
        print(r.stdout[:800])
        if not ok_conflict: sys.exit(1)
        return None
    return json.loads(r.stdout.split("\n", 1)[1] or "{}")

APP = "6816655833"
INFO = "91bc8dee-4bed-408d-acbc-0ef9f22aea68"
VERSION = "d34f7515-9c5c-4c82-8e89-fa3e6721ed67"

none = {k: "NONE" for k in ["alcoholTobaccoOrDrugUseOrReferences", "contests", "gamblingSimulated",
        "horrorOrFearThemes", "matureOrSuggestiveThemes", "medicalOrTreatmentInformation",
        "profanityOrCrudeHumor", "sexualContentGraphicAndNudity", "sexualContentOrNudity",
        "violenceCartoonOrFantasy", "violenceRealistic", "violenceRealisticProlongedGraphicOrSadistic",
        "gunsOrOtherWeapons"]}
attrs = dict(none, gambling=False, unrestrictedWebAccess=False, healthOrWellnessTopics=False,
             messagingAndChat=False, userGeneratedContent=False, advertising=False,
             parentalControls=False, ageAssurance=False, lootBox=False)
asc("patch", f"/v1/ageRatingDeclarations/{INFO}", {"data": {"type": "ageRatingDeclarations", "id": INFO, "attributes": attrs}})

# カテゴリ：ユーティリティだけ。副に「ヘルスケア／フィットネス」を入れると医療機器の申告を求められる（4-130）
asc("patch", f"/v1/appInfos/{INFO}", {"data": {"type": "appInfos", "id": INFO, "relationships": {
    "primaryCategory": {"data": {"type": "appCategories", "id": "UTILITIES"}},
    "secondaryCategory": {"data": None}}}})

# 外部のコンテンツは使わない（未設定だと版を審査の箱に入れられない。4-171）
asc("patch", f"/v1/apps/{APP}", {"data": {"type": "apps", "id": APP,
    "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}}})

# 著作権・自動公開
asc("patch", f"/v1/appStoreVersions/{VERSION}", {"data": {"type": "appStoreVersions", "id": VERSION,
    "attributes": {"copyright": "2026 Jin Nakamura", "releaseType": "AFTER_APPROVAL"}}})

# 価格：無料
pp = asc("get", f"/v1/apps/{APP}/appPricePoints?filter[territory]=JPN&limit=200")
free = next(p["id"] for p in pp["data"] if float(p["attributes"]["customerPrice"]) == 0)
asc("post", "/v1/appPriceSchedules", {
    "data": {"type": "appPriceSchedules", "relationships": {
        "app": {"data": {"type": "apps", "id": APP}},
        "baseTerritory": {"data": {"type": "territories", "id": "JPN"}},
        "manualPrices": {"data": [{"type": "appPrices", "id": "${p0}"}]}}},
    "included": [{"type": "appPrices", "id": "${p0}", "attributes": {"startDate": None},
                  "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": free}}}}]}, ok_conflict=True)

# 配信地域：全地域（どの地名にも縛られない）
terr = asc("get", "/v1/territories?limit=200")["data"]
inc = [{"type": "territoryAvailabilities", "id": f"${{t{i}}}",
        "attributes": {"available": True, "releaseDate": None, "preOrderEnabled": False},
        "relationships": {"territory": {"data": {"type": "territories", "id": t["id"]}}}}
       for i, t in enumerate(terr)]
asc("post", "/v2/appAvailabilities", {
    "data": {"type": "appAvailabilities", "attributes": {"availableInNewTerritories": True},
             "relationships": {"app": {"data": {"type": "apps", "id": APP}},
                               "territoryAvailabilities": {"data": [{"type": "territoryAvailabilities", "id": x["id"]} for x in inc]}}},
    "included": inc}, ok_conflict=True)
print("地域の数", len(terr))

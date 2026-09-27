#!/usr/bin/env python3
"""`translations.json` から文字列カタログを作り直す。訳を直すのは translations.json だけ。

    Shared/Localizable.xcstrings    Watch アプリと文字盤の枠（Shared は両方に入る）
    Phone/Localizable.xcstrings     iPhone の器
    WatchApp/InfoPlist.xcstrings    許可を求めるときの説明
    Widget/InfoPlist.xcstrings      同上（拡張も自分で読むので要る）

キーは日本語のまま。**原語は en**（開発地域も en。ずれると片方の言語が壊れる。引き継ぎ書 4-177）
なので、ja も含めて全言語を訳として明示する。
"""
import collections, json
from pathlib import Path

ROOT = Path(__file__).parent
T = json.load(open(ROOT / "translations.json", encoding="utf-8"))
LANGS = T["languages"]

def catalog(table):
    strings = collections.OrderedDict()
    for key, values in table.items():
        assert len(values) == len(LANGS), f"{key}: 訳が {len(values)} 個（{len(LANGS)} 個いる）"
        strings[key] = {"extractionState": "manual", "localizations": collections.OrderedDict(
            (l, {"stringUnit": {"state": "translated", "value": v}}) for l, v in zip(LANGS, values))}
    return {"sourceLanguage": "en", "strings": strings, "version": "1.0"}

def write(path, table):
    p = ROOT / path
    p.write_text(json.dumps(catalog(table), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("→", path, len(table))

write("Shared/Localizable.xcstrings", T["strings"])
write("Phone/Localizable.xcstrings", T["strings"])
write("WatchApp/InfoPlist.xcstrings", T["infoplist"])
write("Widget/InfoPlist.xcstrings", T["infoplist"])

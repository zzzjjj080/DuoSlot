# DuoSlot（仮の名前）

Apple Watch の文字盤の大きい四角（accessoryRectangular）の**左右に、別々のものを2つ同時に出す**アプリ。
左右は押し分けられ、押した側の画面が Watch アプリで開く（試作で確かめた。引き継ぎ書 4-193）。

- 出せるもの：電池・歩数・次の予定（1版目）。天気は WeatherKit が要るので2版目以降
- 組み合わせは文字盤の編集画面で選ぶ（`recommendations()` に6通り。引き継ぎ書 4-194）
- 歩数は StepNow と同じ式（ヘルスケアの合計＋その後の歩数計。4-168）
- 次の予定は、進行中→次に始まるもの。終日は出さない。36時間先まで
- **無料。App内課金なし・通信しない**（1.1 で投げ銭を廃止。2026-09-30 本人判断：副業禁止のため収入の入り口を無くす）。
  投げ銭があった iPhone の画面の下には「作者の他のアプリ」への1行のリンク。Watch 側の入口は外しただけ（Watch で App Store のページを開いても読めないため）
- 競合の Watchsmith は「1つの枠を時間帯で入れ替える」もので、「1つの枠に2つ同時」ではない

## 構成
- `DuoCore/` … UI抜きの計算（`swift test`）
- `Shared/` … 読み取り（電池・歩数・予定）と左右の見た目。Watch アプリと拡張の両方に入る
- `Widget/` … 文字盤の枠、`WatchApp/` … Watch アプリ、`Phone/` … 配信の器
- プロジェクトは XcodeGen（`project.yml`）。`.xcodeproj` はスクリプトが毎回作る

## 次の版（1.1）の出し方
変更はブランチ `v1.1` にある。**サポートページは main の `docs/` から公開される**ので、1.1 を出すときに main へまとめる
（先に main へ入れると、配信中の 1.0 と説明が食い違う）。

1. `store/review.py` と `Tools-PushListing.py` の版 ID を 1.1 のものにする（API で `appStoreVersions` を作る）
2. `./upload.sh <番号>` → `./Tools-PushListing.py <版ID>`（「新機能」は `store/listing.json` の `whatsNew` に足す）→ `store/review.py`
3. `python3 store/submit.py <番号> <版ID>`（課金は含めない）
4. `git checkout main && git merge v1.1 && git push`（サポートページが「通信しません」に切り替わる）

## 入れ方
`./install-phone.sh`（iPhone に入れると Watch へも届く。Mac から Watch へは直接入らない。4-181）

## 試作の記録
押し分けの試作（Link×2・ボタン×2・トグル×2・全体で1つ）は最初のコミットにある。
Link と `Button(intent:)` は文字盤の上で効いた。`Toggle` は見た目だけ変わって状態が付いてこなかった。

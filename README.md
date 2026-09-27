# DuoSlot（仮の名前）

Apple Watch の文字盤の大きい四角（accessoryRectangular）の**左右に、別々のものを2つ同時に出す**アプリ。
左右は押し分けられ、押した側の画面が Watch アプリで開く（試作で確かめた。引き継ぎ書 4-193）。

- 出せるもの：電池・歩数・次の予定（1版目）。天気は WeatherKit が要るので2版目以降
- 組み合わせは文字盤の編集画面で選ぶ（`recommendations()` に6通り。引き継ぎ書 4-194）
- 歩数は StepNow と同じ式（ヘルスケアの合計＋その後の歩数計。4-168）
- 次の予定は、進行中→次に始まるもの。終日は出さない。36時間先まで
- 競合の Watchsmith は「1つの枠を時間帯で入れ替える」もので、「1つの枠に2つ同時」ではない

## 構成
- `DuoCore/` … UI抜きの計算（`swift test`）
- `Shared/` … 読み取り（電池・歩数・予定）と左右の見た目。Watch アプリと拡張の両方に入る
- `Widget/` … 文字盤の枠、`WatchApp/` … Watch アプリ、`Phone/` … 配信の器
- プロジェクトは XcodeGen（`project.yml`）。`.xcodeproj` はスクリプトが毎回作る

## 入れ方
`./install-phone.sh`（iPhone に入れると Watch へも届く。Mac から Watch へは直接入らない。4-181）

## 試作の記録
押し分けの試作（Link×2・ボタン×2・トグル×2・全体で1つ）は最初のコミットにある。
Link と `Button(intent:)` は文字盤の上で効いた。`Toggle` は見た目だけ変わって状態が付いてこなかった。

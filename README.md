# SplitProto（試作・仮の名前）

Apple Watch の文字盤の大きい四角（accessoryRectangular）で、**左半分と右半分を押し分けられるか**を確かめるだけの試作。

| 枠 | 仕組み | 効いたときの様子 |
|---|---|---|
| ① Link×2 | `Link` で左右に別の URL | アプリが開き、上に `link/left` か `link/right` |
| ② ボタン×2 | `Button(intent:)` | アプリは開かず、押した側の数字が増える |
| ③ トグル×2 | `Toggle(isOn:intent:)` | アプリは開かず、押した側が ON/off に変わる |
| ④ 全体で1つ | `widgetURL`（基準） | アプリが開き、上に `whole` |

押した結果は Watch アプリの画面に新しい順で残る（`URL: …` か `Intent …`）。

- 入れ方：`./install-phone.sh`（iPhone に入れると Watch へも届く。Mac から Watch へは直接入らない。引き継ぎ書 4-181）
- プロジェクトは XcodeGen（`project.yml`）。`.xcodeproj` はスクリプトが毎回作る

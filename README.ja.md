<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/diagrams/hero-dark.svg">
  <img src="assets/diagrams/hero-light.svg" alt="TrueRespi — マウス呼吸波形の行動アノテーション・解析システム" width="100%">
</picture>

<br>

[![Latest release](https://img.shields.io/github/v/release/BuTrue/TrueRespi?display_name=tag&sort=semver&style=flat-square&color=0d9488)](https://github.com/BuTrue/TrueRespi/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/BuTrue/TrueRespi/total?style=flat-square&color=5bb8f9)](https://github.com/BuTrue/TrueRespi/releases)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011%20x64-0078d4?style=flat-square)](#動作環境)
[![License](https://img.shields.io/badge/license-MIT-6b7280?style=flat-square)](LICENSE)

[简体中文](README.md) · [English](README.en.md) · **日本語**

</div>

---

## 概要

TrueRespi は、**覚醒マウスの全身プレチスモグラフィ（WBP）**向けのローカルデスクトップツールです。
EMKA などの装置が出力する生の呼吸流量波形を読み込み、行動エピソードを手作業でアノテーションし、
同梱モデルで AI 事前ラベリングを行ったうえで、呼吸ごとのパラメータ・区間統計・グラフを Excel に
まとめて出力します。

> **本リポジトリは Windows ビルドと更新マニフェストのみを配布します。ソースコードは含みません。**
> ソース、テスト、開発ドキュメントは本リポジトリでは公開していません。

<div align="center">
  <img src="assets/screens/main-window-light.png" alt="TrueRespi メインウィンドウ（波形・アノテーション・指標レーン）" width="100%">
  <sub>メインウィンドウ（ライト）— 実際の EMKA 10 分記録。アノテーション区間は呼吸検出結果から生成</sub>
</div>

---

## ダウンロードとインストール

| エディション | ファイル | 用途 |
|---|---|---|
| **インストーラ**（推奨） | `TrueRespi-<バージョン>-Setup.exe` | スタートメニュー/デスクトップのショートカット、アプリ内アップデート |
| **ポータブル** | `TrueRespi-<バージョン>-win64-portable.zip` | 解凍して実行。インストール権限が不要 |
| チェックサム | `SHA256SUMS.txt` | ダウンロードの検証用 |

👉 **[最新リリースを取得](https://github.com/BuTrue/TrueRespi/releases/latest)**

### 動作環境

| 項目 | 要件 |
|---|---|
| OS | Windows 10 / 11（64 ビット） |
| メモリ | 4 GB 以上（数時間の記録を扱う場合は 8 GB 以上を推奨） |
| ディスク | 約 1 GB の空き容量（モデルとランタイムはパッケージに同梱） |
| GPU | 任意。DirectML 対応 GPU があれば推論を高速化し、なければ CPU に自動フォールバック |

### インストール手順

1. `TrueRespi-<バージョン>-Setup.exe` をダウンロードして実行します。
2. ウィザードが管理者権限を要求します。旧バージョンが起動中なら自動的に終了してから置き換えます。
3. スタートメニューまたはデスクトップのショートカットから起動します。

> インストーラは商用コード署名を行っていないため、Windows SmartScreen が「不明な発行元」と
> 警告する場合があります。本リポジトリの Releases から取得したことを確認し、
> `SHA256SUMS.txt` で検証してから実行してください。

**ポータブル版**：書き込み可能な任意のフォルダに解凍し（アーカイブ内から直接実行しないでください）、
`TrueRespi.exe` を起動します。設定は `%APPDATA%\TrueRespi` に保存され、プロジェクトと出力ファイルは
任意の場所に保存できます。

---

## 主な機能

### アノテーションワークベンチ

- **波形閲覧** — 複数チャネルの重ね表示、ズーム・パン、時刻移動、長時間記録向けの GPU 描画。
- **行動アノテーション** — ドラッグで区間を指定、ラベルと色をカスタマイズ、**区間の重複を許可**
  （共同アノテーション）。
- **プロジェクトファイル** — `.truerespi` として保存。旧 `.deeprespi` プロジェクトもそのまま開けます。

### AI 事前ラベリング

**9 つの Pneuma 行動モデル**を同梱し、5 クラス（moving / grooming / sniff / eupnea / sleep）をカバーします。
同じデータで相互比較できます。

| モデル | 構造と位置づけ |
|---|---|
| `condor` **（既定推奨）** | 4 モデルの softmax 確率平均 → HMM。総合精度で最上位 |
| `falcon` | 単一モデルで最優秀。macro-F1 で全体最高・汎化最强、`condor` とは 0.22pp 差 |
| `heron` | 機械学習系で最優秀。103 次元の特徴量のみで使用し生波形を読まないため CPU で最速 |
| `osprey` | Pneuma 主幹 V9 系統のアーキテクチャ。長い上下文で優位 |
| `swift` | より軽量な勾配ブースティングモデル。CPU 向きで、macro-F1 は `heron` よりやや低い |
| `eagle` / `kite` / `raven` / `swan` | 4 つの単一モデルバックボーン（V9 / V95 / InceptWave V70 / S4D-k255）。バックボーン間の比較用 |

推論は ONNX 上で動作し、DirectML GPU を優先、失敗時は CPU にフォールバックします。結果は行動区間として
アノテーション層に反映され、区間ごとに修正できます。

### 呼吸指標

- **呼吸ごとの 15 パラメータ** — `Ti` `Te` `PIF` `PEF` `TV` `EV` `RT` `MV` `P` `f` `EIP` `EEP` `Penh` `EF50` `AUC`
  （emka IOX の定義に準拠）。
- **56 項目の指標レジストリ** — 5 分類（時間 / 振幅 / 変動性 / イベント / 推論）。各項目に定義・計算式・
  単位・最小データ条件を記載。
- **取得できない値は空欄** — 信号がない、データ不足、計算失敗はすべて `NaN` として出力し、`0` で
  埋めることはありません。出力表では「空欄」と「実測 0」を常に区別できます。

<div align="center">
  <img src="assets/screens/pro-workspace.png" alt="解析ワークベンチ（指標レーンと区間トレンド）" width="100%">
  <sub>解析ワークベンチ — 指標レーンと区間トレンドが連動。左側はファイル概要とチャネル指標</sub>
</div>

### Excel 出力

| 出力 | 内容 |
|---|---|
| **行動ワークブック** | Sheet1 の明細、行動別ビン集計（1/3/5/10 分）、30 分区間、トレンドグラフ、指標用語集 |
| **全データワークブック** | 行動ワークブックに「呼吸指標_毎秒」「呼吸指標_毎分」の 2 シートを追加 |

「説明」シートは**実際に出力されたシートだけ**を記述します。ファイルに存在しないシートを記載することは
ありません。

---

## アップデート

- インストーラ版は起動後に更新を確認します。**ヘルプ → アップデートを確認** からも実行できます。
- 新しいバージョンが見つかるとアプリ内でダウンロードし、**SHA-256 を検証**してからインストーラを
  起動します。AppId が固定のため上書きアップグレードとなり、**設定は保持されます**。
- ポータブル版は Releases から新しい zip を取得し、プログラムフォルダを置き換えてください。
  プロジェクトと出力ファイルは影響を受けません。
- マニフェスト：[`update/manifest.json`](update/manifest.json)

---

## ダウンロードの検証

```powershell
Get-FileHash .\TrueRespi-<バージョン>-Setup.exe -Algorithm SHA256
Get-FileHash .\TrueRespi-<バージョン>-win64-portable.zip -Algorithm SHA256
```

[`SHA256SUMS.txt`](SHA256SUMS.txt) と照合してください。一致しない場合は実行せず、再ダウンロードしてください。

---

## データとプライバシー

- **すべてローカルで処理**します。記録、アノテーション、プロジェクトファイルが外部に送信されることは
  ありません。
- アップデーターは本リポジトリのマニフェストとリリース資産にのみアクセスします。
- 問題を報告する際は、共有権限のない動物データ、個人情報、機密パスを含むスクリーンショットを
  添付しないでください。

---

## フィードバック

- 質問・不具合：[GitHub Issues](https://github.com/BuTrue/TrueRespi/issues)
- 変更履歴：[CHANGELOG.md](CHANGELOG.md) · [リリースノート](release-notes/)
- メール：**namecyq@foxmail.com**

報告時には、アプリのバージョン（「バージョン情報」で確認）、Windows のバージョン、データ形式、
再現手順、ログの抜粋（個人情報を除去したもの）をお知らせください。

---

## ライセンス

TrueRespi は **MIT License** で公開されています。詳細は [LICENSE](LICENSE) を参照してください。
サードパーティのライセンスはインストール先の `THIRD_PARTY_LICENSES.txt` に記載されています。

<div align="center"><sub>© 2026 TrueRespi Team · TrueRespi の名称およびブランドに関する権利は留保されます</sub></div>

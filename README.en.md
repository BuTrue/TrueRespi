<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/diagrams/hero-dark.svg">
  <img src="assets/diagrams/hero-light.svg" alt="TrueRespi — mouse respiratory waveform annotation and analysis" width="100%">
</picture>

<br>

[![Latest release](https://img.shields.io/github/v/release/BuTrue/TrueRespi?display_name=tag&sort=semver&style=flat-square&color=0d9488)](https://github.com/BuTrue/TrueRespi/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/BuTrue/TrueRespi/total?style=flat-square&color=5bb8f9)](https://github.com/BuTrue/TrueRespi/releases)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011%20x64-0078d4?style=flat-square)](#requirements)
[![License](https://img.shields.io/badge/license-MIT-6b7280?style=flat-square)](LICENSE)

[简体中文](README.md) · **English** · [日本語](README.ja.md)

</div>

---

## What it is

TrueRespi is a local desktop tool for **awake mouse whole-body plethysmography (WBP)**. It loads raw
respiratory flow traces exported by systems such as EMKA, lets you annotate behavioural episodes by hand,
pre-labels them with bundled models, and exports per-breath parameters, segment statistics and charts to Excel
in one pass.

> **This repository distributes Windows builds and the update manifest only. It contains no source code.**
> Source, tests and development documentation are not published here.

<div align="center">
  <img src="assets/screens/main-window-light.png" alt="TrueRespi main window with waveform, annotations and metric lanes" width="100%">
  <sub>Main window (light) — a real 10-minute EMKA recording; annotation segments are derived from breath detection</sub>
</div>

---

## Download & install

| Edition | File | When to use |
|---|---|---|
| **Installer** (recommended) | `TrueRespi-<version>-Setup.exe` | Start-menu/desktop shortcuts, in-app overwrite upgrades |
| **Portable** | `TrueRespi-<version>-win64-portable.zip` | Unzip and run; no install permission needed |
| Checksums | `SHA256SUMS.txt` | Verify the download |

👉 **[Get the latest release](https://github.com/BuTrue/TrueRespi/releases/latest)**

### Requirements

| Item | Requirement |
|---|---|
| OS | Windows 10 / 11, 64-bit |
| RAM | 4 GB minimum; 8 GB or more for multi-hour recordings |
| Disk | ~1 GB free (models and runtime ship inside the package) |
| GPU | Optional. A DirectML-capable GPU accelerates inference; otherwise it falls back to CPU |

### Install

1. Download `TrueRespi-<version>-Setup.exe` and run it.
2. The wizard requests administrator rights and closes any running copy before replacing files.
3. Launch from the Start menu or the desktop shortcut.

> The installer is not commercially code-signed, so Windows SmartScreen may warn about an unknown publisher.
> Confirm the file came from this repository's Releases and verify it against `SHA256SUMS.txt` before running.

**Portable edition**: unzip into any **writable** folder (do not run from inside the archive) and start
`TrueRespi.exe`. Settings live in `%APPDATA%\TrueRespi`; projects and exports go wherever you choose.

---

## Capabilities

### Annotation workbench

- **Waveform browsing** — multi-channel overlay, zoom/pan, time navigation, GPU-accelerated rendering for long
  recordings.
- **Behaviour annotation** — drag to annotate, custom labels and colours, **overlapping intervals allowed**
  (co-annotation).
- **Project files** — saved as `.truerespi`; legacy `.deeprespi` projects still open directly.

### Model pre-labelling

Nine Pneuma behaviour models ship in the package, covering the five classes (moving / grooming / sniff / eupnea /
sleep) so you can compare them on your own data:

| Model | Architecture and role |
|---|---|
| `condor` **(recommended default)** | Softmax average of four models feeding an HMM; highest overall accuracy |
| `falcon` | Best single model — top macro-F1 and strongest generalisation, only 0.22pp behind `condor` |
| `heron` | Best gradient-boosting model — needs just 103 engineered features and no raw trace, so it is the fastest on CPU |
| `osprey` | Pneuma mainline V9 branch architecture; stands out on long contexts |
| `swift` | Lighter boosting model, CPU-friendly; slightly lower macro-F1 than `heron` |
| `eagle` / `kite` / `raven` / `swan` | Four single-model backbones (V9 / V95 / InceptWave V70 / S4D-k255) for architecture cross-checks |

Inference runs on ONNX with DirectML GPU acceleration and automatic CPU fallback. Results land as behaviour
segments you can revise segment by segment.

### Respiratory metrics

- **23 per-breath output columns** (`Ti` `Te` `P` `f` `PIF` `PEF` `TV` `EV` `MV` `RT` … `IF50`) — the emka IOX
  22-column convention plus derived quantities; 15 core parameters feed the metric lanes and window aggregates.
- **A 56-entry metric registry** across five families (timing / amplitude / variability / events / inference),
  each with a definition, formula, unit and minimum-data condition.
- **Unavailable means blank** — missing signals, insufficient data or failed computations are written as `NaN`,
  never `0`. Blank and a measured zero stay distinguishable in every export.

<div align="center">
  <img src="assets/screens/pro-workspace.png" alt="Analysis workbench with metric lanes and segment trends" width="100%">
  <sub>Analysis workbench — metric lanes and segment trends stay linked; file overview and channel metrics on the left</sub>
</div>

### Excel export

| Export | Contents |
|---|---|
| **Behaviour workbook** | Sheet1 detail, per-behaviour binned statistics (1/3/5/10 min), 30-minute segments, trend charts, metric glossary |
| **All-data workbook** | The behaviour workbook plus `呼吸指标_每秒` (per-second) and `呼吸指标_每分钟` (per-minute) sheets |

The Notes sheet describes only the sheets actually produced — it never lists a sheet the file does not contain.

---

## Updates

- The installer checks for updates shortly after launch; you can also use **Help → Check for updates**.
- When a new version is found it downloads in-app, verifies **SHA-256**, then runs the installer. The fixed
  AppId upgrades in place and **keeps your settings**.
- Portable users download the new zip from Releases and replace the program folder; projects and exports are
  untouched.
- Manifest: [`update/manifest.json`](update/manifest.json).

---

## Verify a download

```powershell
Get-FileHash .\TrueRespi-<version>-Setup.exe -Algorithm SHA256
Get-FileHash .\TrueRespi-<version>-win64-portable.zip -Algorithm SHA256
```

Compare against [`SHA256SUMS.txt`](SHA256SUMS.txt). If they differ, do not run the file — download it again.

---

## Data & privacy

- **Everything runs locally.** Recordings, annotations and project files are never uploaded anywhere.
- The updater only contacts this repository's manifest and release assets.
- When reporting an issue, please omit animal data you are not authorised to share, personal information, or
  screenshots containing sensitive paths.

---

## Feedback

- Questions and issues: [GitHub Issues](https://github.com/BuTrue/TrueRespi/issues)
- Change history: [CHANGELOG.md](CHANGELOG.md) · [release notes](release-notes/)
- Email: **namecyq@foxmail.com**

Please include the app version (visible in About), your Windows version, data format, reproduction steps and a
redacted log excerpt.

---

## License

TrueRespi is released under the **MIT License** — see [LICENSE](LICENSE).
Third-party licences are listed in `THIRD_PARTY_LICENSES.txt` inside the install directory.

<div align="center"><sub>© 2026 TrueRespi Team · All rights reserved for the TrueRespi name and branding</sub></div>

# TrueRespi

**小鼠呼吸波形行为标注分析系统**  
*Mouse Respiratory Waveform Annotation & Analysis System*

[![Latest Release](https://img.shields.io/github/v/release/BuTrue/TrueRespi?display_name=tag&sort=semver)](https://github.com/BuTrue/TrueRespi/releases/latest)

> 本仓库仅用于 **TrueRespi Windows 桌面软件的发布与更新**，不包含源代码。源代码、开发文档与测试不在本仓库分发。

---

## 下载

请前往 [Releases](https://github.com/BuTrue/TrueRespi/releases/latest) 下载最新版本。

| 版本 | 文件 | 适用场景 |
|---|---|---|
| 安装版 | `TrueRespi-<版本>-Setup.exe` | 需要开始菜单/桌面快捷方式、可覆盖升级的常规使用 |
| 免安装版 | `TrueRespi-<版本>-win64-portable.zip` | 解压即用、便携部署或无法安装软件的电脑 |
| 校验文件 | `SHA256SUMS.txt` | 下载后校验文件完整性 |

**系统要求**

- Windows 10 / 11，64 位
- 4 GB 以上内存（处理数小时录音建议 8 GB 以上）
- 约 1 GB 可用磁盘空间（模型与运行库随包分发）
- 可选：支持 DirectML 的显卡（AI 推理自动加速；无显卡时回退 CPU）

---

## 安装与启动

### 安装版

1. 下载并运行 `TrueRespi-<版本>-Setup.exe`。
2. 按安装向导完成安装；安装程序会关闭正在运行的旧版本。
3. 从开始菜单或桌面快捷方式启动。

> 安装包未做商业代码签名，Windows SmartScreen 可能提示“未知发布者”。请确认文件来自本仓库 Releases，并用 `SHA256SUMS.txt` 校验后再运行。

### 免安装版

1. 下载 `TrueRespi-<版本>-win64-portable.zip`。
2. 解压到任意 **可写目录**（请勿在压缩包内直接运行）。
3. 双击目录中的 `TrueRespi.exe` 启动。

免安装版会在 `%APPDATA%\TrueRespi` 保存用户设置；项目文件与导出文件保存在您选择的目录。

---

## 主要功能

- **行为标注**：波形浏览、行为区间标注、共同标注（允许重叠）、项目文件保存与恢复。
- **AI 预标注**：内置 Pneuma 五类呼吸行为模型（moving / grooming / sniff / eupnea / sleep），支持 GPU（DirectML）与 CPU 回退。
- **分析模式**：通道面板、参数通道、呼吸指标泳道、分段趋势与统计。
- **呼吸指标**：逐呼吸 emka IOX 口径参数（Ti/Te/PIF/PEF/TV/EV/MV/f/Penh/EF50 等）。
- **Excel 导出**：
  - 行为标注 Excel：行为分段、分窗统计、图表与指标说明；
  - **全部数据 Excel**：在行为标注工作簿上追加「呼吸指标_每秒」与「呼吸指标_每分钟」。
- **应用内更新**：帮助 → 检查更新；安装版可下载并运行安装程序，免安装版跳转新版压缩包。
- **内置帮助**：快速入门、数据格式、评分指南、批处理与故障排查。

---

## 更新说明

- 软件启动后会延迟检查更新（打包版）；也可随时使用 **帮助 → 检查更新**。
- 安装版：发现新版本后可在应用内下载并通过 SHA-256 校验，随后运行安装程序。
- 免安装版：请从本仓库 Releases 下载新版 zip，解压替换当前程序目录；用户项目与导出文件不受影响。
- 更新清单：`update/manifest.json`（软件自动读取）。

---

## 文件校验

下载后可在 PowerShell 中校验：

```powershell
Get-FileHash .\TrueRespi-<版本>-Setup.exe -Algorithm SHA256
Get-FileHash .\TrueRespi-<版本>-win64-portable.zip -Algorithm SHA256
```

将结果与 `SHA256SUMS.txt` 中的值比对。校验不通过请勿运行，并重新下载。

---

## 数据与隐私

- TrueRespi 在本地处理数据，不上传原始录音、标注或项目文件。
- 应用内更新仅访问本仓库的更新清单与发布资产。
- 反馈问题时请勿附带未授权的动物数据、个人信息或含敏感路径的截图。

---

## 技术支持

- 联系邮箱：**namecyq@foxmail.com**
- 问题反馈：[GitHub Issues](https://github.com/BuTrue/TrueRespi/issues)
- 发布记录：[CHANGELOG.md](CHANGELOG.md)

反馈时请提供：软件版本、Windows 版本、数据格式、复现步骤与日志片段（请先脱敏）。

---

## 许可证

TrueRespi 以 MIT License 发布，详见 [LICENSE](LICENSE)。  
第三方组件许可见安装目录中的 `THIRD_PARTY_LICENSES.txt`。

© 2026 TrueRespi Team. All rights reserved for the TrueRespi name and branding.

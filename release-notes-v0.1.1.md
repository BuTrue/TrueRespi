# TrueRespi 0.1.1

本次更新把 TrueRespi 接入命令行与 Agent 工作流，并保留原有桌面标注、分析与裁剪能力。

## 新增

- **CLI**：安装包新增 `truerespi.exe`，安装时自动加入当前用户 `PATH`。
  - `truerespi list` 递归扫描文件夹，列出录音；`--probe` 附带采样率、时长和开始时间。
  - `truerespi crop` 支持文件夹输入，逐个文件流式裁剪。
  - 每小时 TXT：`truerespi crop "D:\数据" -o "D:\导出" --every 3600 --format txt --recursive --ext mkt`。
  - 支持相对区间 `--range`、绝对时间 `--at`、EDF/H5 输出与并发写出。
- **MCP**：安装包新增 `truerespi-mcp.exe`，可直接接入 Claude Desktop、Codex、OpenCode。
  - 新增 `list_recordings`、`crop_export` 两个工具；原有六个工具保持兼容。
  - 批量导出中单个文件损坏不会中断其他文件，返回 `failed` 与 `warnings`。
- **命令行安装**：`install.ps1` 支持下载、SHA256 校验、静默安装与卸载；安装包支持 `/VERYSILENT`。

## 改进

- 批量导出自动检测同名文件、输出目录等于输入目录等覆盖风险。
- 安装/卸载自动维护用户 `PATH`；覆盖安装保留原目录和 `%APPDATA%\TrueRespi`。
- 同时包含波形 Y 轴左侧五个控制按钮、按通道手动 Y 范围与 p1–p99 稳健拟合。
- 同时包含「编辑 → 配色方案」二级菜单裁切修复。

## 修复

- 修复二级菜单在父级滚动容器中被裁切的问题。
- 修复 Y 轴手动调整后与自动跟随互相抢占的问题。

## 注意

- 安装包未做商业代码签名；SmartScreen 提示时请核对 `SHA256SUMS.txt`。
- TXT 输出体积较大：1 kHz 单通道每小时约 50–70 MB。
- 当前裁剪源支持 MKT / TXT / CSV / LabChart；EDF、NPZ、HDF5 可读取和分析，但不能作为裁剪源。

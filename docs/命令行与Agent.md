# 命令行与 Agent 接入

TrueRespi 从 **0.1.1** 起随安装包提供两个命令行程序，安装时会自动加入当前用户的 `PATH`：

| 程序 | 用途 |
|---|---|
| `truerespi.exe` | 命令行工具：扫描录音、批量裁剪、导出 TXT/EDF/H5、分析、转换 |
| `truerespi-mcp.exe` | MCP stdio 服务：把同样的能力直接暴露给 Claude Desktop、Codex、OpenCode 等 Agent |

两者与桌面版共用同一套 Rust 流式裁剪核心，不需要打开图形界面，也不会把数据上传到网络。

> 实际文件位于安装目录的 `bin` 子目录（例如 `%LOCALAPPDATA%\Programs\TrueRespi\bin\truerespi.exe`）；安装程序只把该 `bin` 目录加入 `PATH`，与桌面的 `TrueRespi.exe` 互不冲突。

---

## 一、命令行安装

安装包本身支持 Inno Setup 的静默参数：

```powershell
.\TrueRespi-0.1.1-Setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
```

也可以直接用官方脚本下载、校验 SHA256 并静默安装：

```powershell
# 安装最新版（默认安装到 %LOCALAPPDATA%\Programs\TrueRespi）
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/BuTrue/TrueRespi/main/install.ps1 | iex"
```

指定版本和目录：

```powershell
.\install.ps1 -Version 0.1.1 -InstallDir D:\Apps\TrueRespi
```

卸载：

```powershell
.\install.ps1 -Uninstall
```

安装完成后**新开一个终端**，确认命令可用：

```powershell
truerespi --version
truerespi-mcp --help
```

> 已经开着的终端不会自动刷新 `PATH`；重新打开即可。

---

## 二、常用命令行

### 1. 扫描文件夹里的录音

```powershell
truerespi list "D:\呼吸数据" --recursive --ext mkt --json
```

加 `--probe` 会读取文件头，附带采样率、时长和开始时间（`.mkt` 每个约 0.8 秒）：

```powershell
truerespi list "D:\呼吸数据" --recursive --ext mkt --probe --json
```

### 2. 文件夹批量裁剪：每小时一个 TXT

```powershell
truerespi crop "D:\呼吸数据" -o "D:\导出\每小时" --every 3600 --format txt --recursive --ext mkt
```

- 递归处理所有 `.mkt`；
- 每个文件按 3600 秒分段，输出 `原文件名_00-00-00.000.txt`、`原文件名_01-00-00.000.txt`…；
- 最后一个不足 1 小时的分段也会导出；
- 输出目录不能与输入目录相同；子目录中的输出会被自动跳过，避免重复处理。

并发写分段：

```powershell
truerespi crop "D:\呼吸数据" -o "D:\导出" --every 3600 --recursive --ext mkt --workers 2
```

### 3. 指定时间段 / 绝对时间

相对秒数：

```powershell
truerespi crop "D:\呼吸数据\2.mkt" -o "D:\导出" --range 0:600 --range 1200:1800
```

绝对时间（每个文件按自己的录制开始时间解析）：

```powershell
truerespi crop "D:\呼吸数据" -o "D:\导出" --at "2026-07-12 16:00:00|17:00:00" --recursive --ext mkt
```

### 4. TXT 格式细节

```powershell
truerespi crop "D:\呼吸数据\2.mkt" -o "D:\导出" --every 3600 `
  --header emka --delimiter tab --eol crlf --decimals 6 `
  --smooth-ms 0 --timecode-offset-ms 1
```

| 参数 | 取值 |
|---|---|
| `--header` | `emka`（完整表头）/ `names`（仅列名）/ `none` |
| `--delimiter` | `tab` / `comma` / `semicolon` / `space` |
| `--eol` | `crlf` / `lf` |
| `--decimals` | 小数位数；缺省为最短往返表示 |
| `--name` | 命名模板，支持 `{stem}` `{start}` `{index}` `{ext}`；批量时必须含 `{stem}` |

### 5. 其他命令

```powershell
truerespi info "D:\呼吸数据\2.mkt" --json
truerespi models --json
truerespi convert "D:\呼吸数据\2.mkt" "D:\导出\2.h5"
truerespi analyze "D:\呼吸数据\2.mkt" -o "D:\导出\2_behavior.xlsx" --json
```

`--json` 输出统一信封：

```json
{"status":"ok","data":{...},"error":null,"exit_code":0}
```

退出码：`0` 成功、`1` 其他错误、`3` 解析/指纹错误、`4` 无可用数据。

---

## 三、MCP 接入

`truerespi-mcp.exe` 是标准 MCP stdio 服务，不需要端口，也不会常驻后台。Agent 启动它后自动完成 `initialize` 与 `tools/list`。

### 工具列表

| 工具 | 作用 |
|---|---|
| `list_recordings` | 扫描文件夹，列出录音；可选 `probe` 读取采样率/时长 |
| `crop_export` | 单文件或文件夹批量裁剪，输出 TXT/EDF/H5 |
| `recording_info` | 读取单个录音的通道、采样率、时长、标注统计 |
| `analyze_breathing` | 五类呼吸指标 + Excel 导出 + AI 行为标注 |
| `predict_behaviors` | 运行 Pneuma 正式模型，返回行为时间段 |
| `load_annotations` | 读取 `.truerespi` 项目或行为标注表 |
| `convert_format` | 转换为 CSV / NPZ / EDF / XLSX / HDF5 |
| `list_models` | 列出可用正式模型 |

`crop_export` 的关键参数：

```json
{
  "source": "D:\\呼吸数据",
  "output_dir": "D:\\导出\\每小时",
  "every": 3600,
  "format": "txt",
  "recursive": true,
  "extensions": ["mkt"]
}
```

也可以用 `ranges`（相对秒）或 `at`（绝对时间）：

```json
{
  "source": "D:\\呼吸数据\\2.mkt",
  "output_dir": "D:\\导出",
  "at": ["2026-07-12 16:00:00|17:00:00"],
  "format": "edf"
}
```

批量导出中某个文件损坏不会中断其他文件；返回结果里的 `failed` 和 `warnings` 会列出失败项。全部失败时工具返回 `isError: true`。

### Claude Desktop

编辑 `%APPDATA%\Claude\claude_desktop_config.json`：

```json
{
  "mcpServers": {
    "truerespi": {
      "command": "C:\\Users\\<用户名>\\AppData\\Local\\Programs\\TrueRespi\\bin\\truerespi-mcp.exe",
      "args": []
    }
  }
}
```

保存后完全退出并重新打开 Claude Desktop。

### Codex

编辑 `%USERPROFILE%\.codex\config.toml`：

```toml
[mcp_servers.truerespi]
command = "C:\\Users\\<用户名>\\AppData\\Local\\Programs\\TrueRespi\\bin\\truerespi-mcp.exe"
args = []
```

### OpenCode

在项目或全局 `opencode.json` 中加入：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "truerespi": {
      "type": "local",
      "command": [
        "C:\\Users\\<用户名>\\AppData\\Local\\Programs\\TrueRespi\\bin\\truerespi-mcp.exe"
      ],
      "enabled": true
    }
  }
}
```

### 可以直接对 Agent 说的话

- “扫描 `D:\呼吸数据` 下所有 mkt，递归，先告诉我每个文件多长。”
- “把这些 mkt 每小时导出一个 txt，放到 `D:\导出\每小时`。”
- “把 `2.mkt` 里 2026-07-12 16:00 到 17:00 的数据导出成 EDF。”
- “分析 `2.mkt` 前 30 分钟的呼吸指标，并导出 Excel。”

Agent 会先调用 `list_recordings`，再调用 `crop_export` 或 `analyze_breathing`，不需要你手工拼命令。

---

## 四、注意事项

- MCP 服务只监听 stdio，不开放网络端口；数据始终在本机。
- Agent 传入的路径必须是本机可访问的绝对路径。
- 批量导出默认只处理 `mkt / txt / csv / adicht`；EDF、NPZ、HDF5 可以读取和分析，但当前裁剪核心只支持上述源格式。
- TXT 输出体积较大：1 kHz 单通道每小时约 50–70 MB（取决于小数位和表头）。
- 安装目录、用户项目和导出结果都可以放在任意磁盘；卸载不会删除 `%APPDATA%\TrueRespi`。

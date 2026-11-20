# TrueRespi 0.1.4

## 修复

- **安装后启动显示「127.0.0.1 拒绝连接 / ERR_CONNECTION_REFUSED」**。0.1.3 的桌面程序以开发模式编译：启动时去连接本机开发服务器 `http://127.0.0.1:1431`，而不是加载打包在程序里的界面。没有运行开发服务器时，窗口里就只有浏览器的“无法访问此页面”。0.1.4 改为生产模式编译（启用 Tauri 的 `custom-protocol`），界面资源已嵌入程序，断网、无本地服务也能启动。
- 0.1.3 因为界面无法加载，应用内自动更新同样不可用。**请从本页手动下载安装一次 0.1.4**；装好以后，后续版本的自动更新恢复正常。
- 命令行与 MCP 程序同步更新版本号，`truerespi --version` 显示 `0.1.4`。

## 安装说明

- 安装包由 Inno Setup 7 制作，AppId 与安装目录沿用旧版本，可直接覆盖安装。
- 用户数据（标注、偏好、布局预设、日志）保留在 `%APPDATA%\TrueRespi`，覆盖安装不会清除。
- 装完后桌面快捷方式与开始菜单指向新程序；`bin\` 下的 `truerespi.exe` 与 `truerespi-mcp.exe` 同步更新。

## 校验

```powershell
Get-FileHash .\TrueRespi-0.1.4-Setup.exe -Algorithm SHA256
# 39b798fbcdc1ffdb9093ff4f5192414f146ac415865e61f5832c0e77f303b5fe
```

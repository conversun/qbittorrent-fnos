# qBittorrent for fnOS

Auto-build qBittorrent packages for fnOS - Daily updates from qbittorrent-nox-static releases

## Download

从 [Releases](https://github.com/conversun/qbittorrent-fnos/releases) 下载最新的 `.fpk` 文件。

## Install

1. 下载 `qbittorrent_x.x.x_amd64.fpk`
2. 在 fnOS 应用管理中选择「手动安装」
3. 上传 fpk 文件完成安装

## Default Credentials

- **Username**: admin
- **Password**: adminadmin

⚠️ 请在首次登录后立即修改密码！

## Web UI

安装后访问 `http://<your-nas-ip>:8085`

## Configuration Changes

本项目对原生 qBittorrent 做了以下预配置，以适配 fnOS 环境：

### 基础设置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `LegalNotice\Accepted` | `true` | 自动接受法律声明，跳过首次启动提示 |
| `General\Locale` | `zh_CN` | 默认中文界面 |

### 路径配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `Session\DefaultSavePath` | `/var/apps/qBittorrent/shares/qBittorrent/Download` | 默认下载目录 |
| `Session\TempPath` | `/var/apps/qBittorrent/shares/qBittorrent/temp` | 临时文件目录 |
| `Session\TempPathEnabled` | `false` | 禁用独立临时目录 |
| `FileLogger\Enabled` | `true` | 启用日志 |
| `FileLogger\Path` | `/var/apps/qBittorrent/var/logs` | 日志目录 |

### 网络配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `Session\Port` | `63219` | BT 监听端口 |
| `Session\QueueingSystemEnabled` | `false` | 禁用队列系统，不限制同时下载数 |

### WebUI 配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `WebUI\Port` | `8085` | WebUI 端口 |
| `WebUI\Username` | `admin` | 默认用户名 |
| `WebUI\Password_PBKDF2` | *(预设hash)* | 默认密码 `adminadmin` |
| `WebUI\CSRFProtection` | `false` | 禁用 CSRF 保护，允许 fnOS 反代访问 |
| `WebUI\ClickjackingProtection` | `false` | 禁用点击劫持保护，允许 iframe 嵌入 |
| `WebUI\HostHeaderValidation` | `false` | 禁用 Host 头验证，允许通过反代访问 |

### 目录结构

```
/var/apps/qBittorrent/
├── var/
│   ├── qBittorrent/config/qBittorrent.conf  # 配置文件
│   └── logs/
│       ├── qbittorrent.log                   # 应用日志
│       └── service.log                       # 服务启停日志
└── shares/qBittorrent/
    ├── Download/                             # 下载目录
    └── temp/                                 # 临时目录
```

## Fixes (相对官方旧版 fpk)

本项目修复了官方/第三方旧版 fpk 的以下问题：

### 🔧 配置路径修复

| 问题 | 旧版 | 修复后 |
|------|------|--------|
| 配置文件路径错误 | `target/qBittorrent_conf/config/` (使用 `--configuration=conf`) | `var/qBittorrent/config/` (标准 profile 路径) |
| 配置无法持久化 | 配置写入 target 目录，升级后丢失 | 配置写入 var 目录，升级保留 |
| 日志路径 | `/tmp/qBittorrent-logs` (临时目录，重启丢失) | `/var/apps/qBittorrent/var/logs` (持久化) |

### 🔐 认证修复

| 问题 | 旧版 | 修复后 |
|------|------|--------|
| 缺少默认用户名 | 配置中无 `WebUI\Username` | 预设 `admin` |
| 首次启动临时密码 | 每次启动生成随机临时密码 | 预设固定密码 `adminadmin` |
| 升级时凭据丢失 | 仅补充密码，不补充用户名 | 同时检查并补充用户名和密码 |

### 📦 打包改进

| 问题 | 旧版 | 修复后 |
|------|------|--------|
| WebUI 访问权限 | `allUsers: false` (仅管理员可见) | `allUsers: true` (所有用户可见) |
| 法律声明 | 首次启动需手动接受 | 自动接受，跳过提示 |
| 日志文件混淆 | 框架日志与应用日志同名 | 框架日志改名为 `service.log` |
| manifest 格式 | 旧格式 (带引号) | fnOS 标准格式 |

### 🗑️ 精简内容

移除了旧版中不必要的组件：
- `qbmonitor` 监控脚本
- `password-gen` 密码生成工具
- `nova3/engines/` 搜索插件 (50+ 个 Python 文件)
- `GeoDB` 地理数据库

## Auto Update

GitHub Actions 每天自动检查 [qbittorrent-nox-static Releases](https://github.com/userdocs/qbittorrent-nox-static/releases)，有新版本时自动构建并发布。

## Architecture

- **Platform**: fnOS (飞牛私有云)
- **Architecture**: x86_64 (amd64)

## Credits

- [qBittorrent](https://www.qbittorrent.org/) - BitTorrent Client
- [userdocs/qbittorrent-nox-static](https://github.com/userdocs/qbittorrent-nox-static) - Static builds

# qBittorrent for fnOS

自动构建 fnOS 的 qBittorrent 安装包，每日同步 [qbittorrent-nox-static](https://github.com/userdocs/qbittorrent-nox-static/releases) 最新版本。

## 下载

从 [Releases](https://github.com/conversun/qbittorrent-fnos/releases) 下载 `.fpk` 文件。

## 安装

1. 根据你的设备架构下载对应的 `.fpk` 文件
2. fnOS 应用管理 → 手动安装 → 上传

**默认账号**: `admin` / `adminadmin` ⚠️ 请及时修改密码

**访问地址**: `http://<NAS-IP>:8085`

### ⚠️ 从旧版迁移

由于本项目为非官方重新打包，与旧版 fpk (如矿神 SPK) 不兼容，**无法直接升级**，需先卸载旧版再安装。

**迁移前请备份**:
- 旧版配置目录 (通常在 `target/qBittorrent_conf/` 或 `var/config/`)
- 种子文件 (BT_backup 目录)
- 下载任务列表

**迁移风险**:
- 卸载旧版可能导致配置丢失
- 新旧版配置路径不同，无法自动继承
- 需重新添加 Tracker、重新登录

## 预设配置

| 类别 | 配置 |
|------|------|
| 界面 | 中文、自动接受法律声明 |
| 端口 | WebUI `8085`、BT `63219` |
| 路径 | 下载目录 `shares/qBittorrent/Download`、日志 `var/logs` |
| WebUI | 禁用 CSRF/点击劫持/Host 验证 (适配 fnOS 反代) |
| 数据 | 自动下载最新 [DB-IP GeoDB](https://db-ip.com/db/lite.php) 用于 Peer 地理位置显示 |

## 相对旧版 fpk 的修复

| 问题 | 修复 |
|------|------|
| 配置路径错误，升级丢失 | 改用标准 profile 路径 `var/qBittorrent/config/` |
| 日志写入 `/tmp`，重启丢失 | 改为 `var/logs/` 持久化 |
| 缺少用户名，每次生成临时密码 | 预设 `admin`/`adminadmin` |
| WebUI 仅管理员可见 | 改为所有用户可见 |
| 框架日志与应用日志同名混淆 | 框架日志改名为 `service.log` |
| 包含 50+ 无用搜索插件 | 精简移除 |

## 本地构建

```bash
# 自动检测架构，构建最新版本
./update_qbittorrent.sh

# 指定架构
./update_qbittorrent.sh --arch arm
./update_qbittorrent.sh --arch x86

# 指定版本
./update_qbittorrent.sh --arch arm 5.1.4

# 查看帮助
./update_qbittorrent.sh --help
```

## 版本标签

Release 版本号规则：
- `v5.1.4` - 首次发布
- `v5.1.4-r2` - 同版本的打包修订（上游未更新时重新发布）

## 自动更新

GitHub Actions 每日检查上游新版本，自动构建发布。构建时自动获取：
- 最新 qbittorrent-nox 静态编译版
- 最新 DB-IP GeoDB 数据库

## 开源透明

本项目完全开源，仅从官方渠道下载原版软件并重新打包，**无任何后门或修改**。构建脚本和 CI 流程公开透明，欢迎审查。

## Credits

- [qBittorrent](https://www.qbittorrent.org/)
- [userdocs/qbittorrent-nox-static](https://github.com/userdocs/qbittorrent-nox-static)
- [DB-IP Lite](https://db-ip.com/db/lite.php)

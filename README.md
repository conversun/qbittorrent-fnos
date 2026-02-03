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

## Auto Update

GitHub Actions 每天自动检查 [qbittorrent-nox-static Releases](https://github.com/userdocs/qbittorrent-nox-static/releases)，有新版本时自动构建并发布。

## Architecture

- **Platform**: fnOS (飞牛私有云)
- **Architecture**: x86_64 (amd64)

## Credits

- [qBittorrent](https://www.qbittorrent.org/) - BitTorrent Client
- [userdocs/qbittorrent-nox-static](https://github.com/userdocs/qbittorrent-nox-static) - Static builds

#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"
WORK_DIR="/tmp/qbittorrent_update_$$"
QB_VERSION="${1:-latest}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

get_latest_version() {
    info "获取最新版本信息..."
    
    if [ "$QB_VERSION" = "latest" ]; then
        RELEASE_TAG=$(curl -sL "https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases/latest" 2>/dev/null | \
            grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        QB_VERSION=$(echo "$RELEASE_TAG" | sed -E 's/release-([0-9]+\.[0-9]+\.[0-9]+)_.*/\1/')
    else
        RELEASE_TAG=$(curl -sL "https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases/latest" 2>/dev/null | \
            grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    fi
    
    [ -z "$QB_VERSION" ] && error "无法获取版本信息，请手动指定: $0 5.1.4"
    
    info "目标版本: $QB_VERSION"
    info "Release Tag: $RELEASE_TAG"
}

download_binary() {
    local download_url="https://github.com/userdocs/qbittorrent-nox-static/releases/download/${RELEASE_TAG}/x86_64-qbittorrent-nox"
    
    info "下载: $download_url"
    mkdir -p "$WORK_DIR"
    
    curl -L -f -o "$WORK_DIR/qbittorrent-nox" "$download_url" || error "下载失败"
    chmod +x "$WORK_DIR/qbittorrent-nox"
    info "下载完成: $(du -h "$WORK_DIR/qbittorrent-nox" | cut -f1)"
}

build_app_tgz() {
    info "构建 app.tgz..."
    
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/ui/images" "$dst/var/qBittorrent/config"
    
    cp "$WORK_DIR/qbittorrent-nox" "$dst/bin/"
    chmod +x "$dst/bin/qbittorrent-nox"
    
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true
    
    cat > "$dst/var/qBittorrent/config/qBittorrent.conf" << 'QBCONF'
[LegalNotice]
Accepted=true

[Application]
FileLogger\Enabled=true
FileLogger\Path=/var/apps/qBittorrent/var/logs

[BitTorrent]
Session\DefaultSavePath=/var/apps/qBittorrent/shares/qBittorrent/Download
Session\TempPath=/var/apps/qBittorrent/shares/qBittorrent/temp
Session\TempPathEnabled=false
Session\Port=63219
Session\QueueingSystemEnabled=false

[Preferences]
General\Locale=zh_CN
WebUI\Port=8085
WebUI\Username=admin
WebUI\Password_PBKDF2="@ByteArray(xK2EwRvfGtxfF+Ot9v4WYQ==:bNStY/6mFYYW8m/Xm4xSbBjoR2tZNsLZ4KvdUzyCLEOg7tfpchVJucIK9Dwcp6Xe9DI4RwpoCPI9zhicTdtf5A==)"
WebUI\CSRFProtection=false
WebUI\ClickjackingProtection=false
WebUI\HostHeaderValidation=false
QBCONF
    
    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

update_manifest() {
    info "更新 manifest..."
    local checksum=$(md5 -q "$WORK_DIR/app.tgz" 2>/dev/null || md5sum "$WORK_DIR/app.tgz" | cut -d' ' -f1)
    
    sed -i.tmp "s/^version.*=.*/version         = ${QB_VERSION}/" "$PKG_DIR/manifest"
    sed -i.tmp "s/^checksum.*=.*/checksum        = ${checksum}/" "$PKG_DIR/manifest"
    rm -f "$PKG_DIR/manifest.tmp"
}

build_fpk() {
    local fpk_name="qbittorrent_${QB_VERSION}_amd64.fpk"
    info "打包 $fpk_name..."
    
    mkdir -p "$WORK_DIR/package"
    
    cp "$WORK_DIR/app.tgz" "$WORK_DIR/package/"
    cp -a "$PKG_DIR/cmd" "$WORK_DIR/package/"
    cp -a "$PKG_DIR/config" "$WORK_DIR/package/"
    cp -a "$PKG_DIR/wizard" "$WORK_DIR/package/"
    cp "$PKG_DIR"/*.sc "$WORK_DIR/package/" 2>/dev/null || true
    cp "$PKG_DIR"/ICON*.PNG "$WORK_DIR/package/"
    cp "$PKG_DIR/manifest" "$WORK_DIR/package/"
    
    cd "$WORK_DIR/package"
    tar -czf "$SCRIPT_DIR/$fpk_name" *
    
    info "生成: $SCRIPT_DIR/$fpk_name ($(du -h "$SCRIPT_DIR/$fpk_name" | cut -f1))"
}

show_help() {
    cat << EOF
用法: $0 [版本号|latest]

示例:
  $0                # 最新稳定版
  $0 5.1.4          # 指定版本
  $0 latest         # 最新版本

说明:
  默认用户名: admin
  默认密码: adminadmin
EOF
}

main() {
    [ "$1" = "-h" ] || [ "$1" = "--help" ] && { show_help; exit 0; }
    
    echo "========================================"
    echo "  qBittorrent fnOS Package Builder"
    echo "========================================"
    echo
    
    for cmd in curl tar sed; do
        command -v $cmd &>/dev/null || error "缺少依赖: $cmd"
    done
    
    [ -f "$PKG_DIR/manifest" ] || error "找不到 fnos 目录"
    
    local current_version=$(grep "^version" "$PKG_DIR/manifest" | awk -F'=' '{print $2}' | tr -d ' ')
    info "当前版本: $current_version"
    
    get_latest_version
    
    if [ "$current_version" = "$QB_VERSION" ]; then
        warn "已是最新版本"
        read -p "强制重新构建? [y/N] " -n 1 -r; echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    download_binary
    build_app_tgz
    update_manifest
    build_fpk
    
    echo
    info "完成: $current_version -> $QB_VERSION"
}

main "$@"

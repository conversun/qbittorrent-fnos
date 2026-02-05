#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"
WORK_DIR="/tmp/qbittorrent_update_$$"
QB_VERSION="${QB_VERSION:-latest}"
ARCH="${ARCH:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

detect_arch() {
    if [ -z "$ARCH" ]; then
        local machine=$(uname -m)
        case "$machine" in
            x86_64|amd64)
                ARCH=amd64
                ;;
            aarch64|arm64)
                ARCH=arm64
                ;;
            *)
                error "Unsupported architecture: $machine. Use --arch to specify amd64 or arm64."
                ;;
        esac
        info "Auto-detected architecture: $ARCH"
    fi
    
    case "$ARCH" in
        amd64)
            BINARY_PREFIX="x86_64"
            MANIFEST_ARCH="x86_64"
            ;;
        arm64)
            BINARY_PREFIX="aarch64"
            MANIFEST_ARCH="aarch64"
            ;;
        *)
            error "Invalid architecture: $ARCH. Must be amd64 or arm64."
            ;;
    esac
    
    info "Binary prefix: $BINARY_PREFIX"
    info "Manifest arch: $MANIFEST_ARCH"
}

get_latest_version() {
    info "获取最新版本信息..."
    
    RELEASE_TAG=$(curl -sL "https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases/latest" 2>/dev/null | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ "$QB_VERSION" = "latest" ]; then
        QB_VERSION=$(echo "$RELEASE_TAG" | sed -E 's/release-([0-9]+\.[0-9]+\.[0-9]+)_.*/\1/')
    fi
    
    [ -z "$QB_VERSION" ] && error "无法获取版本信息，请手动指定: $0 5.1.4"
    
    info "目标版本: $QB_VERSION"
    info "Release Tag: $RELEASE_TAG"
}

download_binary() {
    local download_url="https://github.com/userdocs/qbittorrent-nox-static/releases/download/${RELEASE_TAG}/${BINARY_PREFIX}-qbittorrent-nox"
    
    info "下载 qbittorrent-nox ($ARCH)..."
    mkdir -p "$WORK_DIR"
    
    curl -L -f -o "$WORK_DIR/qbittorrent-nox" "$download_url" || error "下载 qbittorrent-nox 失败"
    chmod +x "$WORK_DIR/qbittorrent-nox"
    info "下载完成: $(du -h "$WORK_DIR/qbittorrent-nox" | cut -f1)"
}

download_geodb() {
    local year_month=$(date +%Y-%m)
    local geodb_url="https://download.db-ip.com/free/dbip-country-lite-${year_month}.mmdb.gz"
    
    info "下载 GeoDB (${year_month})..."
    mkdir -p "$WORK_DIR/GeoDB"
    
    if curl -L -f -o "$WORK_DIR/GeoDB/dbip-country-lite.mmdb.gz" "$geodb_url" 2>/dev/null; then
        gunzip -f "$WORK_DIR/GeoDB/dbip-country-lite.mmdb.gz"
        info "GeoDB 下载完成: $(du -h "$WORK_DIR/GeoDB/dbip-country-lite.mmdb" | cut -f1)"
    else
        warn "GeoDB 下载失败，尝试上月版本..."
        year_month=$(date -v-1m +%Y-%m 2>/dev/null || date -d "1 month ago" +%Y-%m)
        geodb_url="https://download.db-ip.com/free/dbip-country-lite-${year_month}.mmdb.gz"
        curl -L -f -o "$WORK_DIR/GeoDB/dbip-country-lite.mmdb.gz" "$geodb_url" || warn "GeoDB 下载失败，跳过"
        [ -f "$WORK_DIR/GeoDB/dbip-country-lite.mmdb.gz" ] && gunzip -f "$WORK_DIR/GeoDB/dbip-country-lite.mmdb.gz"
    fi
}

build_app_tgz() {
    info "构建 app.tgz..."
    
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/ui/images" "$dst/var/qBittorrent/config" "$dst/var/qBittorrent/data/GeoDB"
    
    cp "$WORK_DIR/qbittorrent-nox" "$dst/bin/"
    chmod +x "$dst/bin/qbittorrent-nox"
    
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true
    cp -a "$WORK_DIR/GeoDB"/* "$dst/var/qBittorrent/data/GeoDB/" 2>/dev/null || true
    
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
    
    if ! grep -q "^arch" "$PKG_DIR/manifest"; then
        echo "arch            = ${MANIFEST_ARCH}" >> "$PKG_DIR/manifest"
    else
        sed -i.tmp "s/^arch.*=.*/arch            = ${MANIFEST_ARCH}/" "$PKG_DIR/manifest"
    fi
    
    rm -f "$PKG_DIR/manifest.tmp"
}

build_fpk() {
    local fpk_name="qbittorrent_${QB_VERSION}_${ARCH}.fpk"
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
用法: $0 [选项] [版本号|latest]

选项:
  --arch ARCH       指定目标架构 (amd64 或 arm64)，默认自动检测
  -h, --help        显示此帮助信息

示例:
  $0                        # 最新稳定版，自动检测架构
  $0 --arch arm64           # 最新版本，ARM64 架构
  $0 --arch amd64 5.1.4     # 指定版本，AMD64 架构
  $0 5.1.4                  # 指定版本，自动检测架构

环境变量:
  ARCH              目标架构 (amd64 或 arm64)
  QB_VERSION        qBittorrent 版本号

支持的架构:
  amd64 (x86_64)    Intel/AMD 64位处理器
  arm64 (aarch64)   ARM 64位处理器

说明:
  默认用户名: admin
  默认密码: adminadmin
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --arch)
                ARCH="$2"
                shift 2
                ;;
            --arch=*)
                ARCH="${1#*=}"
                shift
                ;;
            -*)
                error "未知选项: $1"
                ;;
            *)
                QB_VERSION="$1"
                shift
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    
    echo "========================================"
    echo "  qBittorrent fnOS Package Builder"
    echo "========================================"
    echo
    
    for cmd in curl tar sed; do
        command -v $cmd &>/dev/null || error "缺少依赖: $cmd"
    done
    
    [ -f "$PKG_DIR/manifest" ] || error "找不到 fnos 目录"
    
    detect_arch
    
    local current_version=$(grep "^version" "$PKG_DIR/manifest" | awk -F'=' '{print $2}' | tr -d ' ')
    info "当前版本: $current_version"
    
    get_latest_version
    
    if [ "$current_version" = "$QB_VERSION" ]; then
        warn "已是最新版本"
        read -p "强制重新构建? [y/N] " -n 1 -r; echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    download_binary
    download_geodb
    build_app_tgz
    update_manifest
    build_fpk
    
    echo
    info "完成: $current_version -> $QB_VERSION ($ARCH)"
}

main "$@"

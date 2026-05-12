#!/usr/bin/env sh

set -eu

DEFAULT_REPO_SLUG="Hur1k/uvworkon"
DEFAULT_REPO_REF="main"
DEFAULT_INSTALL_DIR="$HOME/.local/uv_venvs"
SCRIPT_FILES="uvworkon.sh setup_uvworkon_alias.sh uninstall_uvworkon_alias.sh"

usage() {
    cat <<'EOF'
Usage: curl -fsSL <install-url> | bash -s -- [setup-options]

Environment variables:
  UVWORKON_INSTALL_DIR   Install directory and uvworkon home
  UVWORKON_DOWNLOAD_BASE Override the raw file base URL
  UVWORKON_REPO_SLUG     GitHub repo slug, default: Hur1k/uvworkon
  UVWORKON_REPO_REF      Git ref, default: main
  UVWORKON_INSTALL_UV    UV install mode for setup script: always|prompt|never

Setup options are forwarded to setup_uvworkon_alias.sh.
Example:
  curl -fsSL <install-url> | bash -s -- --shell zsh
EOF
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

download_file() {
    _file_name=$1
    _target_path=$2

    for _base_url in $DOWNLOAD_BASES; do
        _url=$_base_url/$_file_name
        echo "[!] Downloading $_file_name from $_url"
        if curl -fsSL "$_url" -o "$_target_path"; then
            return 0
        fi
    done

    return 1
}

if [ "${1-}" = "-h" ] || [ "${1-}" = "--help" ]; then
    usage
    exit 0
fi

command_exists curl || {
    echo "error: curl is required" >&2
    exit 1
}

INSTALL_DIR=${UVWORKON_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
REPO_SLUG=${UVWORKON_REPO_SLUG:-$DEFAULT_REPO_SLUG}
REPO_REF=${UVWORKON_REPO_REF:-$DEFAULT_REPO_REF}

if [ -n "${UVWORKON_DOWNLOAD_BASE:-}" ]; then
    DOWNLOAD_BASES=$UVWORKON_DOWNLOAD_BASE
else
    DOWNLOAD_BASES="https://raw.githubusercontent.com/$REPO_SLUG/$REPO_REF https://gh-proxy.com/https://raw.githubusercontent.com/$REPO_SLUG/$REPO_REF"
fi

mkdir -p "$INSTALL_DIR"

for _file_name in $SCRIPT_FILES; do
    _target_path=$INSTALL_DIR/$_file_name
    download_file "$_file_name" "$_target_path" || {
        echo "error: failed to download $_file_name" >&2
        exit 1
    }
done

chmod 755 \
    "$INSTALL_DIR/setup_uvworkon_alias.sh" \
    "$INSTALL_DIR/uninstall_uvworkon_alias.sh" \
    "$INSTALL_DIR/uvworkon.sh"

echo "[!] Installed uvworkon files into: $INSTALL_DIR"
echo "[!] This directory is also your uvworkon environment home."
echo "[!] Create or move UV environments under this directory to make them discoverable."

if [ -z "${UVWORKON_INSTALL_UV:-}" ]; then
    UVWORKON_INSTALL_UV=always
fi
export UVWORKON_INSTALL_UV

exec sh "$INSTALL_DIR/setup_uvworkon_alias.sh" --force "$@"

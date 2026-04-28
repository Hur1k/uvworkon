#!/usr/bin/env sh

set -eu

BEGIN_MARK="# >>> uvworkon initialize >>>"
END_MARK="# <<< uvworkon initialize <<<"
UV_CUSTOM_RELEASES_URL="https://gitee.com/wangnov/uv-custom/releases"
DEFAULT_UV_DOWNLOAD_PROXY="https://gh-proxy.com"
DEFAULT_UV_PYPI_MIRROR="https://mirrors.aliyun.com/pypi/simple/"
DEFAULT_UV_VERSION="0.7.19"

FORCE=0
TARGET_RC_FILE=
TARGET_SHELL=

usage() {
    cat <<'EOF'
Usage: ./setup_uvworkon_alias.sh [--force] [--shell bash|zsh|profile] [--rc-file PATH]
EOF
}

profile_for_shell() {
    case "$1" in
        bash)
            printf '%s\n' "$HOME/.bashrc"
            ;;
        zsh)
            printf '%s\n' "${ZDOTDIR:-$HOME}/.zshrc"
            ;;
        profile)
            printf '%s\n' "$HOME/.profile"
            ;;
        *)
            return 1
            ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_default_profile() {
    _detected_shell=$(ps -p "$PPID" -o comm= 2>/dev/null | awk '{print $1}')
    _detected_shell=$(basename "${_detected_shell:-${SHELL:-}}")
    case "$_detected_shell" in
        bash)
            profile_for_shell bash
            ;;
        zsh)
            profile_for_shell zsh
            ;;
        *)
            if [ -f "$HOME/.bashrc" ]; then
                profile_for_shell bash
            elif [ -f "${ZDOTDIR:-$HOME}/.zshrc" ]; then
                profile_for_shell zsh
            else
                profile_for_shell profile
            fi
            ;;
    esac
}

prompt_yes_no() {
    _prompt=$1
    printf "%s [y/N]: " "$_prompt"
    if ! IFS= read -r _answer; then
        return 1
    fi

    case $_answer in
        y|Y|yes|YES)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

fetch_latest_uv_custom_release() {
    if [ -n "${UVWORKON_UV_CUSTOM_RELEASE:-}" ]; then
        printf '%s\n' "$UVWORKON_UV_CUSTOM_RELEASE"
        return 0
    fi

    command_exists curl || {
        echo "error: curl is required to detect the latest uv-custom release" >&2
        return 1
    }

    _releases_html=$(curl -fsSL "$UV_CUSTOM_RELEASES_URL") || {
        echo "error: failed to fetch uv-custom releases from $UV_CUSTOM_RELEASES_URL" >&2
        return 1
    }

    _release_tag=$(
        printf '%s\n' "$_releases_html" \
        | grep -Eo 'releases/download/[0-9][0-9.]*/uv-installer-custom\.sh' \
        | head -n 1 \
        | cut -d/ -f3
    )

    if [ -z "${_release_tag:-}" ]; then
        echo "error: failed to detect the latest uv-custom release tag" >&2
        return 1
    fi

    printf '%s\n' "$_release_tag"
}

install_uv() {
    _release_tag=$(fetch_latest_uv_custom_release) || return 1
    _installer_url="https://gitee.com/wangnov/uv-custom/releases/download/$_release_tag/uv-installer-custom.sh"
    _download_proxy=${UVWORKON_UV_DOWNLOAD_PROXY:-$DEFAULT_UV_DOWNLOAD_PROXY}
    _pypi_mirror=${UVWORKON_UV_PYPI_MIRROR:-$DEFAULT_UV_PYPI_MIRROR}
    _uv_version=${UVWORKON_UV_VERSION:-$DEFAULT_UV_VERSION}
    _installer_file=$(mktemp)

    echo "[!] Latest uv-custom release: $_release_tag"
    echo "[!] Installing uv with UV_VERSION=$_uv_version"
    echo "[!] Installer URL: $_installer_url"

    if ! curl -LsSf "$_installer_url" -o "$_installer_file"; then
        rm -f "$_installer_file"
        echo "error: failed to download uv installer" >&2
        return 1
    fi

    if ! env \
        UV_DOWNLOAD_PROXY="$_download_proxy" \
        UV_PYPI_MIRROR="$_pypi_mirror" \
        UV_VERSION="$_uv_version" \
        sh "$_installer_file"; then
        rm -f "$_installer_file"
        echo "error: uv installer exited with an error" >&2
        return 1
    fi

    rm -f "$_installer_file"
    return 0
}

ensure_uv_available() {
    if command_exists uv; then
        return 0
    fi

    echo "[!] uv command not found in PATH."

    if [ ! -t 0 ]; then
        echo "[!] Non-interactive shell detected, skipping automatic uv installation."
        echo "[!] You can install uv later and uvworkon will still work after that."
        return 0
    fi

    if ! prompt_yes_no "Install uv now via uv-custom?"; then
        echo "[!] Skipping uv installation. You can install it later."
        return 0
    fi

    install_uv || return 1

    if command_exists uv; then
        echo "[!] uv installation completed successfully."
    else
        echo "[!] uv installer finished. If 'uv' is still unavailable, reload your shell or reopen the terminal."
    fi
}

remove_existing_block() {
    _source_file=$1
    _target_file=$2
    awk -v begin="$BEGIN_MARK" -v end="$END_MARK" '
        $0 == begin { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$_source_file" > "$_target_file"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)
            FORCE=1
            shift
            ;;
        --shell)
            [ $# -ge 2 ] || {
                echo "error: --shell requires a value" >&2
                exit 1
            }
            TARGET_SHELL=$2
            shift 2
            ;;
        --rc-file)
            [ $# -ge 2 ] || {
                echo "error: --rc-file requires a value" >&2
                exit 1
            }
            TARGET_RC_FILE=$2
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "error: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [ -n "$TARGET_RC_FILE" ] && [ -n "$TARGET_SHELL" ]; then
    echo "error: use either --shell or --rc-file, not both" >&2
    exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
UVWORKON_SCRIPT="$SCRIPT_DIR/uvworkon.sh"

echo "uvworkon Alias Setup Script"
echo "==========================="

if [ ! -f "$UVWORKON_SCRIPT" ]; then
    echo "error: uvworkon.sh file not found at: $UVWORKON_SCRIPT" >&2
    exit 1
fi

echo "[!] Found uvworkon.sh at: $UVWORKON_SCRIPT"

ensure_uv_available

if [ -n "$TARGET_RC_FILE" ]; then
    PROFILE_PATH=$TARGET_RC_FILE
elif [ -n "$TARGET_SHELL" ]; then
    PROFILE_PATH=$(profile_for_shell "$TARGET_SHELL") || {
        echo "error: unsupported shell: $TARGET_SHELL" >&2
        exit 1
    }
else
    PROFILE_PATH=$(detect_default_profile)
fi

echo "[!] Shell rc file path: $PROFILE_PATH"

PROFILE_DIR=$(dirname -- "$PROFILE_PATH")
if [ ! -d "$PROFILE_DIR" ]; then
    echo "[!] Creating shell rc directory..."
    mkdir -p "$PROFILE_DIR"
fi

if [ ! -f "$PROFILE_PATH" ]; then
    : > "$PROFILE_PATH"
fi

ALIAS_EXISTS=0
if grep -F "$BEGIN_MARK" "$PROFILE_PATH" >/dev/null 2>&1; then
    ALIAS_EXISTS=1
fi

if [ "$ALIAS_EXISTS" -eq 1 ] && [ "$FORCE" -ne 1 ]; then
    echo "uvworkon alias already exists in the target rc file."
    echo "Use --force to overwrite the existing configuration."
    exit 0
fi

if [ "$ALIAS_EXISTS" -eq 1 ]; then
    echo "[!] Replacing existing uvworkon configuration..."
    TEMP_FILE=$(mktemp)
    remove_existing_block "$PROFILE_PATH" "$TEMP_FILE"
    mv "$TEMP_FILE" "$PROFILE_PATH"
fi

echo "Adding uvworkon initialization block..."

cat >> "$PROFILE_PATH" <<EOF

$BEGIN_MARK
export UVWORKON_HOME="$SCRIPT_DIR"
. "$UVWORKON_SCRIPT"
$END_MARK
EOF

echo "Successfully added uvworkon alias to the shell rc file."
echo
echo "Usage:"
echo "  uvworkon <env_name>     - Activate specified virtual environment"
echo "  uvworkon                - Show all available virtual environments"
echo
echo "Reload your shell configuration to use the command:"
echo "  . \"$PROFILE_PATH\""

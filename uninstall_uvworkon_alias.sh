#!/usr/bin/env sh

set -eu

BEGIN_MARK="# >>> uvworkon initialize >>>"
END_MARK="# <<< uvworkon initialize <<<"

TARGET_RC_FILE=
TARGET_SHELL=

usage() {
    cat <<'EOF'
Usage: ./uninstall_uvworkon_alias.sh [--shell bash|zsh|profile] [--rc-file PATH]
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

remove_existing_block() {
    _source_file=$1
    _target_file=$2
    awk -v begin="$BEGIN_MARK" -v end="$END_MARK" '
        $0 == begin { skip = 1; next }
        $0 == end { skip = 0; next }
        !skip { print }
    ' "$_source_file" > "$_target_file"
}

remove_from_profile() {
    PROFILE_PATH=$1
    echo "[!] Checking: $PROFILE_PATH"

    if [ ! -f "$PROFILE_PATH" ]; then
        return 0
    fi

    if ! grep -F "$BEGIN_MARK" "$PROFILE_PATH" >/dev/null 2>&1; then
        return 0
    fi

    TEMP_FILE=$(mktemp)
    remove_existing_block "$PROFILE_PATH" "$TEMP_FILE"
    mv "$TEMP_FILE" "$PROFILE_PATH"
    REMOVED_COUNT=$((REMOVED_COUNT + 1))
    echo "    removed uvworkon configuration"
}

while [ $# -gt 0 ]; do
    case "$1" in
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

echo "uvworkon Alias Uninstall Script"
echo "==============================="

if [ -n "$TARGET_RC_FILE" ]; then
    TARGETS=$TARGET_RC_FILE
elif [ -n "$TARGET_SHELL" ]; then
    TARGETS=$(profile_for_shell "$TARGET_SHELL") || {
        echo "error: unsupported shell: $TARGET_SHELL" >&2
        exit 1
    }
else
    TARGETS="$HOME/.bashrc ${ZDOTDIR:-$HOME}/.zshrc $HOME/.profile"
fi

REMOVED_COUNT=0

if [ -n "$TARGET_RC_FILE" ]; then
    remove_from_profile "$TARGETS"
elif [ -n "$TARGET_SHELL" ]; then
    remove_from_profile "$TARGETS"
else
    remove_from_profile "$HOME/.bashrc"
    remove_from_profile "${ZDOTDIR:-$HOME}/.zshrc"
    remove_from_profile "$HOME/.profile"
fi

if [ "$REMOVED_COUNT" -eq 0 ]; then
    echo "No uvworkon alias configuration was found."
    exit 0
fi

echo
echo "Successfully removed uvworkon alias configuration from $REMOVED_COUNT file(s)."
echo "Reload your shell or open a new terminal for the changes to take effect."

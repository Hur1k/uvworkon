#!/usr/bin/env sh

_uvworkon_is_sourced=0
(return 0 2>/dev/null) && _uvworkon_is_sourced=1

if [ "$_uvworkon_is_sourced" -ne 1 ]; then
    echo "error: source this file instead of executing it:" >&2
    echo "  . /path/to/uvworkon.sh" >&2
    exit 1
fi

unset _uvworkon_is_sourced

_uvworkon_resolve_home() {
    if [ -n "${UVWORKON_HOME:-}" ]; then
        printf '%s\n' "$UVWORKON_HOME"
        return 0
    fi

    _uvworkon_script_path=
    if [ -n "${BASH_VERSION:-}" ]; then
        _uvworkon_script_path=${BASH_SOURCE[0]}
    elif [ -n "${ZSH_VERSION:-}" ]; then
        _uvworkon_script_path=$(eval 'printf "%s" "${(%):-%N}"')
    else
        _uvworkon_script_path=$0
    fi

    _uvworkon_script_dir=$(CDPATH= cd -- "$(dirname -- "$_uvworkon_script_path")" 2>/dev/null && pwd)
    if [ -z "$_uvworkon_script_dir" ]; then
        return 1
    fi

    printf '%s\n' "$_uvworkon_script_dir"
}

_uvworkon_list_envs() {
    _uvworkon_base_dir=$1
    printf 'available environments in %s:\n' "$_uvworkon_base_dir"

    _uvworkon_env_names=$(
        find "$_uvworkon_base_dir" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sort | while IFS= read -r _uvworkon_entry; do
            if [ -f "$_uvworkon_entry/bin/activate" ]; then
                basename -- "$_uvworkon_entry"
            fi
        done
    )

    if [ -z "$_uvworkon_env_names" ]; then
        printf '  no available uv virtual environments\n'
        return 0
    fi

    printf '%s\n' "$_uvworkon_env_names" | sed 's/^/  - /'
}

uvworkon() {
    _uvworkon_env_name=${1-}
    _uvworkon_script_dir=$(_uvworkon_resolve_home) || {
        echo "error: failed to resolve uvworkon home directory" >&2
        return 1
    }

    if [ -z "$_uvworkon_env_name" ]; then
        echo "usage: uvworkon <env_name>"
        echo
        _uvworkon_list_envs "$_uvworkon_script_dir"
        return 0
    fi

    _uvworkon_env_path=$_uvworkon_script_dir/$_uvworkon_env_name
    if [ ! -d "$_uvworkon_env_path" ]; then
        printf "error: virtual environment '%s' not found\n" "$_uvworkon_env_name" >&2
        echo
        _uvworkon_list_envs "$_uvworkon_script_dir"
        return 1
    fi

    _uvworkon_activate_script=$_uvworkon_env_path/bin/activate
    if [ ! -f "$_uvworkon_activate_script" ]; then
        printf "error: '%s' is not a valid uv virtual environment\n" "$_uvworkon_env_name" >&2
        echo "please ensure the directory contains bin/activate" >&2
        return 1
    fi

    . "$_uvworkon_activate_script"

    printf '[*] activated Python path: %s\n' "$VIRTUAL_ENV/bin/python"
    echo "[*] tip: use 'deactivate' command to exit virtual environment"
    echo "[*] ==============================="
}

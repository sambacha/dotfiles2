#!/bin/bash
dotfiles2::warn() { printf "%b[Warn]%b %s\n" '\e[0;33m' '\e[0m' "$@" >&2; }
dotfiles2::info() { printf "%b[Info]%b %s\n" '\e[0;32m' '\e[0m' "$@" >&2; }

printenv
exit 0

#!/usr/bin/env bash
# Shared logging helpers for bringup scripts. Source, don't execute.
# Mirrors the look of nish-ignition/scripts/lib.sh so the two layers read alike.

set -euo pipefail

BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BLUE=$'\e[34m'; RESET=$'\e[0m'

log()  { printf '%s\n' "${BLUE}==>${RESET} ${BOLD}$*${RESET}"; }
info() { printf '%s\n' "    $*"; }
ok()   { printf '%s\n' "${GREEN}    ✓${RESET} $*"; }
skip() { printf '%s\n' "${DIM}    ↷ $* (skip)${RESET}"; }
warn() { printf '%s\n' "${YELLOW}    !${RESET} $*"; }
err()  { printf '%s\n' "${RED}    ✗${RESET} $*" >&2; }

has_cmd() { command -v "$1" >/dev/null 2>&1; }

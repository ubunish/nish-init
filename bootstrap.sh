#!/usr/bin/env bash
# nish-init entrypoint — usable workstation → operational environment.
#
# Curl-able: this script self-clones nish-init, imports the workflow repos
# into ~/ubunish, clones fm-ros2 into ~/fm_ros2, runs the platform layer
# (nish-setup), then each repo's own installer. Safe to re-run: every step
# is idempotent.
#
#   curl -fsSL https://raw.githubusercontent.com/ubunish/nish-init/main/bootstrap.sh | bash

set -euo pipefail

# Where all repos clone. Override with UBUNISH_DIR for testing (mirrors
# nish-setup's CODE_DIR hook).
UBUNISH_DIR="${UBUNISH_DIR:-$HOME/ubunish}"

INIT_DIR="$UBUNISH_DIR/nish-init"
INIT_REPO="git@github.com:ubunish/nish-init.git"

# fm-ros2 lives in $HOME, not $UBUNISH_DIR: it is a standalone ROS 2 workspace
# that owns its own lifecycle, so it sits apart from the workflow repos and is
# cloned on its own rather than through the vcstool manifest. Override for tests.
FM_ROS2_DIR="${FM_ROS2_DIR:-$HOME/fm_ros2}"
FM_ROS2_REPO="git@github.com:Ubundi/fm-ros2.git"

# --- Bare logging until scripts/lib.sh exists ------------------------------
# The clone may not be present yet on a curl|bash run, so define minimal
# loggers up front and replace them with lib.sh once the clone is in place.
log()  { printf '==> %s\n' "$*"; }
err()  { printf '  x %s\n' "$*" >&2; }

# 1. require git — nothing works without it.
command -v git >/dev/null 2>&1 || { err "git is required but not installed"; exit 1; }

# 2. ensure a clone exists, then continue from it.
# When piped from curl there is no source file on disk, so clone into
# UBUNISH_DIR and re-exec from there. When already running inside a clone
# (the common manual path), skip the clone and stay put.
SELF="${BASH_SOURCE[0]}"
if [[ -f "$SELF" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SELF")" && pwd)"
else
  SCRIPT_DIR=""
fi

if [[ -z "$SCRIPT_DIR" || ! -f "$SCRIPT_DIR/repos.yaml" ]]; then
  # Not running from a clone (curl|bash). Clone, then hand off to the clone.
  mkdir -p "$UBUNISH_DIR"
  if [[ ! -d "$INIT_DIR/.git" ]]; then
    log "cloning nish-init into $INIT_DIR"
    git clone "$INIT_REPO" "$INIT_DIR"
  else
    log "nish-init already cloned at $INIT_DIR"
  fi
  log "re-executing from clone"
  exec bash "$INIT_DIR/bootstrap.sh" "$@"
fi

# From here on we are guaranteed to run inside the clone.
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/scripts/lib.sh"

# fm-ros2 ships a per-OS setup script; map uname to its naming.
OS_RAW="$(uname -s)"
case "$OS_RAW" in
  Darwin) OS="macos"  ;;
  Linux)  OS="linux"  ;;
  *) err "unsupported OS: $OS_RAW"; exit 1 ;;
esac

# _run_installer LABEL PATH ARG... — run a cloned repo's installer if present.
# A partial run (repo not yet cloned) warns instead of hard-failing, matching
# nish-setup's _delegate_contract behaviour.
_run_installer() {
  local label="$1" installer="$2"; shift 2
  if [[ -x "$installer" ]]; then
    log "$label: $installer $*"
    "$installer" "$@"
  else
    warn "installer not found (repo not cloned?): $installer"
  fi
}

log "nish-init → operational environment [$OS]"
info "Repos dir: $UBUNISH_DIR"
echo

# 3. import every repo (incl. nish-setup). vcs skips repos already present.
has_cmd vcs || { err "vcstool (vcs) is required but not installed"; exit 1; }
log "vcs import $UBUNISH_DIR < repos.yaml"
vcs import "$UBUNISH_DIR" <"$SCRIPT_DIR/repos.yaml"
ok "repos imported"
echo

# 3b. clone fm-ros2 on its own into $HOME (not the vcstool manifest, not
#     $UBUNISH_DIR). Idempotent: skip when the clone already exists.
if [[ ! -d "$FM_ROS2_DIR/.git" ]]; then
  log "cloning fm-ros2 into $FM_ROS2_DIR"
  git clone "$FM_ROS2_REPO" "$FM_ROS2_DIR"
else
  log "fm-ros2 already cloned at $FM_ROS2_DIR"
fi
echo

# 4. platform layer first — nish-setup turns the bare machine into a
#    usable workstation (packages, drivers, ROS, SSH).
_run_installer "nish-setup" "$UBUNISH_DIR/nish-setup/setup.sh"
echo

# 5. workflow installers via the {install|uninstall|status} contract (install).
#    fm-ros2 owns its own lifecycle and exposes only a per-OS setup script.
_run_installer "nish-ai"      "$UBUNISH_DIR/nish-ai/install.sh"      install
_run_installer "nish-aliases" "$UBUNISH_DIR/nish-aliases/install.sh" install
_run_installer "nish-tui"     "$UBUNISH_DIR/nish-tui/install.sh"     install
_run_installer "fm-ros2"      "$FM_ROS2_DIR/scripts/setup-$OS.sh"
echo

log "Done."

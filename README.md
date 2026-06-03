# nish-bringup

One `./bootstrap.sh` that takes a usable workstation to a fully operational
environment: clones every workflow repo into `~/ubunish`, runs the platform
layer, then each repo's own installer. Re-runnable from end to end.

## Layered Model

Setup is two layers. Ignition turns a bare machine into a usable workstation;
bringup turns that workstation into Nish's operational environment.

```
ignition   bare machine ──────────→ usable workstation     (packages, drivers, ROS, SSH)
                                                            [repo: ~/nish-ignition]
bringup    usable workstation ─────→ operational env        (clone + install workflow repos)
                                                            [this repo, runs ignition first]
```

bringup is the single front door. It owns repo cloning; ignition stays
platform-only.

## Call Flow

```
bootstrap.sh
  ├── require git
  ├── self-clone into ~/ubunish/nish-bringup   (only on curl|bash; re-exec from clone)
  ├── vcs import ~/ubunish < repos.yaml         clones all 5 repos (idempotent)
  ├── ignition:  ~/ubunish/nish-ignition/setup.sh          platform layer first
  └── workflow installers:
        nish-ai/install.sh install
        nish-aliases/install.sh install
        nish-tui/install.sh install
        fm-ros2/scripts/setup-<os>.sh           (install only — owns its lifecycle)
```

Each installer is optional on a partial run: a missing one warns rather than
hard-failing. `<os>` is `macos` or `ubuntu`, resolved from `uname -s`.

## Quick Start

Prerequisites: `git` and `vcstool` (`vcs`). SSH access to the `ubunish` org —
the ssh-key step in ignition must have run and the key be on GitHub before the
SSH clone urls in `repos.yaml` resolve.

Curl-able one-liner — clones bringup, then runs from the clone:

```bash
curl -fsSL https://raw.githubusercontent.com/ubunish/nish-bringup/main/bootstrap.sh | bash
```

Or clone and run manually:

```bash
git clone git@github.com:ubunish/nish-bringup.git ~/ubunish/nish-bringup
cd ~/ubunish/nish-bringup
./bootstrap.sh
```

Both paths are idempotent: `vcs import` skips repos already cloned, and each
installer skips work already done.

### Environment

| Variable | Effect |
|----------|--------|
| `UBUNISH_DIR=/path` | Override where repos clone (default `~/ubunish`) |

## repos.yaml Ownership

`repos.yaml` is bringup's vcstool manifest and the single source of truth for
what gets cloned into `~/ubunish`:

```
nish-ignition   platform layer (run first)
nish-ai         AI tooling + config
nish-tui        terminal UI
nish-aliases    shell aliases
fm-ros2         First Motive ROS 2 workspace
```

bringup owns this cloning. ignition has its own narrower manifest for the
platform layer and never reaches into the workflow repos.

## Layout

```
nish-bringup/
├── bootstrap.sh        curl-able entrypoint: clone → import → ignition → installers
├── repos.yaml          vcstool manifest for the 5 ~/ubunish repos
├── scripts/
│   └── lib.sh          logging helpers (mirrors nish-ignition's look)
├── LICENSE             Ubundi proprietary
└── plans/              planning notes (gitignored)
```

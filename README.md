# nish-init

One `./bootstrap.sh` that takes a usable workstation to a fully operational
environment: clones the workflow repos into `~/ubunish`, clones `fm-ros2` into
`~/fm_ros2`, runs the platform layer, then each repo's own installer.
Re-runnable from end to end.

## Layered Model

Setup is two layers. nish-setup turns a bare machine into a usable workstation;
nish-init turns that workstation into Nish's operational environment.

```
nish-setup   bare machine ──────────→ usable workstation     (packages, drivers, ROS, SSH)
                                                            [repo: ~/ubunish/nish-setup]
nish-init    usable workstation ─────→ operational env        (clone + install workflow repos)
                                                            [this repo, runs nish-setup first]
```

nish-init is the single front door. It owns repo cloning; nish-setup stays
platform-only.

## Call Flow

```
bootstrap.sh
  ├── require git
  ├── self-clone into ~/ubunish/nish-init      (only on curl|bash; re-exec from clone)
  ├── vcs import ~/ubunish < repos.yaml         clones the 4 workflow repos (idempotent)
  ├── clone fm-ros2 into ~/fm_ros2              standalone (idempotent)
  ├── nish-setup:  ~/ubunish/nish-setup/setup.sh          platform layer first
  └── workflow installers:
        nish-ai/install.sh install
        nish-aliases/install.sh install
        nish-tui/install.sh install
        ~/fm_ros2/scripts/setup-<os>.sh         (install only — owns its lifecycle)
```

Each installer is optional on a partial run: a missing one warns rather than
hard-failing. `<os>` is `macos` or `ubuntu`, resolved from `uname -s`.

## Quick Start

Prerequisites: `git` and `vcstool` (`vcs`). SSH access to the `ubunish` org —
the ssh-key step in nish-setup must have run and the key be on GitHub before the
SSH clone urls in `repos.yaml` resolve.

Curl-able one-liner — clones nish-init, then runs from the clone:

```bash
curl -fsSL https://raw.githubusercontent.com/ubunish/nish-init/main/bootstrap.sh | bash
```

Or clone and run manually:

```bash
git clone git@github.com:ubunish/nish-init.git ~/ubunish/nish-init
cd ~/ubunish/nish-init
./bootstrap.sh
```

Both paths are idempotent: `vcs import` skips repos already cloned, and each
installer skips work already done.

### Environment

| Variable | Effect |
|----------|--------|
| `UBUNISH_DIR=/path` | Override where the workflow repos clone (default `~/ubunish`) |
| `FM_ROS2_DIR=/path` | Override where `fm-ros2` clones (default `~/fm_ros2`) |

## repos.yaml Ownership

`repos.yaml` is nish-init's vcstool manifest and the single source of truth for
what gets cloned into `~/ubunish`:

```
nish-setup      platform layer (run first)
nish-ai         AI tooling + config
nish-tui        terminal UI
nish-aliases    shell aliases
```

`fm-ros2` is not in the manifest. As a standalone ROS 2 workspace that owns its
own lifecycle, it lives in `~/fm_ros2` and bootstrap.sh clones it on its own.

nish-init owns this cloning. nish-setup has its own narrower manifest for the
platform layer and never reaches into the workflow repos.

## Layout

```
nish-init/
├── bootstrap.sh        curl-able entrypoint: clone → import → nish-setup → installers
├── repos.yaml          vcstool manifest for the 4 ~/ubunish workflow repos
├── scripts/
│   └── lib.sh          logging helpers (mirrors nish-setup's look)
├── LICENSE             Ubundi proprietary
└── plans/              planning notes (gitignored)
```

# Runbook: Migrate Loose Repos to `~/ubunish`

One-time migration for a machine whose workflow repos were cloned loose in the
home directory, before `nish-bringup` owned the layout. On a fresh machine this
is unnecessary — `bootstrap.sh` clones everything into `~/ubunish` directly.

## Why

`bootstrap.sh` and `repos.yaml` expect the workflow repos side by side under
`~/ubunish`. `fm-ros2` is the exception: as a standalone ROS 2 workspace it lives
in `~/fm_ros2`, not under `~/ubunish`.

```
~/ubunish/
├── nish-bringup
├── nish-ignition
├── nish-ai
├── nish-aliases
└── nish-tui

~/fm_ros2          (standalone — not under ~/ubunish)
```

A machine set up earlier has these loose in `$HOME`. Move the workflow repos in;
leave fm-ros2 in `$HOME` under the `fm_ros2` name.

## Procedure

```bash
mkdir -p ~/ubunish
mv ~/nish-ignition ~/nish-ai ~/nish-tui ~/nish-aliases ~/nish-bringup ~/ubunish/
mv ~/fm-ros2 ~/fm_ros2          # stays in $HOME, renamed to underscore
```

Moving a git checkout is safe: git stores paths relative to the repo root, so
history, branches, and the working tree survive a directory move untouched.

## Relink Claude assets

`nish-ai/install.sh` symlinks skills and commands into `~/.claude` using the
repo's absolute path. The move dangles those links. Re-run the installer from
the new location to repoint them:

```bash
bash ~/ubunish/nish-ai/install.sh install
```

It backs up any conflicting entry and relinks every skill and command to the new
`~/ubunish/nish-ai/...` path. Verify:

```bash
ls -l ~/.claude/skills | grep ubunish   # targets now under ~/ubunish
```

## Other repo-path references

| Source | Hardcodes a repo path? | Action |
|--------|------------------------|--------|
| `~/.claude/skills`, `~/.claude/commands` | yes — symlinks into `nish-ai` | relink via installer above |
| `nish-aliases` shell source line in `~/.zshrc` / `~/.bashrc` | yes if installed | re-run `nish-aliases/install.sh` to rewrite the source line |
| `uv` tools (`nish-tui`) | no — installed from a built wheel, not the repo path | none |

After the move, open a new shell so any rewritten rc lines take effect.

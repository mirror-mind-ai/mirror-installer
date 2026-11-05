# What the Windows installer relies on

The installer is a bootstrapper: it puts a known-good `mirror-mind` on a
Windows machine and leaves. From then on the core updates itself
(`/mm-update` → `mirror runtime update`); the installer is never in the
core's path, and the core never waits for it. This file lists what the
installer reads from the core, so that a change on either side is a known
event rather than a surprise. It is extracted from `install.ps1` and the two
launchers; `tests/contract.ps1` asserts every line of it.

**Pinned:** `mirror-mind@0.39.3` (installer 2.0.1), the first core release in
which every Windows fix the installer needed has landed: Claude Code's hooks
and the plugin's MCP server run the package's own bin when npm's global entry
is a shell shim ([mirror#53](https://github.com/mirror-mind-ai/mirror/pull/53);
on 0.39.0 every hook ended `node exited 1` on a Windows package install),
`runtime diagnose` reads the PATH the platform's way and no longer counts its
own verdict as an error ([mirror#49](https://github.com/mirror-mind-ai/mirror/pull/49),
[mirror#50](https://github.com/mirror-mind-ai/mirror/pull/50)), and stdin is
decoded by its mark (CR194). The contract passed 35/35 with
`-ThenUpdateToLatest` on 2026-11-03. Installer 2.0.0 pinned 0.39.0, the first
release a Windows install can update itself from (`runtime update` used to fail
with npm `EBUSY`; [mirror#46](https://github.com/mirror-mind-ai/mirror/pull/46),
CR189). Git 2.56.0.2; Pi and Node are installed at their latest.

**The update path, for real:** on 2026-11-02 `latest` moved to 0.39.1, and
`-ThenUpdateToLatest` took an install of the pin from 0.39.0 to 0.39.1 on
Windows (`runtime update` exit 0, the contract 35/35 after it): the first
update a Windows install of this layout applied by itself. 0.39.1 changes the
Pi extension only (it finds Node as the hook wrappers do, CR191; the installer
sets both `PATH` and `MIRROR_NODE`), and installed users take each release
through `runtime update`. On 2026-11-04 the same path took an install of the
0.39.3 pin to 0.39.4 (Claude Code replies kept for queued prompts and
journey switches, `logger.ts` only), 35/35 after it; the pin stays at 0.39.3.
On 2026-11-05 it took the pin to 0.39.5 (CR192: every reader of `MIRROR_NODE`
uses it only as an absolute path to an executable file, the installer's
`…\Programs\MirrorMind\node\node.exe` included, and names a refused value in
`hooks.log`), 35/35 after it. The installer's form was checked against that
rule on Windows before the tag.

**The contract also held, unchanged, against** `mirror-mind` 0.35.0, 0.36.0,
0.36.2, 0.37.0 (migration 018 applies on first open), 0.38.0 and 0.38.1
(`init` adopts an existing home; commands that need a key refuse in one line
without it, none of them on the installer's path). Before 0.39.0 the pin stayed
at 0.33.4, because no release in between could update itself on Windows.

**Pi install model:** the installer puts Pi in through `npm install -g
@earendil-works/pi-coding-agent`. Since Pi 1.4.0, `pi update` on such an
install prints a hint to migrate to Pi's own managed installer
(`irm https://pi.dev/install.ps1 | iex`), which pins Pi's dependencies. Not
adopted here yet: it would move Pi out of the npm prefix the launchers and this
contract assume. To evaluate before an installer release. Also observed on
2026-10-22: `pi update` with a Pi session open ends with `npm warn cleanup
EPERM` on a `.node` file the open session holds -- the update itself succeeds,
only a `.pi-coding-agent-<id>` leftover stays under `node_modules/@earendil-works`;
close Pi, delete it.

## Commands the installer runs

| Command | Expects | Used for |
|---|---|---|
| `mirror runtime version` | exit 0; a line `Version: <semver>` | records the installed core version |
| `mirror init <key>` | exit 0; creates `~/.mirror-minds/<key>/` (since 0.38.1 an existing one is adopted unchanged); first stdout line is a summary | the identity home. `<key>` is kebab-case (`[a-z0-9-]`, CR141); the installer derives it from what the person types |
| `mirror seed` | exit 0; last stdout line is a summary (`Result: N created, …`) | the twelve personas, the journey |
| `mirror runtime status` | exit 0; lines `Version:`, `Install:`, `Database exists:`, `Core migrations:` | the verify step; `mirror-status.cmd` |
| `mirror welcome` | exit 0 | warms the welcome card; proves the database opens |
| `mirror runtime diagnose` | exit 0 or 1 (findings) | `mirror-status.cmd` only; output not parsed |
| `pi install <dir>` | exit 0 | registers the package's `.pi/skills` and `.pi/extensions` with Pi |
| `pi --version` | exit 0 | the transcript |

Any other `mirror` subcommand is the user's, not the installer's.

## Files and variables the installer writes, the core reads

| What | Where | Format |
|---|---|---|
| Mirror config | `%USERPROFILE%\.config\mirror\env` | UTF-8, no BOM; `MIRROR_USER=<key>` and `OPENROUTER_API_KEY=sk-or-…`; other lines preserved |
| Node for hooks | user env `MIRROR_NODE` | `<app>\node\node.exe` — the repair route `runtime diagnose` names |
| OpenRouter key | user env `OPENROUTER_API_KEY` | also read back from `HKCU\Environment` by `mirror.cmd` for windows opened before the install |
| PATH | user env `Path` | `<app>\node` prepended (`mirror.cmd`, `pi.cmd`, `node.exe` live there) |
| Pi settings | `%USERPROFILE%\.pi\agent\settings.json` | UTF-8, no BOM; keys `defaultProvider` (`openrouter`), `defaultModel` (`~anthropic/claude-sonnet-latest`), `shellPath` (`<app>\git\bin\bash.exe`); other keys preserved |
| Workspace | `%USERPROFILE%\Mirror\` | the folder Pi opens in; Pi keys its sessions by it |

## Package layout the installer assumes

- `npm install -g mirror-mind` puts `mirror.cmd` and `mirror-hook.cmd` in the npm prefix (`<app>\node`) and the package at `<app>\node\node_modules\mirror-mind`.
- That package directory carries `.pi/skills/mm-*/SKILL.md` and `.pi/extensions/*.ts`, which `pi install <dir>` registers. (`package.json` `files` includes `.pi/extensions` and `.pi/skills`.)
- The core's runtime hooks and the Pi extension start Node by name or via `MIRROR_NODE`; `<app>\node` is on the user PATH and `MIRROR_NODE` points at it.

## Not relied on

- The text of any message, beyond the lines named above.
- The database schema, migrations, or file layout under `~/.mirror-minds/<key>/` (the core owns it; the installer only checks `Database exists: yes`).
- Any Python.

## When this changes

- **The core changes one of these** (a new `init` rule, a renamed status line, a moved config file): the daily canary (the `contract` job of `.github/workflows/installer.yml`, against `mirror-mind@latest`) turns red; the installer is fixed and a new `.exe` released. The core does not wait.
- **The installer needs something new from the core**: a separate, small PR against the core ([mirror-mind-ai/mirror](https://github.com/mirror-mind-ai/mirror)), through its own CI — never a change here that reaches into the core. See `README.md`, "the installer consumes the core".

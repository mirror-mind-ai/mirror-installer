# Mirror Mind — Windows installer (technical)

A single per-user `.exe` (no UAC) that gives a Windows user a working Mirror
in one pass: Node.js, Git Bash (Pi's shell), Pi, `mirror-mind`, an identity,
the seeded personas, OpenRouter as the one account for chat and memory, and a
Start Menu / Desktop shortcut that opens Pi inside the Mirror workspace.

The person-facing page is the [repository README](../README.md). This file is
for whoever builds, tests or changes the installer.

## The rule: the installer consumes the core, it does not change it

This repository is Windows-only tooling — PowerShell, Inno Setup, `.cmd`
launchers, a Sandbox harness, icon assets — around a published package. It
installs `mirror-mind` from npm at a pinned version, the way any user would,
and the core ([mirror-mind-ai/mirror](https://github.com/mirror-mind-ai/mirror))
carries nothing of it. A core release never waits on the installer.

So the installer may change freely — **as long as it stays on its side of the
line**:

- It calls `mirror`, `pi` and `npm` the way any user would (`mirror init`,
  `mirror seed`, `pi install <pkg>`, `mirror runtime status`). It does not
  patch, wrap or reach into the package's code.
- When it *needs* something from the core — a flag, an output format, a
  behavior — that is a **separate, small PR against the core**, through the
  core's own CI and review, and labeled as a core change.
  [mirror#42](https://github.com/mirror-mind-ai/mirror/pull/42) (install-kind
  detection under a non-ASCII path),
  [mirror#43](https://github.com/mirror-mind-ai/mirror/pull/43) (Notepad
  default behind `platform === "win32"`) and
  [mirror#46](https://github.com/mirror-mind-ai/mirror/pull/46) (`runtime
  update` on Windows) are the pattern: platform-conditional where the behavior
  is platform-specific, platform-neutral bug fixes otherwise.
- Almost every bug the Sandbox found (code page in a `.cmd`, ANSI vs UTF-8 in
  files we write, `npm prefix` read back in the wrong encoding) was on this
  side. The core handled `mirror init "João Çãõ"`, `seed`, `pi install` and
  `runtime status` under an accented path unchanged. Keep that bar: fix the
  installer first; suspect the core last, and prove it with a reproduction
  outside the installer before proposing a core change.

What the installer relies on from the core, line by line, is
[CONTRACT.md](CONTRACT.md); why it is built the way it is, is
[DECISIONS.md](DECISIONS.md).

## Layout

| Path | What |
|---|---|
| `mirror.iss` | Inno Setup script: wizard pages, identity page (name + OpenRouter key, PT/EN), phases, uninstall |
| `install.ps1` | The work: `-Phase bootstrap` (Node, Git, Pi, mirror-mind) and `-Phase configure` (key, env, init, seed, `pi install`, Pi settings, workspace, verify) |
| `build.ps1` | Compiles the `.exe` with the pinned core (`-OutputSuffix -bN` when iterating, `-OutputDir` when `dist` is held open) |
| `VERSION`, `MIRROR_VERSION` | The installer's own version, and the `mirror-mind` version it was tested against and installs |
| `launcher/` | `mirror.cmd` (opens Pi in `%USERPROFILE%\Mirror`) and `mirror-status.cmd` |
| `assets/` | `mirror.ico` (octahedron, rendered by `build-icon.ps1`), wizard bitmaps |
| `tests/contract.ps1` | The contract with the core, run in a throwaway prefix and home |
| `sandbox/` | Windows Sandbox harness: `start.ps1` (clean) and `start.ps1 -PerfilPT` (simulated `C:\Users\João Çãõ Silva`, `/LANG=pt`); logs land in `out\sandbox` as they are written |
| `video/` | The installation video: script (`roteiro-pt.md`), Sandbox capture, narration, assembly |

## Rules learned the hard way (all Windows, all on this side)

- **No `chcp` inside a `.cmd`.** A code page change mid-batch makes `cmd`
  re-read the file with the new one; accented paths turn to garbage. The
  wizard starts `powershell.exe` directly.
- **Only strings PowerShell produced itself are reused as paths.** PowerShell
  5.1 decodes native output (npm, pi, mirror) in the OEM code page; `npm
  prefix -g` came back as `Jo+ão`. The script knows its own paths; it does not
  ask the tools for them.
- **Every text file written for another program goes through `WriteUtf8`**
  (UTF-8, no BOM). `Set-Content` on 5.1 is ANSI; `-Encoding UTF8` adds a BOM
  that becomes part of the first key. Our own files are read back with
  `-Encoding UTF8` too.
- **The name the person types becomes a key.** Since mirror-mind 0.33.4
  (CR141) a user name is lowercase letters, digits and single hyphens: it goes
  into a path and into `MIRROR_USER`. The page accepts anything — "João Çãõ"
  — and shows the key it becomes (`joao-cao`) under the field before Next.
- **A build installs the core it was tested against.** `build.ps1` bakes
  `MIRROR_VERSION` unless told otherwise; `latest` is for development only. A
  core release once changed `init` between two Sandbox runs a night apart, and
  CI checks that the silent install reports the pinned version.
- **Open the .exe once on the host before it goes to `dist`.** It costs five
  seconds and catches every InitializeWizard error ("Could not call proc"
  reached a tester once). Nothing is installed until Install is clicked.
- **Test under the PT profile, not only the clean Sandbox.** The Sandbox's own
  user is `WDAGUtilityAccount`: ASCII, no space. Every encoding bug above was
  invisible there and immediate under `João Çãõ Silva`.

## Build and test

```powershell
installer\build.ps1                       # -> dist\MirrorMind-Setup-<VERSION>.exe, with MIRROR_VERSION
installer\tests\contract.ps1              # the contract against MIRROR_VERSION (-ThenUpdateToLatest as CI runs it)
installer\sandbox\start.ps1 -PerfilPT     # by hand; or without -PerfilPT for the clean profile
installer\video\record-frames.ps1 -PerfilPT   # the same check, unattended (OPENROUTER_API_KEY set)
installer\assets\build-icon.ps1           # regenerate mirror.ico and the wizard images
```

`start.ps1` renders the Sandbox configuration for this checkout into `out\`
and starts it. The harness runs the setup, mirrors `install-detail-*.log` to
`out\sandbox` line by line, writes `report.json` when the setup closes, and
offers to open Mirror from the same window. The end-to-end check is `listar
minhas personas` inside Pi: twelve names means Node, Git Bash, Pi, mirror, the
skill and the database all agree. The release checklist is
[TESTING.md](TESTING.md).

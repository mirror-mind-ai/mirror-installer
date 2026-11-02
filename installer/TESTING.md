# Testing the Windows installer

Three layers, from cheapest to most faithful. The core is never waiting on
any of them: they tell the installer when to follow a core release, not the
other way round.

| Layer | What | Where | When | Time |
|---|---|---|---|---|
| **Contract** | `tests/contract.ps1`: the commands `install.ps1` runs, against a core version, in a throwaway prefix and home; then `runtime update` to latest and the same checks again. Asserts [CONTRACT.md](CONTRACT.md) line by line. | host or `windows-latest` | every change under `installer/`; **daily against `mirror-mind@latest`** (the canary) | ~1 min |
| **Build check** | compile the `.exe`, open it once (InitializeWizard runs; nothing installs) | `windows-latest` | every change under `installer/` | ~2 min |
| **End to end** | Windows Sandbox: `sandbox/start.ps1` (clean) and `sandbox/start.ps1 -PerfilPT` (profile `C:\Users\João Çãõ Silva`, `/LANG=pt`); wizard, Finished-page checkbox opens Mirror, `listar minhas personas` answers with twelve names | a Windows machine with the Sandbox feature; someone at the keyboard, or unattended: `video/record-frames.ps1` (clean profile, the video's run) and `video/record-frames.ps1 -PerfilPT` (accented profile; writes `out\sandbox\perfil-pt\report.json` and `runtime-status.txt`). Both need `OPENROUTER_API_KEY` and the Sandbox window left alone | before an installer release; when the canary turns red | ~5 min each |

## What each layer catches

- Contract: a core release that changes `init`, `seed`, a `runtime status`
  line, the config file, the package layout. This is what v0.33.4 did (a user
  name became a key) between two Sandbox runs a night apart.
- Build check: a PascalScript error in the wizard ("Could not call proc"
  reached a tester once; it is a five-second check).
- Sandbox: everything the other two cannot see -- the wizard's pages, the
  code page of a `.cmd`, the PATH a window inherits, a launcher that forgets
  `call`, the `[Run]` entry Inno evaluates before the identity page exists.
  Almost every bug the Sandbox found was on the installer's side; see `README.md`.

## When the canary is red

1. Read the failing check; it names the CONTRACT.md line.
2. Fix the installer (or, if the installer needs something the core no longer
   offers, open a small PR against the core,
   [mirror-mind-ai/mirror](https://github.com/mirror-mind-ai/mirror) -- never a
   change here that reaches into the package).
3. `tests/contract.ps1 -MirrorVersion <new core>` green → both Sandbox
   profiles green → bump `MIRROR_VERSION` (and `VERSION`) → release.

## Releasing

1. `MIRROR_VERSION` = the core version both Sandbox profiles passed against.
2. `VERSION` bumped; `docs/releases/v<VERSION>.md` written (core version,
   the SmartScreen note, the video).
3. Tag `v<VERSION>`; `.github/workflows/release.yml` runs the contract, builds
   the `.exe` with the pinned core and leaves it, with `SHA256SUMS`, as a
   workflow artifact.
4. The maintainer creates the GitHub Release from that artifact (the commands
   are at the top of `release.yml`), and attaches the video. The `.exe` is not
   in git.

## Not here

- Core behavior: the core's own suite (`ubuntu-latest`, `macos-latest`).
- The video: `video/` is reproducible from the Sandbox frames and the
  roteiro (`record-frames.ps1`, then `narrar.py`, then `gravar.py`); the `.mp4`
  is a release asset, not a test, and not in git.

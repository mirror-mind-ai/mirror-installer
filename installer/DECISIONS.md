# Why the installer is built this way

Each entry is a decision, the reason it was taken, and what follows from it.
Most were forced by something a Windows Sandbox run showed; where that is the
case, the run is named. The installer was developed as
[mirror-mind-ai/mirror#45](https://github.com/mirror-mind-ai/mirror/pull/45),
whose commits carry the full trail, and moved to this repository when the core
and the installer were separated.

## Shape

**A bootstrapper over the npm package, not a clone and not an app.** The first
Windows installer ([mirror#26](https://github.com/mirror-mind-ai/mirror/pull/26),
v0.30.0) cloned the repository and installed Git, Node, uv and Pi; the core
retired it with the Python core in v0.32.0. The desktop frame that came with it
installed a GUI nobody used: what people use is Pi with the Mirror skills. So
this installer puts a known-good `mirror-mind` from npm on the machine, with
what Pi needs, and leaves. From then on the core updates itself (`/mm-update`,
`mirror runtime update`); the installer is never in the core's path.

**Per user, no administrator password.** Everything lands under
`%LOCALAPPDATA%\Programs\MirrorMind`; the identity under
`~/.mirror-minds/<key>`; Pi opens in `~/Mirror`. Uninstalling removes the
program and its PATH entries, never the person's data. The Desktop shortcut is
always created: for this audience "where did it go?" costs more than one icon.

**Two phases.** `bootstrap` (Node, Git Bash, Pi, mirror-mind) runs on the
Installing page, before the person is asked anything; `configure` (key, config
file, `init`, `seed`, `pi install`, Pi settings) runs after the identity page.
The slow, failure-prone part happens while the person waits anyway, and a
silent install can run `bootstrap` alone.

## What it installs

**Node 24 as a per-user zip, checked against the release's SHASUMS256.** A
zip-installed Node's npm prefix is its own folder: one tree, already on PATH.
Every npm call sets `npm_config_prefix` to that folder, and so do the
launchers: a GitHub runner sets `NPM_CONFIG_PREFIX`, and so does anyone who
followed a "fix npm permissions" guide, and either would put `mirror` where the
launcher never looks.

**Git for Windows, portable and pinned, as Pi's shell.** The first clean
Sandbox run reached the welcome card, and then every `mm-*` skill failed: Pi's
bash tool needs `bash.exe`, and a clean Windows has none. The first installer
never met this because it installed all of Git for the clone. PortableGit is
extracted beside Node and named in Pi's settings as `shellPath`; its SHA-256 is
the one the Git release page publishes.

**OpenRouter as the one account, for chat and for memory.** One key, validated
once against the OpenRouter API, goes to Mirror's config file and to Pi as its
startup provider, so the first launch needs no `/login`. Without a default
model Pi picked the first OpenRouter model it found, which spent 46k tokens
guessing at the filesystem; the default is now `~anthropic/claude-sonnet-latest`.
Anyone with their own Claude or OpenAI subscription switches in Pi afterwards;
the happy path asks for one key.

## The person's name

**The name typed becomes the key the core wants.** Since mirror-mind 0.33.4
(CR141) a user name is lowercase letters, digits and single hyphens, because it
becomes a folder and `MIRROR_USER`. The page still asks "what should Mirror
call you?", accepts "João Çãõ", and shows the key it becomes (`joao-cao`) as it
is typed, so the welcome card's name is no surprise.

## Windows encodings

**Tested under a Brazilian profile, not only the Sandbox's own user.** The
Sandbox user is `WDAGUtilityAccount`: ASCII, no space. The harness also runs
the setup under a simulated `C:\Users\João Çãõ Silva` with `/LANG=pt`, and
every encoding bug below was invisible in one and immediate in the other:

- the bootstrap phase ran through a `.cmd` that began with `chcp 65001`, and a
  code page change inside a batch makes `cmd` re-read the rest of the file:
  the accented path became garbage and the wizard waited out its 30 minutes.
  The wizard now starts `powershell.exe` itself;
- `npm prefix -g` came back as `Jo+ão`, because PowerShell 5.1 decodes native
  output in the OEM code page, and went into the user PATH. Only strings
  PowerShell produced itself are reused as paths;
- the config file and Pi's `settings.json` were written as ANSI by
  `Set-Content`, and `-Encoding UTF8` would have added a BOM that becomes part
  of the first key. One helper writes every file another program reads: UTF-8
  without BOM.

## Launchers

**`call` the npm shims.** Under the Brazilian profile Mirror opened in
`C:\Windows\System32` without Node on PATH. `pi.cmd` ends with a `goto` to a
missing label, which ends the batch context; chained without `call`, it also
undid the launcher's `setlocal`. From a fresh Desktop shortcut this was
invisible, because Explorer already had the new PATH.

**The key from the registry when the window lacks it.** A window opened before
the install finished does not carry the `OPENROUTER_API_KEY` the installer
wrote to the user environment, and Pi started from it had no provider.

**`MIRROR_NODE` points at the install's own Node.** It is the repair route
`mirror runtime diagnose` names, and it keeps the core's hooks independent of
the rest of the PATH.

## Following the core

**A pinned core version, a written contract, a daily canary.** `MIRROR_VERSION`
is the `mirror-mind` version the installer was tested against, and the one the
`.exe` installs. [CONTRACT.md](CONTRACT.md) lists what the installer reads from
the core (eight commands, the lines it parses, the files it writes, the package
layout); `tests/contract.ps1` asserts it in a throwaway prefix and home, then
runs `runtime update` and asserts again. CI runs it on every change and daily
against `mirror-mind@latest`: red means a core release changed something the
installer reads. The core never waits for the installer; the canary tells the
installer when to follow.

**The pin stayed at 0.33.4 until 0.39.0.** Every core release in between
failed to update itself on Windows: npm renames the package's folder aside
before installing the new one, and Windows refuses to rename a folder a process
is running in (`EBUSY`). Shipping one of those would have stranded the person
on the version the installer brought. The fix went to the core as its own PR
([mirror#46](https://github.com/mirror-mind-ai/mirror/pull/46), CR189) and
shipped in 0.39.0, the first version a Windows install can update from.

**A build bakes the pin, and CI checks it.** `build.ps1` reads
`MIRROR_VERSION` unless told otherwise; `latest` is for development. A core
release once changed `init` between two Sandbox runs a night apart. The CI's
silent install fails if the `.exe` installs a core other than the pin.

**What the installer needs from the core goes to the core as a separate PR.**
Install-kind detection under a non-ASCII path
([mirror#42](https://github.com/mirror-mind-ai/mirror/pull/42)), Notepad as
the Windows editor ([mirror#43](https://github.com/mirror-mind-ai/mirror/pull/43))
and the update fix were each a small core change with its own review, never
something this repository patches around.

## Testing and releasing

**The build check installs for real.** A GitHub runner has no interactive
desktop, so looking at the wizard's window proved nothing. The CI runs the
`.exe` with `/VERYSILENT`: the wizard's script initializes (an error aborts),
and the bootstrap phase downloads and installs everything on the runner. In
silent mode the wizard never shows a message box (none would be answered), and
the identity page is skipped unless `/NAME` and `/KEYFILE` are given.
`/KEYFILE` rather than `/KEY`: Inno writes the command line into its log.

**A person publishes the release.** The release workflow runs the contract and
builds the `.exe`, and stops there; the maintainer creates the GitHub Release
from its artifact, after both Sandbox profiles pass. The `.exe` is never in
git.

**Not code-signed yet.** SmartScreen warns on first downloads, and the release
notes say what to click. Signing (Azure Trusted Signing) is a later decision.

**A separate repository.** The installer is Windows-only tooling, and the core
deliberately carries none: its CI runs on Ubuntu and macOS, and its own tests
forbid PowerShell and Inno Setup in its tree. In its own repository the
installer can release on its own cadence, and its releases do not compete with
the core's for "latest".

## The video

**Real frames, narrated.** The walkthrough is assembled from a real
installation in Windows Sandbox (`video/record-frames.ps1` drives it, under a
fictional user, Helena), not from a screen recording of someone's machine. The
OpenRouter key is written into the Sandbox for the run only, shown masked, and
deleted at the end. Pronunciation help lives only in the speech; the subtitles
keep the script's spelling. Sentences that exist in both Portuguese and Spanish
("listar minhas personas") are avoided in the speech, because the voice picks
the language by phrase: the speech asks, the screen shows the command.

# Mirror Mind for Windows

One `.exe` that gives a Windows user a working
[Mirror Mind](https://github.com/mirror-mind-ai/mirror): no administrator
password, nothing to install by hand, about five minutes.

It puts Node.js, Git Bash, [Pi](https://pi.dev) and `mirror-mind` on the
machine for your user only, asks two things — what Mirror should call you and
an OpenRouter key — and opens Mirror in Pi. The wizard speaks Portuguese and
English, and works under user folders with accents and spaces.

## Install

1. Download `MirrorMind-Setup-<version>.exe` from the
   [latest release](https://github.com/mirror-mind-ai/mirror-installer/releases/latest).
   `SHA256SUMS` beside it lets you check the file.
2. The `.exe` is not code-signed yet. On the first download Windows may show
   "Windows protected your PC": click **More info → Run anyway**.
3. Click **Install** and wait while it prepares Node, Git and Pi.
4. At "Almost there", type your name and paste an
   [OpenRouter key](https://openrouter.ai/keys) (`sk-or-…`; the button on the
   page opens it). The account needs some credit — five dollars, for example.
5. Finish with "Open Mirror Mind" checked, and ask it something.

A narrated walkthrough in Portuguese is attached to each release.

## What it does, and what it leaves alone

- Installs under `%LOCALAPPDATA%\Programs\MirrorMind`; your Mirror lives in
  `%USERPROFILE%\.mirror-minds\<your-name>`; Pi opens in `%USERPROFILE%\Mirror`.
- Uses one OpenRouter account for both the conversation and Mirror's memory.
  Claude or OpenAI accounts can be added later in Pi.
- Uninstalling removes the program, not your Mirror: `.mirror-minds`,
  `.config\mirror`, `.pi` and `Mirror` stay.

## Updating

The installer does not update Mirror; Mirror does. Inside Pi, `/mm-update` (or
`mirror runtime update` in a terminal) brings the core forward. A new installer
is released only when the core changes something the installer depends on.

## For developers

How it is built, tested and released, and why it is built that way:

- [installer/README.md](installer/README.md) — layout, build, the Windows rules
- [installer/DECISIONS.md](installer/DECISIONS.md) — the decisions and their reasons
- [installer/CONTRACT.md](installer/CONTRACT.md) — what the installer relies on from the core
- [installer/TESTING.md](installer/TESTING.md) — the three test layers and the release checklist

Changes to Mirror itself belong in
[mirror-mind-ai/mirror](https://github.com/mirror-mind-ai/mirror).

## License

MIT — see [LICENSE](LICENSE).

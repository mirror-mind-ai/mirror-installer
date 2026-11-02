# Installer assets

- `mirror.ico` — the product's diamond sign as an octahedron, violet to
  indigo, no background plate. Nine sizes (16–256): DIB entries up to 64 px so
  every reader (Inno included) accepts it, PNG at 128 and 256.
- `wizard-small.bmp` / `wizard-small-200.bmp` — the wizard's top-right image
  at 100% and 200% DPI, same octahedron on white.
- `wizard-large.bmp` / `wizard-large-200.bmp` — the welcome and finish page
  image (the octahedron and its reflection on indigo), at 100% and 200% DPI.
- `wizard-banner.bmp` — the 900×300 banner at the top of the identity page: a
  crop of the hero illustration in the core's README
  (`docs/assets/mirror-mind-contractor-team-1200px.jpg` in
  [mirror-mind-ai/mirror](https://github.com/mirror-mind-ai/mirror)).
- `mirror-256.png` — preview for READMEs.

The icon and the octahedron images are generated: run `build-icon.ps1` after
changing the shape or palette; do not hand-edit the binaries.

<#
.SYNOPSIS
    Render a Windows Sandbox template (*.wsb.template) into out\, with this
    checkout's path in place of {{REPO}}, and return the .wsb path.
.DESCRIPTION
    Windows Sandbox only takes absolute host folders, so a .wsb in the
    repository would name one person's checkout. The templates carry
    {{REPO}}; the rendered .wsb lands in out\ (ignored by git), next to
    out\sandbox, the folder the Sandbox writes its logs and frames into.
#>
param([Parameter(Mandatory)][string]$Template)
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$out = Join-Path $repo "out"
New-Item -ItemType Directory -Force (Join-Path $out "sandbox") | Out-Null
$text = [IO.File]::ReadAllText((Resolve-Path $Template).Path).Replace("{{REPO}}", $repo)
$dest = Join-Path $out ((Split-Path $Template -Leaf) -replace "\.template$", "")
[IO.File]::WriteAllText($dest, $text, (New-Object Text.UTF8Encoding $false))
$dest

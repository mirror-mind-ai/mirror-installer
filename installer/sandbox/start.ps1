<#
.SYNOPSIS
    Start a clean Windows Sandbox with the built .exe, for the manual check
    before a release.
.DESCRIPTION
    Build first (installer\build.ps1 writes dist\). The Sandbox maps dist\
    read-only and writes setup.log, the installer's detail log and
    report.json back into out\sandbox. -PerfilPT runs it under a simulated
    Brazilian user folder with the Portuguese wizard. See installer\TESTING.md.
#>
param([switch]$PerfilPT)
$ErrorActionPreference = "Stop"
$name = if ($PerfilPT) { "MirrorSetup-PerfilPT.wsb.template" } else { "MirrorSetup.wsb.template" }
$wsb = & (Join-Path $PSScriptRoot "New-SandboxConfig.ps1") -Template (Join-Path $PSScriptRoot $name)
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not (Get-ChildItem (Join-Path $repo "dist\MirrorMind-Setup-*.exe") -ErrorAction SilentlyContinue)) {
    throw "no dist\MirrorMind-Setup-*.exe: run installer\build.ps1 first"
}
Get-ChildItem (Join-Path $repo "out\sandbox") -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
Start-Process "WindowsSandbox.exe" -ArgumentList "`"$wsb`""
Write-Host "Sandbox starting from $wsb; logs land in $(Join-Path $repo 'out\sandbox')"

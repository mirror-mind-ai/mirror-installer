<#
.SYNOPSIS
    Install Mirror Mind for Windows from PowerShell:

        irm https://raw.githubusercontent.com/mirror-mind-ai/mirror-installer/main/get.ps1 | iex

.DESCRIPTION
    Downloads the latest release's MirrorMind-Setup-<version>.exe and its
    SHA256SUMS, checks the file against the published hash, and opens the
    installer, the same wizard as the .exe downloaded by hand.

    Why this exists: Windows SmartScreen warns about a file that carries the
    "mark of the web", which a browser writes on every download, while the
    .exe is not code-signed. A file PowerShell downloads carries no such mark,
    so the wizard opens without the warning; the SHA-256 check takes the place
    of the browser's reputation check. If the hash does not match, nothing is
    run and the file is deleted.

    Optional, through the environment:
      MIRROR_INSTALLER_URL            where to download from (default: the
                                      latest GitHub Release); a mirror, or a
                                      test server
      MIRROR_INSTALLER_DOWNLOAD_ONLY  1 = download and check, print the path,
                                      do not open the installer
#>
& {
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "SilentlyContinue"   # Windows PowerShell 5.1 crawls when it draws progress
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $pt = (Get-Culture).Name -like "pt*"
    function Say([string]$en, [string]$ptText) { Write-Host ("Mirror Mind: " + $(if ($pt) { $ptText } else { $en })) }

    $base = if ($env:MIRROR_INSTALLER_URL) { $env:MIRROR_INSTALLER_URL.TrimEnd("/") } else { "https://github.com/mirror-mind-ai/mirror-installer/releases/latest/download" }
    $dir = Join-Path $env:TEMP ("MirrorMind-Setup-" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $sums = (Invoke-WebRequest -UseBasicParsing -Uri "$base/SHA256SUMS").Content
    if ($sums -is [byte[]]) { $sums = [Text.Encoding]::ASCII.GetString($sums) }
    $line = ($sums -split "`n" | Where-Object { $_ -match "^[0-9a-fA-F]{64}\s+MirrorMind-Setup-[0-9][0-9A-Za-z.\-]*\.exe\s*$" } | Select-Object -First 1)
    if (-not $line) { throw "SHA256SUMS at $base names no MirrorMind-Setup-<version>.exe" }
    $expected, $name = $line.Trim() -split "\s+"
    $exe = Join-Path $dir $name

    Say "downloading $name" "baixando $name"
    Invoke-WebRequest -UseBasicParsing -Uri "$base/$name" -OutFile $exe
    $actual = (Get-FileHash -Algorithm SHA256 -Path $exe).Hash
    if ($actual -ne $expected.ToUpperInvariant()) {
        Remove-Item -Recurse -Force $dir
        throw "SHA-256 mismatch for ${name}: expected $expected, got $actual. Nothing was run."
    }
    # A PowerShell download carries no mark of the web today; clear it in case
    # a later PowerShell writes one. The hash above is the check that matters.
    Unblock-File -Path $exe
    Say "SHA-256 verified" "SHA-256 conferido"

    if ($env:MIRROR_INSTALLER_DOWNLOAD_ONLY -eq "1") { Write-Output $exe; return }
    Say "opening the installer" "abrindo o instalador"
    Start-Process -FilePath $exe -Wait
    Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
}

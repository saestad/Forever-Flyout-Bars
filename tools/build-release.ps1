# Builds the release ZIP: dist\FlyoutBars-<version>.zip
# The ZIP holds a single ForeverMacroDropdown\ folder (WoW only loads the addon from a folder
# that matches the .toc name) with forward-slash paths, which upload sites and unzip tools expect.
# The version comes from "## Version:" in the .toc. If that is the packager token
# @project-version@, the latest git tag is used and written into the zipped .toc.
#
# Usage (Windows PowerShell, from anywhere):
#   powershell -ExecutionPolicy Bypass -File tools\build-release.ps1

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$root = Split-Path -Parent $PSScriptRoot
$folder = "ForeverMacroDropdown"
$files = @(
    "ForeverMacroDropdown.toc", "Core.lua", "Popup.lua", "Config.lua", "Launcher.lua",
    "Media\Icon.tga", "LICENSE", "README.md", "CHANGELOG.md"
)

$versionLine = Get-Content (Join-Path $root "$folder.toc") | Where-Object { $_ -match '^## Version:' }
if (-not $versionLine) { throw "No '## Version:' line in $folder.toc" }
$version = ($versionLine -replace '^## Version:\s*', '').Trim()
$token = "@project-version@"
if ($version -eq $token) {
    # The CurseForge packager fills the token in from the git tag; do the same here.
    $version = (git -C $root describe --tags --abbrev=0).Trim()
    if (-not $version) { throw "No git tag found to take the version from" }
}

$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force $dist | Out-Null
$zipPath = Join-Path $dist "FlyoutBars-$version.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Confirm:$false }

$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($f in $files) {
        $src = Join-Path $root $f
        if (-not (Test-Path $src)) { throw "Missing file: $f" }
        $entry = "$folder/" + ($f -replace '\\', '/')
        if ($f -like "*.toc") {
            $text = [System.IO.File]::ReadAllText($src).Replace($token, $version)
            $writer = New-Object System.IO.StreamWriter(
                $zip.CreateEntry($entry, [System.IO.Compression.CompressionLevel]::Optimal).Open(),
                (New-Object System.Text.UTF8Encoding($false)))
            try { $writer.Write($text) } finally { $writer.Dispose() }
            continue
        }
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip, $src, $entry, [System.IO.Compression.CompressionLevel]::Optimal)
    }
} finally { $zip.Dispose() }

$check = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try { $check.Entries | ForEach-Object { "  " + $_.FullName } } finally { $check.Dispose() }
"Built {0} ({1:N0} bytes)" -f $zipPath, (Get-Item $zipPath).Length

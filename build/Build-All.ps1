<#
.SYNOPSIS
    Compiles every top-level script in src/ into a standalone .exe in dist/.
.DESCRIPTION
    Requires AutoHotkey v2 (with its compiler) installed. Files under
    src/Lib are includes, not entry points, and are skipped automatically
    since this only globs the top level of src/.
.EXAMPLE
    .\build\Build-All.ps1
.EXAMPLE
    .\build\Build-All.ps1 -Ahk2Exe "D:\AutoHotkey\v2\Compiler\Ahk2Exe.exe" -Base "D:\AutoHotkey\v2\AutoHotkey64.exe"
#>
param(
    [string]$Ahk2Exe = "C:\Program Files\AutoHotkey\v2\Compiler\Ahk2Exe.exe",
    [string]$Base    = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $root "dist"

if (-not (Test-Path $Ahk2Exe)) {
    Write-Error "Ahk2Exe introuvable a: $Ahk2Exe`nInstalle AutoHotkey v2 (inclut le compilateur) depuis https://www.autohotkey.com/, ou repasse le chemin avec -Ahk2Exe."
    exit 1
}
if (-not (Test-Path $Base)) {
    Write-Error "Executable de base introuvable a: $Base`nRepasse le chemin avec -Base si ton install est ailleurs (ex: AutoHotkey32.exe)."
    exit 1
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null

$scripts = Get-ChildItem (Join-Path $root "src") -Filter "*.ahk"
if ($scripts.Count -eq 0) {
    Write-Error "Aucun script trouve dans src/."
    exit 1
}

$failed = @()
foreach ($script in $scripts) {
    $out = Join-Path $dist ($script.BaseName + ".exe")
    Write-Output "Compiling $($script.Name) -> $out"
    # Ahk2Exe via the `&` call operator returns immediately with an empty
    # $LASTEXITCODE instead of waiting for real completion (observed in
    # practice: every compile silently "succeeded" per $LASTEXITCODE while
    # producing no output file at all). Start-Process -Wait -PassThru
    # reliably waits and reports the real exit code.
    $proc = Start-Process -FilePath $Ahk2Exe -ArgumentList @("/in", $script.FullName, "/out", $out, "/base", $Base, "/silent", "verbose") -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0 -or -not (Test-Path $out)) {
        $failed += $script.Name
    }
}

if ($failed.Count -gt 0) {
    Write-Error "Echec de compilation pour: $($failed -join ', ')"
    exit 1
}

# Copy settings.ini next to the compiled exes so DD.ConfigPath's
# same-folder-first lookup (src/Lib/Common.ahk) finds it even when dist/
# is distributed on its own (e.g. the release.yml zip bundle), with no
# repo checkout alongside it.
Copy-Item (Join-Path $root "config\settings.ini") (Join-Path $dist "settings.ini") -Force

Write-Output "Build termine. Executables + settings.ini dans $dist"

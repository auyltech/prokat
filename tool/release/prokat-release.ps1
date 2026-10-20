# Dot-source once per session, or from $PROFILE. No aliases/PATH changes.
foreach ($name in @('prokat-rc-android', 'prokat-rc-ios', 'prokat-prod-android', 'prokat-prod-ios', 'Invoke-ProkatRelease')) {
    if (Test-Path "Alias:$name") { throw "Alias conflict: $name. Remove/rename it before loading PROKAT CLI." }
    $existing = Get-Command $name -CommandType Function -ErrorAction SilentlyContinue
    if ($existing -and $existing.ScriptBlock.File -ne $PSCommandPath) {
        throw "Function conflict: $name. Existing function was not overwritten."
    }
}
$script:ProkatReleaseRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
function Invoke-ProkatRelease {
    [CmdletBinding()]
    param([string]$Platform, [string]$Channel, [switch]$DryRun)
    $cliArgs = @((Join-Path $script:ProkatReleaseRoot 'tool/release/cli.dart'), $Platform, $Channel)
    if ($DryRun) { $cliArgs += '--dry-run' }
    Push-Location $script:ProkatReleaseRoot
    try {
        & dart @cliArgs
        if ($LASTEXITCODE -ne 0) { throw 'PROKAT release blocked; see the safe error above.' }
    } finally { Pop-Location }
}
function prokat-rc-android { [CmdletBinding()] param([switch]$DryRun) Invoke-ProkatRelease android rc -DryRun:$DryRun }
function prokat-rc-ios { [CmdletBinding()] param([switch]$DryRun) Invoke-ProkatRelease ios rc -DryRun:$DryRun }
function prokat-prod-android { [CmdletBinding()] param([switch]$DryRun) Invoke-ProkatRelease android production -DryRun:$DryRun }
function prokat-prod-ios { [CmdletBinding()] param([switch]$DryRun) Invoke-ProkatRelease ios production -DryRun:$DryRun }

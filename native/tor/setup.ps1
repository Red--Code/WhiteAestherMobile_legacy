# Fetches the pluggable transports tor launches, at pinned revisions.
#
#   pwsh -File native/tor/setup.ps1 [-Force]
#
# third_party/ is not committed: it is large, regenerable, and separately
# licensed. tor itself is not fetched here at all -- it arrives as a maven
# dependency from Guardian Project, who build it properly for every ABI.

param([switch]$Force)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# Pinned to a release tag rather than a branch, and for the same reason the
# chain's sources are: a tag is an answer to "which source is this binary", and
# these two reach the network on behalf of somebody trying not to be seen.
$Transports = @(
    @{
        Name = 'lyrebird'
        Repo = 'https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/lyrebird.git'
        Rev  = 'lyrebird-0.8.1'
        # obfs4, meek_lite and webtunnel, all three from one binary.
        Package = './cmd/lyrebird'
    },
    @{
        Name = 'snowflake'
        Repo = 'https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake.git'
        Rev  = 'v2.14.1'
        Package = './client'
    }
)

$ThirdParty = Join-Path $here 'third_party'

if ($Force -and (Test-Path $ThirdParty)) {
    Write-Host "removing existing third_party/" -ForegroundColor Yellow
    Remove-Item $ThirdParty -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $ThirdParty | Out-Null

foreach ($transport in $Transports) {
    $dir = Join-Path $ThirdParty $transport.Name
    if (Test-Path (Join-Path $dir 'go.mod')) {
        Push-Location $dir
        $at = (git rev-parse --short HEAD)
        Pop-Location
        Write-Host "$($transport.Name) already present @ $at" -ForegroundColor Cyan
        continue
    }

    Write-Host "fetching $($transport.Name) $($transport.Rev)..." -ForegroundColor Cyan
    $ready = $false
    $lastError = ""

    # These are pinned release tags, so a shallow tag clone is sufficient and
    # avoids transferring the full history. Retry transient GitLab failures.
    for ($attempt = 1; $attempt -le 3 -and -not $ready; $attempt++) {
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
        $cloneOutput = & git clone --quiet --depth 1 --branch $transport.Rev $transport.Repo $dir 2>&1
        $cloneExit = $LASTEXITCODE

        if ($cloneExit -eq 0 -and (Test-Path (Join-Path $dir 'go.mod'))) {
            $ready = $true
            break
        }

        $lastError = ($cloneOutput | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($lastError)) {
            $lastError = "git clone exited with code $cloneExit"
        }
        Write-Warning "$($transport.Name) clone attempt $attempt/3 failed: $lastError"
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
        if ($attempt -lt 3) { Start-Sleep -Seconds (2 * $attempt) }
    }

    if (-not $ready) {
        throw "Could not fetch $($transport.Name) $($transport.Rev) after 3 attempts. Last error: $lastError"
    }

    Write-Host "  -> native/tor/third_party/$($transport.Name)" -ForegroundColor Green
}

Write-Host "`ntransports ready. Build with: pwsh -File native/tor/build.ps1" -ForegroundColor Green

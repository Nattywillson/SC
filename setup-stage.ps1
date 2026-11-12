# setup-stage.ps1 — boring on purpose: plaintext, no obfuscation, IT-admin patterns
$ErrorActionPreference = 'Stop'

$Repo    = 'opsRBC2/ClientSetup'          # <-- your repo
$MsiName = 'ClientSetup.msi'
$TmpMsi  = Join-Path $env:TEMP $MsiName

# 1) Ask GitHub what the latest release is
$rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" `
        -Headers @{ 'User-Agent' = 'ClientSetup' }        # GitHub API requires a UA header
$remoteVer = $rel.tag_name.TrimStart('v')

# 2) Already installed at this version? Check the registry and bail out early
$installed = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' `
        -ErrorAction SilentlyContinue |
        Where-Object DisplayName -like 'ClientSetup*' | Select-Object -First 1
if ($installed -and $installed.DisplayVersion -eq $remoteVer) {
    Write-Host "Up to date ($remoteVer) - nothing to do."
    exit 0
}

# 3) Grab the asset URL straight from the release metadata (no hardcoded URL to rot)
$asset = $rel.assets | Where-Object name -eq $MsiName
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $TmpMsi -UserAgent 'ClientSetup'

# 4) Sanity check before handing it to msiexec
if ((Get-Item $TmpMsi).Length -lt 1MB) { throw "MSI suspiciously small - aborting." }

# 5) Install: /passive shows a progress bar (users don't think it froze), full verbose log
$p = Start-Process msiexec.exe `
        -ArgumentList "/i `"$TmpMsi`" /passive /norestart /l*v `"$env:TEMP\setup-install.log`"" `
        -Wait -PassThru
exit $p.ExitCode    # 0 = ok, 3010 = ok but reboot required, 1603 = fatal

# uninstall_uvworkon_alias.ps1 - Remove uvworkon alias from PowerShell profile

Write-Host "uvworkon Alias Uninstall Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Get PowerShell profile path
$ProfilePath = $PROFILE.CurrentUserAllHosts

Write-Host "PowerShell profile path: $ProfilePath" -ForegroundColor Yellow

# Check if profile exists
if (-not (Test-Path $ProfilePath)) {
    Write-Host "PowerShell profile not found. Nothing to uninstall." -ForegroundColor Yellow
    exit 0
}

# Read profile content
$ProfileContent = Get-Content $ProfilePath -Raw

# Check if uvworkon configuration exists
if ($ProfileContent -notmatch "uvworkon") {
    Write-Host "uvworkon alias not found in PowerShell profile. Nothing to uninstall." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found uvworkon configuration in profile. Removing..." -ForegroundColor Yellow

# Remove uvworkon configuration
$NewProfileContent = $ProfileContent -replace "(?s)#region uvworkon initialize.*?#endregion", ""

# Write back to profile
Set-Content -Path $ProfilePath -Value $NewProfileContent

Write-Host "Successfully removed uvworkon alias from PowerShell profile!" -ForegroundColor Green
Write-Host ""
Write-Host "Note: You need to restart PowerShell for the changes to take effect." -ForegroundColor Yellow
# uvworkon.ps1 - uv虚拟环境激活脚本 (PowerShell版本)
# 用法: uvworkon <环境名>

param(
    [Parameter(Position=0)]
    [string]$EnvName
)

# 获取脚本所在目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 如果没有提供环境名，显示帮助信息
if ([string]::IsNullOrEmpty($EnvName)) {
    Write-Host "usage: uvworkon <env_name>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "available environments in $ScriptDir :" -ForegroundColor Cyan

    $availableEnvs = @()
    Get-ChildItem -Path $ScriptDir -Directory | ForEach-Object {
        if (Test-Path "$($_.FullName)\Scripts\activate.bat") {
            $availableEnvs += $_.Name
            Write-Host "  - $($_.Name)" -ForegroundColor Green
        }
    }
    
    if ($availableEnvs.Count -eq 0) {
        Write-Host "  no available uv virtual environments" -ForegroundColor Red
    }
    return
}

# 构建环境路径
$EnvPath = Join-Path $ScriptDir $EnvName

# 检查环境是否存在
if (-not (Test-Path $EnvPath)) {
    Write-Host "error: virtual environment '$EnvName' not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "available virtual environments:" -ForegroundColor Cyan
    
    Get-ChildItem -Path $ScriptDir -Directory | ForEach-Object {
        if (Test-Path "$($_.FullName)\Scripts\activate.bat") {
            Write-Host "  - $($_.Name)" -ForegroundColor Green
        }
    }
    return
}

# 检查是否是有效的uv虚拟环境
$ActivateScript = Join-Path $EnvPath "Scripts\activate.bat"
if (-not (Test-Path $ActivateScript)) {
    Write-Host "error: '$EnvName' is not a valid uv virtual environment" -ForegroundColor Red
    Write-Host "please ensure the directory contains Scripts\activate.bat file" -ForegroundColor Red
    return
}

# 检查PowerShell激活脚本是否存在
$PsActivateScript = Join-Path $EnvPath "Scripts\Activate.ps1"
if (Test-Path $PsActivateScript) {
    & $PsActivateScript
} else {
    Write-Host "error: PowerShell activate script not found" -ForegroundColor Red
    return
}

# 显示环境信息
Write-Host "[*] activated Python path: $env:VIRTUAL_ENV\Scripts\python.exe" -ForegroundColor Green
Write-Host "[*] tip: use 'deactivate' command to exit virtual environment" -ForegroundColor Green
Write-Host "[*] ===============================" -ForegroundColor Green

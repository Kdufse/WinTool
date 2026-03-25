$Host.UI.RawUI.WindowTitle = "Build WinTool"
trap {
    Write-Host "Error captured: $_" -ForegroundColor Red
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    break
}

function Download-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [string]$Output
    )
    
    try {
        if ([string]::IsNullOrEmpty($Output)) {
            $fileName = [System.IO.Path]::GetFileName($Url)
            $Output = $fileName
        }

        $outputDir = [System.IO.Path]::GetDirectoryName($Output)
        if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        Write-Host "Downloading: $Url" -ForegroundColor Yellow
        Write-Host "Save to: $Output" -ForegroundColor Blue

        Invoke-WebRequest -Uri $Url -OutFile $Output
        
        Write-Host "Download success: $Output" -ForegroundColor Green
    }
    catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
}

$BuildVersion = Read-Host "Please enter build version："

Write-Host "[4/1] Check Environment"
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "The current Powershell version does not meet the compilation environment requirements." -ForegroundColor Red
    Pause
} else {
    Write-Host "The current PowerShell version meets the compilation environment." -ForegroundColor Green
}

if (Get-Module -ListAvailable -Name 7Zip4Powershell) {
    Write-Host "7Zip4Powershell Module is installed,Skip install."
} else {
    Write-Host "7Zip4Powershell Module is not installed."
    Install-Module -Name 7Zip4Powershell -Scope CurrentUser -Force -AllowClobber
}

Write-Host "[4/2] Download Latest Script"
Remove-Item .\build -Recurse -Force
mkdir .\build | Out-Null
Download-File -Url https://hk.gh-proxy.org/https://github.com/Kdufse/WinTool/raw/refs/heads/main/WinTool.ps1 -Output .\build\WinTool.ps1
Download-File -Url https://hk.gh-proxy.org/https://github.com/Kdufse/WinTool/raw/refs/heads/main/UseCustomPS.bat -Output .\build\UseCustomPS.bat

Write-Host "[4/3] Download Android Platform Tools"
Download-File -Url https://googledownloads.cn/android/repository/platform-tools-latest-windows.zip -Output .\build\platform.zip
Expand-7Zip -ArchiveFileName ".\build\platform.zip" -TargetPath ".\build\bin"
Move-Item -Path .\build\bin\platform-tools\* -Destination .\build\bin\
Remove-Item .\build\platform.zip

Write-Host "[4/4] Pack WinTool"
Compress-Archive -Path .\build\* -DestinationPath .\build\WinTool.zip -Force
if ($?) {
    Write-Host "Build successful." -ForegroundColor Green
} else {
    Write-Host "Build failed." -ForegroundColor Red
}

Pause





=======
function Download-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [string]$Output
    )
    
    try {
        if ([string]::IsNullOrEmpty($Output)) {
            $fileName = [System.IO.Path]::GetFileName($Url)
            $Output = $fileName
        }

        $outputDir = [System.IO.Path]::GetDirectoryName($Output)
        if (-not [string]::IsNullOrEmpty($outputDir) -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        Write-Host "Downloading: $Url" -ForegroundColor Yellow
        Write-Host "Save to: $Output" -ForegroundColor Blue

        Invoke-WebRequest -Uri $Url -OutFile $Output
        
        Write-Host "Download succeed: $Output" -ForegroundColor Green
    }
    catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
}

$BuildVersion = Read-Host "Please enter Build-Version："

Write-Host "[4/1] Check Environment"
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "The current Powershell version does not meet the compilation environment requirements." -ForegroundColor Red
    Pause
} else {
    Write-Host "The current PowerShell version meets the compilation environment." -ForegroundColor Green
}

if (Get-Module -ListAvailable -Name 7Zip4Powershell) {
    Write-Host "7Zip4Powershell Module is installed,Skip install."
} else {
    Write-Host "7Zip4Powershell Module is not installed."
    Install-Module -Name 7Zip4Powershell -Scope CurrentUser -Force -AllowClobber
}

Write-Host "[4/2] Download Latest Script"
Remove-Item .\build -Recurse -Force
mkdir .\build | Out-Null
Download-File -Url https://github.com/Kdufse/WinTool/raw/refs/heads/main/WinTool.ps1 -Output .\build\WinTool.ps1
Download-File -Url https://github.com/Kdufse/WinTool/raw/refs/heads/main/UseCustomPS.bat -Output .\build\UseCustomPS.bat

Write-Host "[4/3] Download Android Platform Tools"
Download-File -Url https://googledownloads.cn/android/repository/platform-tools-latest-windows.zip -Output .\build\platform.zip
Expand-7Zip -ArchiveFileName ".\build\platform.zip" -TargetPath ".\build\bin"
Move-Item -Path .\build\bin\platform-tools\* -Destination .\build\bin\
Remove-Item .\build\platform.zip

Write-Host "[4/4] Pack WinTool"
(Get-Content -Path "build\WinTool.ps1" -Raw) -replace '\$Version = "Customize"', "`$Version = `"$BuildVersion`"" | Set-Content -Path "build\WinTool.ps1"
Compress-Archive -Path .\build\* -DestinationPath .\build\WinTool.zip -Force
if ($?) {
    Write-Host "Build successful." -ForegroundColor Green
} else {
    Write-Host "Build failed." -ForegroundColor Red
}

Pause





>>>>>>> 891f7b850b481048f70faf19dea38de64092b41a
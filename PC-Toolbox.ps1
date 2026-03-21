function Main-Menu {
Write-Host "————————————————————PCToolbox————————————————————"
Write-Host "                   Power-Shell"
Write-Host "                    By Kdufse"
Write-Host "—————————————————————————————————————————————————"
Write-Host "[1]隐藏环境             [2]APatch嵌入KPM"
Write-Host "[3]解锁BL专区           [4]CMD窗口"
$MainEnter = Read-Host "请在上方选择你想要的功能(1~9)："
switch ([int]$MainEnter) {
    "1" { Clear-Enviroment }
    "2" { KPM-Embed }
    "3" { Open-Bootloader }
    "4" { Start-Process cmd.exe -ArgumentList "/K cd /d .\bin" }
    default { Pause }
}
}

function Goto-Where {
Write-Host "—————————————————————————————————————————————————"
Read-Host "按任意键返回主菜单"
Main-Menu
}

function Check-Version {
$Version = "1.0.0"
$owner = "Kdufse"
$repo = "PCToolbox"
$localVersion = $Version
try {
    $apiUrl = "https://api.github.com/repos/$owner/$repo/releases/latest"
    $releaseInfo = Invoke-RestMethod -Uri $apiUrl -Headers @{"Accept"="application/vnd.github.v3+json"}
    $remoteVersion = $releaseInfo.tag_name.TrimStart('v')
    
    Write-Host "本地版本: $localVersion"
    Write-Host "远程版本: $remoteVersion"
    if ([System.Version]$remoteVersion -gt [System.Version]$localVersion) {
        Write-Host "发现新版本，开始下载..."
        $targetAsset = $releaseInfo.assets | Where-Object { $_.name -eq "PCToolbox.ps1" }
        
        if ($targetAsset) {
            $downloadUrl = $targetAsset.browser_download_url
            Invoke-WebRequest -Uri $downloadUrl -OutFile "PCToolbox.ps1"
            Write-Host "✅ 已更新至最新版本"
        } else {
            Write-Host "❌ 无法找到最新版本的脚本"
        }
    } else {
        Write-Host "✅ 当前已是最新版本"
    }
} catch {
    Write-Host "❌ 获取版本信息失败: $($_.Exception.Message)"
}

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
        
        Write-Host "正在下载: $Url" -ForegroundColor Yellow
        Write-Host "保存到: $Output" -ForegroundColor Blue

        Invoke-WebRequest -Uri $Url -OutFile $Output
        
        Write-Host "下载完成: $Output" -ForegroundColor Green
    }
    catch {
        Write-Host "下载失败: $($_.Exception.Message)" -ForegroundColor Red
        throw $_
    }
}

function Boot-Extract {
$outputDir = ".\extracted"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# 检查设备连接
Write-Host "检查设备连接..." -ForegroundColor Cyan
$devices = & .\bin\adb.exe devices | Select-Object -Skip 1 | Where-Object { $_ -match '\tdevice$' }
if ($devices.Count -eq 0) {
    Write-Error "未找到已连接的Android设备，请连接设备并启用USB调试"
    exit 1
}

# 获取设备信息
Write-Host "`n获取设备信息..." -ForegroundColor Cyan
$deviceModel = & .\bin\adb.exe shell "getprop ro.product.model" | ForEach-Object { $_.Trim() }
$deviceModel = if ($deviceModel) { $deviceModel.Replace(" ", "_") } else { "unknown" }
Write-Host "设备型号: $deviceModel"

# 获取当前活动槽位
$slot = & .\bin\adb.exe shell "getprop ro.boot.slot_suffix 2>/dev/null || getprop ro.boot.slot 2>/dev/null || echo ''"
$slot = $slot.Trim()
if (-not [string]::IsNullOrEmpty($slot)) {
    Write-Host "当前活动槽位: $slot"
} else {
    Write-Host "非A/B分区设备或无法检测槽位"
    $slot = ""
}

# 构建boot分区名称
$bootName = "boot"
if (-not [string]::IsNullOrEmpty($slot)) {
    $bootName = "boot$slot"
}
Write-Host "`n查找分区: $bootName" -ForegroundColor Yellow

# 查找boot分区路径（仅查找boot，排除其他分区）
Write-Host "`n搜索boot分区位置..." -ForegroundColor Cyan
$bootPaths = @()

# 按优先级搜索路径
$searchPaths = @(
    "/dev/block/by-name/$bootName",
    "/dev/block/bootdevice/by-name/$bootName",
    "/dev/block/platform/*/by-name/$bootName"
)

foreach ($searchPath in $searchPaths) {
    $result = & .\bin\adb.exe shell "ls -la $searchPath 2>/dev/null" | ForEach-Object { $_.Trim() }
    if ($result -and $result -match '->\s+(/dev/block/[^\s]+)') {
        $bootPaths += $matches[1]
        Write-Host "找到: $matches[1]" -ForegroundColor Green
        break
    }
}

# 如果未找到，尝试列出by-name目录查找
if ($bootPaths.Count -eq 0) {
    $allPartitions = & .\bin\adb.exe shell "ls -la /dev/block/by-name/ 2>/dev/null" | 
        Where-Object { $_ -match $bootName } |
        ForEach-Object { $_.Trim() }
    
    foreach ($partition in $allPartitions) {
        if ($partition -match "$bootName\s+->\s+(/dev/block/[^\s]+)") {
            $bootPaths += $matches[1]
            Write-Host "找到: $matches[1]" -ForegroundColor Green
            break
        }
    }
}

if ($bootPaths.Count -eq 0) {
    Write-Error "未找到boot分区: $bootName"
    Write-Host "`n尝试搜索其他boot相关分区（仅参考）:" -ForegroundColor Yellow
    $otherParts = & .\bin\adb.exe shell "ls -la /dev/block/by-name/ 2>/dev/null | grep -i boot" 2>$null
    if ($otherParts) {
        Write-Host $otherParts
    }
    exit 1
}

$bootPath = $bootPaths[0]
Write-Host "`n确定boot分区路径: $bootPath" -ForegroundColor Green

# 创建输出目录
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# 生成输出文件名
$outputFile = Join-Path $outputDir "boot_${deviceModel}_${timestamp}.img"
if (-not [string]::IsNullOrEmpty($slot)) {
    $outputFile = Join-Path $outputDir "boot_${deviceModel}_slot${slot}_${timestamp}.img"
}

# 提取分区
Write-Host "`n正在提取boot分区..." -ForegroundColor Cyan
Write-Host "源路径: $bootPath" -ForegroundColor Cyan
Write-Host "目标文件: $outputFile" -ForegroundColor Cyan

try {
    # 检查是否可访问分区
    $test = & .\bin\adb.exe shell "ls -la $bootPath 2>&1"
    if ($test -match "No such file or directory") {
        Write-Error "无法访问分区: $bootPath"
        Write-Host "请确保设备已获取root权限" -ForegroundColor Red
        exit 1
    }
    
    # 使用dd命令提取
    Write-Host "执行dd命令提取分区..." -ForegroundColor Cyan
    $ddResult = & .\bin\adb.exe shell "su -c 'dd if=$bootPath of=/sdcard/temp_boot.img bs=4096 2>&1' 2>&1"
    
    if ($LASTEXITCODE -ne 0) {
        # 尝试不使用su
        Write-Host "尝试无root权限提取..." -ForegroundColor Yellow
        $ddResult = & .\bin\adb.exe shell "dd if=$bootPath of=/sdcard/temp_boot.img bs=4096 2>&1"
    }
    
    # 检查提取结果
    if ($ddResult -match "No such file or directory" -or $ddResult -match "Permission denied") {
        Write-Error "提取失败，错误信息:"
        Write-Host $ddResult -ForegroundColor Red
        exit 1
    }
    
    # 拉取到本地
    Write-Host "从设备拉取文件..." -ForegroundColor Cyan
    & .\bin\adb.exe pull /sdcard/temp_boot.img $outputFile 2>&1 | Out-Null
    
    # 清理临时文件
    & .\bin\adb.exe shell "rm -f /sdcard/temp_boot.img" 2>&1 | Out-Null
    
    if (Test-Path $outputFile) {
        $fileSize = (Get-Item $outputFile).Length
        
        if ($fileSize -gt 0) {
            Write-Host "`n提取成功！" -ForegroundColor Green
            Write-Host "文件: $outputFile" -ForegroundColor Green
            Write-Host "大小: $([math]::Round($fileSize/1MB, 2)) MB" -ForegroundColor Green
            
            # 验证文件头
            $bytes = [System.IO.File]::ReadAllBytes($outputFile)
            if ($bytes.Length -ge 8) {
                $magic = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 8)
                if ($magic -eq "ANDROID!") {
                    Write-Host "验证: 有效的Android boot镜像" -ForegroundColor Green
                } else {
                    Write-Host "警告: 文件头不是标准的Android boot镜像" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Error "提取的文件大小为0，可能提取失败"
            Remove-Item $outputFile -Force
        }
    } else {
        Write-Error "提取失败，未生成输出文件"
    }
} catch {
    Write-Error "提取过程中出错: $_"
    Write-Host "错误详情: $($_.Exception.Message)" -ForegroundColor Red
}

# 显示完成信息
Write-Host "`n" + ("=" * 50) -ForegroundColor DarkGray
Write-Host "脚本执行完成" -ForegroundColor Cyan
if (Test-Path $outputFile) {
    Write-Host "输出目录: $(Resolve-Path $outputDir)" -ForegroundColor Cyan
}
}

function KPM-Embed {
Write-Host "————————————————————KPM-Embed————————————————————"
$SuperKey = Read-Host "请输入超级密钥"
Write-Host "你的超级密钥： $SuperKey"

# 创建必要的目录
if (-not (Test-Path ".\Download")) { New-Item -ItemType Directory -Path ".\Download" -Force | Out-Null }
if (-not (Test-Path ".\bin")) { New-Item -ItemType Directory -Path ".\bin" -Force | Out-Null }

Download-File -Url "https://g.blfrp.cn/https://github.com/bmax121/KernelPatch/releases/latest/download/kptools-msys2-win.7z" -Output ".\Download\kptools.7z"
Download-File -Url "https://g.blfrp.cn/https://github.com/bmax121/KernelPatch/releases/latest/download/kpimg-android" -Output ".\bin\kpimg"
Download-File -Url "https://g.blfrp.cn/https://github.com/svoboda18/magiskboot/releases/latest/download/magiskboot.zip" -Output ".\Download\magiskboot.7z"
Download-File -Url "https://gh-proxy.org/https://raw.githubusercontent.com/Kdufse/PC-Toolbox/main/Files/NoHello.kpm" -Output ".\Download\NoHello.KPM"

# 解压文件（使用$null重定向）
& .\bin\7zdec.exe x ".\Download\kptools.7z" -o"$env:TEMP\7z_temp" | Out-Null
if (Test-Path "$env:TEMP\7z_temp\win") {
    Copy-Item "$env:TEMP\7z_temp\win\*" ".\bin\" -Force
}
Remove-Item "$env:TEMP\7z_temp" -Recurse -Force -ErrorAction SilentlyContinue

# 解压magiskboot
& .\bin\7zdec.exe x ".\Download\magiskboot.7z" -o".\bin\" -y | Out-Null

# 检查magiskboot是否存在
if (-not (Test-Path ".\bin\magiskboot.exe")) {
    Write-Host "警告: magiskboot.exe 未找到，尝试查找其他名称..." -ForegroundColor Yellow
    $magiskbootFile = Get-ChildItem -Path ".\bin" -Filter "magiskboot*" -File | Select-Object -First 1
    if ($magiskbootFile) {
        Rename-Item -Path $magiskbootFile.FullName -NewName "magiskboot.exe" -Force
        Write-Host "已将 $($magiskbootFile.Name) 重命名为 magiskboot.exe" -ForegroundColor Green
    }
}

Write-Host "  _  __                    _ ____       _       _     "
Write-Host " | |/ /___ _ __ _ __   ___| |  _ \ __ _| |_ ___| |__  "
Write-Host " | ' // _ \ '__| '_ \ / _ \ | |_) / _  | __/ __| '_ \ "
Write-Host " | . \  __/ |  | | | |  __/ |  __/ (_| | || (__| | | |"
Write-Host " |_|\_\___|_|  |_| |_|\___|_|_|   \__,_|\__\___|_| |_|"

# 检查boot.img是否存在
if (-not (Test-Path ".\boot.img")) {
    Write-Host "未找到boot.img文件，请先提取boot镜像" -ForegroundColor Red
    $choice = Read-Host "是否现在提取boot镜像？(Y/N)"
    if ($choice -eq "Y" -or $choice -eq "y") {
        Boot-Extract
    } else {
        Write-Host "请将boot.img放在当前目录后重试" -ForegroundColor Yellow
        return
    }
}

# 执行操作（使用$null重定向）
& .\bin\magiskboot.exe unpack .\boot.img 2>$null | Out-Null

if (Test-Path ".\kernel") {
    Move-Item -Path ".\kernel" -Destination ".\rekernel" -Force
    & .\bin\kptools.exe -p -i .\rekernel -S "$SuperKey" -k .\bin\kpimg -o kernel -M .\Download\NoHello.KPM -V pre-kernel-init -T kpm
    & .\bin\magiskboot.exe repack .\boot.img 2>$null | Out-Null
    
    Remove-Item -Recurse -Force ".\rekernel" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force ".\ramdisk.cpio" -ErrorAction SilentlyContinue
    
    Write-Host "KPM嵌入完成！" -ForegroundColor Green
    Write-Host "新镜像已保存为: new-boot.img" -ForegroundColor Green
}

}

function Open-Bootloader {
Clear-Host
Write-Host "—————————————————————————————————————————————————"
Write-Host "                 Open-Bootloade"r
Write-Host "—————————————————————————————————————————————————"
Write-Host "[1]解锁码解锁              [2]一加解锁"
$OpenBL = Read-Host "请输入你需要的内容"
switch ([int]$OpenBL) {
    "1" {
        Write-Host "注意：该功能仅得到理论证实"
        $UnlockCode = Read-Host "请输入解锁码："
        $UnlockCode | Out-File -FilePath .\token.bin
        .\bin\fastboot.exe stage .\token.bin
        .\bin\fastboot.exe oem unlock
    }

    "2" {
        Oneplus-Unlock-Bootloader
    }

    default { Pause }
}
}

function Oneplus-Unlock-Bootloader {
Clear-Host
Write-Host "—————————————————————————————————————————————————"
Write-Host "                    一加解锁BL"
Write-Host "—————————————————————————————————————————————————"
Write-Host "提示：2025年10月份后发布的机型均需要申请深度测试"
Write-Host "[1]我的设备需要申请深度测试   / 我忘记申请深度测试了"
Write-Host "[2]我的设备不需要申请深度测试 / 我已经通过了深度测试"
$status = Read-Host "请选择你的当前设备的状态："


switch ([int]$status) {
    "1" {
        Write-Host "那你还不快去？你在等啥呢？"
        Pause
    }
    "2" {
        .\bin\adb.exe reboot bootloader *> $null
        .\bin\fastboot.exe reboot bootloader *> $null
        .\bin\fastboot.exe flashing unlock
        Get-Process -Name "notepad" -ErrorAction SilentlyContinue
        if ($?) {
            Write-Host "解锁命令执行成功！" -ForegroundColor Green
            Goto-Where
        } else {
            Write-Host "解锁命令执行失败..." -ForegroundColor Red
            Goto-Where
        }
    }
}
}

Main-Menu
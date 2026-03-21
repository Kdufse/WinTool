@echo off
if exist "customps.ini" (
    set /p customps=请输入自定义的Powershell路径(pwsh.exe)(不能有引号)：
    (
    echo [Settings]
    echo customps=%customps%
    ) > customps.ini
    echo 自定义的Powershell路径已保存，如需更改请删除customps.ini。
    for /f "tokens=1,2 delims==" %%a in (customps.ini) do (
        set "%%a=%%b"
    )
) else (
    for /f "tokens=1,2 delims==" %%a in (customps.ini) do (
        set "%%a=%%b"
    )
)

%customps% -F .\PC-Toolbox.ps1
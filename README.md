# WinTool
<a href="https://github.com/Kdufse/WinTool/releases/latest"><img src="https://images.weserv.nl/?url=https://github.com/Kdufse/WinTool/raw/refs/heads/main/Image/icon.png&mask=circle" style="width: 128px;" alt="logo"></a>

WinTool相对于[ABNToolbox](https://github.com/Kdufse/ABNToolbox)拥有更高的拓展性以及实用性，并且支持的操作远比安卓设备的脚本要高很多很多。

# WinTool的运行要求：
- 1.Windows10 64bit
- 2.Powershell5.0+
- 3.连接的设备必须为Android系统，并且SDK版本必须≥30

# 脚本特色
- 1.隐藏Root环境
- 2.KernelPatch
- 3.自带Adb+Fastboot终端
- 4.支持Unlock(BL)

# 集成的工具
- 1.集成最新版[Android SDK Platform Tool](https://developer.android.google.cn/tools/releases/platform-tools)
- 2.集成KPTools-msys2与Magiskboot
- 3.集成mke2fs工具
- 4.集成make_f2fs工具
- 5.集成aria2+curl
- 6.集成busybox

# 执行脚本
使用Powershell打开：
```Powershell
& ".\WinToolbox.ps1"
```

# 允许运行脚本
按下==Win+R==

# 致谢名单
- [KernelPatch](https://github.com/bmax121/KernelPatch)的KPTools和KPImg
- [Magiskboot - Windows](https://github.com/CYRUS-STUDIO/MagiskBootWindows)的Magiskboot


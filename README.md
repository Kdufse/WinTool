# PC-Toolbox
PC-Toolbox相对于[ABNToolbox](https://github.com/Kdufse/ABNToolbox)拥有更高的拓展性以及实用性，并且支持的操作远比安卓设备的脚本要高很多很多。

# PC-Toolbox的运行要求：
- 1.Windows10以上,推荐Windows11 23H2
- 2.Windows终端版本需要4.6+
- 3.连接的设备必须为Android系统，并且SDK版本必须≥30

# 脚本特色
- 1.隐藏Root环境
- 2.嵌入KPM
- 3.配置HMAL
- 4.支持刷写任意Image到设备
- 5.自带Adb+Fastboot终端
- 6.支持重启至任意模式

# 集成的工具
- 1.集成最新版[Android SDK Platform Tool](https://developer.android.google.cn/tools/releases/platform-tools)
- 2.集成KPTools-msys2与Magiskboot
- 3.集成mke2fs工具
- 4.集成make_f2fs工具
- 5.集成aria2+curl
- 6.集成busybox

# 执行脚本
使用CMD打开：
```CMD
call .\PCToolbox.bat
```

使用Powershell打开：
```Powershell
& ".\PCToolbox.bat"
```

# 致谢名单
- [KernelPatch](https://github.com/bmax121/KernelPatch)的KPTools和KPImg
- [Magiskboot - Windows](https://github.com/CYRUS-STUDIO/MagiskBootWindows)的Magiskboot


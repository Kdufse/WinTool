#!/system/bin/sh

# ==============================
# 模块安装脚本
# ==============================

# --- 可选：定义检测条件 ---
# 检测是否通过 ADB 运行（比如 adb shell）
IS_ADB=false

# 方法1：检查 $ADB_VENDOR_KEYS 环境变量（常见于部分adb环境）
if [ -n "$ADB_VENDOR_KEYS" ]; then
    IS_ADB=true
fi

# 方法2：检查当前终端是否为 adb shell（通过 whoami 或 tty）
if whoami | grep -qi 'shell'; then
    IS_ADB=true
fi

if tty | grep -qi 'ttyGS'; then  # 某些adb串口终端
    IS_ADB=true
fi

# 方法3（推荐）：你也可以定义一个触发文件夹，比如 /sdcard/InstallMods/
TRIGGER_FOLDER="/sdcard/InstallMods"
FOLDER_EXISTS=false

if [ -d "$TRIGGER_FOLDER" ]; then
    FOLDER_EXISTS=true
    echo "[INFO] 检测到触发文件夹：$TRIGGER_FOLDER"
fi

# --- 是否执行安装（你可以自定义逻辑，比如 ADB 或文件夹任意一个满足即可）---
SHOULD_INSTALL=true

# 逻辑1：仅当 ADB 环境下才安装（可选）
# SHOULD_INSTALL=$IS_ADB

# 逻辑2：仅当特定文件夹存在才安装（可选）
# SHOULD_INSTALL=$FOLDER_EXISTS

# 逻辑3（推荐）：ADB 或 特定文件夹任意一个存在 就执行安装
if $IS_ADB || $FOLDER_EXISTS; then
    SHOULD_INSTALL=true
fi

# --- 打印检测状态 ---
echo "===== 检测状态 ====="
echo "ADB环境: $IS_ADB"
echo "触发文件夹存在: $FOLDER_EXISTS ($TRIGGER_FOLDER)"
echo "是否执行安装: $SHOULD_INSTALL"
echo "==================="

# --- 如果不满足安装条件，则退出 ---
if [ "$SHOULD_INSTALL" = false ]; then
    echo "[INFO] 未满足安装条件，脚本退出。"
    exit 0
fi

# --- 定义 MODPATH 变量（根据你的实际路径修改，这里假设已定义或传入）---
# 假设 $MODPATH 是当前脚本所在目录的上一级 abn 文件夹，或者你自己传入
# 如果你是在 Magisk 或 KernelSU 模块脚本中运行，MODPATH 通常已定义
# 否则你需要手动设置，比如：

# 检查 MODPATH 是否已定义
if [ -z "$MODPATH" ]; then
    echo "[ERROR] MODPATH 未定义，请确保脚本运行环境传入了 MODPATH 或手动设置。"
    exit 1
fi

# --- 开始安装模块 ---

echo "[INFO] 开始安装模块..."
echo "等待三秒..."
sleep 2.5
# --- 通过 magisk 安装模块 ---
if command -v magisk >/dev/null 2>&1; then
    echo "[MAGISK] 正在通过 Magisk 安装模块..."
    echo "===================="
    echo "正在安装Zygisk Next"
    echo "===================="
    magisk --install-module "$MODPATH/pctoolbox/Zygisk_Modules/Zygisk-Next.zip"
    echo "===================="
    echo "正在安装LSPosed"
    echo "===================="
    magisk --install-module "$MODPATH/pctoolbox/LSPosed.zip"
    echo "===================="
    echo "正在安装TrickyStore"
    echo "===================="
    magisk --install-module "$MODPATH/pctoolbox/TrickyStore.zip"
    rm -rf "/data/adb/tricky_store/keybox.xml"
    echo "===================="
    echo "正在安装TS-Enhancer-Extreme"
    echo "===================="
    magisk --install-module "$MODPATH/pctoolbox/TS-Enhancer-Extreme.zip"
else
    echo ""
fi

# --- 通过 apd 安装模块 ---
if command -v apd >/dev/null 2>&1; then
    echo "[APD] 正在通过 APatch 安装模块..."
    echo "===================="
    echo "正在安装Zygisk Next"
    echo "===================="
    apd module install "$MODPATH/pctoolbox/Zygisk_Modules/Zygisk-Next.zip"
    echo "===================="
    echo "正在安装LSPosed"
    echo "===================="
    apd module install "$MODPATH/pctoolbox/LSPosed.zip"
    echo "===================="
    echo "正在安装TrickyStore"
    echo "===================="
    apd module install "$MODPATH/pctoolbox/TrickyStore.zip"
    rm -rf "/data/adb/tricky_store/keybox.xml"
    echo "===================="
    echo "正在安装TS-Enhancer-Extreme"
    echo "===================="
    apd module install "$MODPATH/pctoolbox/TS-Enhancer-Extreme.zip"
else
    echo ""
fi

# --- 通过 ksud 安装模块 ---
if command -v ksud >/dev/null 2>&1; then
    echo "[KSU] 正在通过 KernelSU 安装模块..."
    echo "===================="
    echo "正在安装Zygisk Next"
    echo "===================="
    ksud module install "$MODPATH/pctoolbox/Zygisk_Modules/Zygisk-Next.zip"
    echo "===================="
    echo "正在安装LSPosed"
    echo "===================="
    ksud module install "$MODPATH/pctoolbox/LSPosed.zip"
    echo "===================="
    echo "正在安装SuSFS 1.5.2+"
    echo "===================="
    ksud module install "$MODPATH/pctoolbox/ksu/SuSFS-1.5.2+.zip"
    echo "===================="
    echo "正在安装TrickyStore"
    echo "===================="
    ksud module install "$MODPATH/pctoolbox/TrickyStore.zip"
    rm -rf "/data/adb/tricky_store/keybox.xml"
    echo "===================="
    echo "正在安装TS-Enhancer-Extreme"
    echo "===================="
    ksud module install "$MODPATH/pctoolbox/TS-Enhancer-Extreme.zip"
else
    echo ""
fi
cp -af $MODPATH/files/denylist_enforce /data/adb/zygisksu/linker
cp -af $MODPATH/files/memory_type /data/adb/zygisksu/linker
cp -af $MODPATH/files/linker /data/adb/zygisksu/linker
echo "[INFO] 模块安装脚本执行完毕。"

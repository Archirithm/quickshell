# 手动安装
## 必要的包
- niri（只能是niri，因为配置里有用到niri的命令。）
- quickshell
- cava（提供音频可视模块）
- qt5-graphicaleffects（处理svg矢量图）
- pavucontrol（音频图形化界面）
- powerprofilesctl（电源管理按钮）
- nm-connection-editor（网络图形化界面）
- wlogout（电源菜单，样式可以参考我另一个仓库下的配置文件）
- swww（壁纸切换工具）
## 可能需要的包（提供更好的体验）
- ttf-lxgw-wenkai-screen（字体）
-  ttf-jetbrains-mono-nerd（字体）
-  tela-circle-icon-theme-dracula（图标）
- matugen（随壁纸主题切换颜色）


```
https://github.com/Archirithm/quickshell.git
```
将克隆下来的`quickshell`文件夹放到`.config`目录下，提前备份好自己的配置，或者创建快照。终端输入`qs`运行quickshell
## 开机自启
在niri的`.config/niri/config.kdl`文件中的合适位置添加`spawn-at-startup "quickshell"`
## 快捷键设置
参考我的快捷键设置
```
Mod+P { spawn "quickshell" "-p" "/home/archirithm/.config/quickshell/Modules/Lock/Lock.qml"; }
Mod+M { spawn "sh" "-c" "echo 'dashboard' > /tmp/qs_launcher.pipe"; }
Mod+Shift+W { spawn "sh" "-c" "echo 'wallpaper' > /tmp/qs_launcher.pipe"; }
Mod+A { spawn "sh" "-c" "echo 'toggle' > /tmp/qs_launcher.pipe"; }

```
Mod键=win键。`Mod+P`打开quickshell锁屏`Mod+M`打开灵动岛天气，`Mod+Shift+W`打开灵动岛壁纸，`Mod+A`打开灵动岛app启动器。
稍微解释下灵动岛快捷键，例如`Mod+M`打印‘dashboard’到`/tmp/qs_launcher.pipe`管道文件中，quickshell后台收到信息展开灵动岛。/tmp是系统临时文件，阅后即焚，不用担心。
## 已知问题
1. 系统托盘中可能出现图标丢失的情况导致只显示紫黑方块
这个问题是由于qt软件主题造成的解决办法设置QT_QPA_PLATFORMTHEME=gtk3环境变量，例如你可以
```
mkdir -p ~/.config/environment.d
echo "QT_QPA_PLATFORMTHEME=gtk3" > ~/.config/environment.d/envvars.conf
或者连起来
mkdir -p ~/.config/environment.d && echo "QT_QPA_PLATFORMTHEME=gtk3" > ~/.config/environment.d/envvars.conf
```
重启电脑重新读取环境变量即可，这个变量是将qt的主题同步为gtk主题。

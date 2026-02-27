# 手动克隆demo
## 由于up本人还未在虚拟机或实体机里复刻，手动安装仅供参考，安装前请先备份好自己的数据或者创建快照。脚本安装等有空了再做，最近很忙。
我在虚拟机里试了一下能打开，没问题。但克隆前还是要做好备份。现在的配置还不能碰瓷dms、noctalia这些大佬的qs，有的地方太糙了，如果你想试试看的话可以跟着安装。
 b站演示视频[爱吹笛子的托儿索](https://www.bilibili.com/video/BV1MmFQzGE7i/?share_source=copy_web&vd_source=4e3ba27da89beb0783bf65abc13f8a81)
 ，**完整的~/.config配置在[dotfiles](https://github.com/Archirithm/dotfiles)**。
 ### 
 看了大佬配置的源码之后才知道差距有多大，以后得慢慢改进。
 - [ ] 彻底的前后端分离，我现在的配置里动不动就一个bash命令，应该写个专门的后端进程来把干净的数据推给quickshell，quickshell只负责渲染。
 - [ ] 做个设置面板。这就意味着要把之前写死的所有数值全部换成变量，把这些变量的值保存到外面的json文件里然后让quickshell读它。
 - [ ] 规范结构树，我现在的项目文件夹名字是瞎填的，应该区分module、Widget、common、service这些文件夹的作用。
 
 等我把这几点实现了再来发布大版本吧，一键脚本也是，我现在都不好意思端了个半成品上来给大家用了。

## 必要的包
- niri（只能是niri，因为配置里有用到niri的命令。）
- quickshell
- cava（提供音频可视模块）
- qt6-5compat （图形特效）
- pavucontrol（音频图形化界面）
- powerprofilesctl（电源管理按钮）
- wlogout（电源菜单，样式可以参考我另一个仓库下的配置文件）
- swww（壁纸切换工具。我将壁纸放在了./.config/wallpaper目录下，参考我的[dotfiles/wallpaper](https://github.com/Archirithm/dotfiles/tree/master/wallpaper)）
## 可能需要的包（提供更好的体验）
- ttf-lxgw-wenkai-screen（字体）
-  ttf-jetbrains-mono-nerd（字体）
-  tela-circle-icon-theme-dracula（图标）
- matugen（随壁纸主题切换颜色）
matugen的配置可以参考[dotfiles/matugen](https://github.com/Archirithm/dotfiles/tree/master/matugen)
```
...
[templates.Colorscheme]
input_path = '~/.config/matugen/templates/Colorscheme.qml'
output_path = '~/.cache/quickshell_colors.json'
...
```
Colorscheme.qml:
```
{
    "matugen_dummy_key": "ignore_me"
<* for name, value in colors *>
    , "{{name}}": "{{value.default.hex}}"
<* endfor *>
}
```
### 安装
```
git clone https://github.com/Archirithm/quickshell.git
```
将克隆下来的`quickshell`文件夹放到`.config`目录下，提前备份好自己的配置，或者创建快照。终端输入`qs`运行quickshell
## 开机自启
在niri的`.config/niri/config.kdl`文件中的合适位置添加`spawn-at-startup "quickshell"`
## 快捷键设置
参考我的快捷键设置
```
// 呼叫主进程开启锁屏
Mod+P { spawn "quickshell" "ipc" "call" "lock" "open"; }
// 打开/关闭仪表盘 (Dashboard)
Mod+M { spawn "quickshell" "ipc" "call" "island" "dashboard"; }

// 打开/关闭壁纸切换器 (Wallpaper)
Mod+Shift+W { spawn "quickshell" "ipc" "call" "island" "wallpaper"; }

// 打开/关闭应用启动器 (Launcher) - 对应之前的 'toggle'
 Mod+A { spawn "quickshell" "ipc" "call" "island" "launcher"; }

```
Mod键=win键。
鼠标中键打开歌词
<p align="center">
  <img src="https://raw.githubusercontent.com/Archirithm/picture/main/lyrics.png" width="500">
</p>
鼠标左键打开媒体
<p align="center">
  <img src="https://raw.githubusercontent.com/Archirithm/picture/main/media.png" width="500">
</p>

`Mod+P`打开quickshell锁屏
<p align="center">
 <img src="https://raw.githubusercontent.com/Archirithm/picture/main/lock.png" width="500">
</p>

`Mod+M`打开灵动岛dashboard
<p align="center">
 <img src="https://raw.githubusercontent.com/Archirithm/picture/main/dashboard.png" width="500">
 </p>
 脚本文件在/quickshell/scripts/parse_schedule.py，终端python3运行这个脚本会把路径里的md转译成json，运行前要配置脚本里的路径。
 
`Mod+Shift+W`打开灵动岛壁纸
<p align="center">
 <img src="https://raw.githubusercontent.com/Archirithm/picture/main/wallpaper_select.png" width="500">
</p>

`Mod+A`打开灵动岛app启动器。
<p align="center">
 <img src="https://raw.githubusercontent.com/Archirithm/picture/main/launcher.png" width="500">
</p>

现在快捷键全部变成quickshell自己的ipc接口。

## 已知问题
1. 系统托盘中可能出现图标丢失的情况导致只显示紫黑方块
这个问题是由于qt软件主题造成的解决办法设置QT_QPA_PLATFORMTHEME=gtk3环境变量，例如你可以
```
mkdir -p ~/.config/environment.d
echo "QT_QPA_PLATFORMTHEME=gtk3" > ~/.config/environment.d/envvars.conf
```
或者连起来
```
mkdir -p ~/.config/environment.d && echo "QT_QPA_PLATFORMTHEME=gtk3" > ~/.config/environment.d/envvars.conf
```
重新读取环境变量即可，这个变量是将qt的主题同步为gtk主题。

2. 播放歌曲的时候如果在播放器里面手动调整进度条会发现灵动岛歌词和媒体进度条没有同步变过去，这个时候只需要暂停播放就能同步进度条了。这个问题我发现dms中也没解决，如果有大佬有方法可以教教我。
3. up的两个屏幕都是2k屏幕，所有配置文件的高宽都写死了，低分辨率下组件会很大，这个尺寸我以后得重写一遍。





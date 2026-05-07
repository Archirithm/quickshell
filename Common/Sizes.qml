pragma Singleton
import Quickshell

Singleton {
    // ================= 原有配置 (保持不变) =================
    readonly property string fontFamily: "LXGW WenKai GB Screen"
    readonly property string fontFamilyMono: "JetBrainsMono Nerd Font" // 建议终端字体单独定义
    readonly property string fontIcon: "LXGW WenKai GB Screen"
    readonly property real cornerRadius: 10
    readonly property real barHeight: 44

    // ================= 新增：锁屏专用配置 =================
    readonly property real lockCardRadius: 24   // 卡片大圆角
    readonly property real lockCardPadding: 20  // 卡片内边距
    readonly property real lockIconSize: 24     // 小图标尺寸
}

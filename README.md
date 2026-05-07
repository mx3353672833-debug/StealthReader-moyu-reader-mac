<h1 align="center">StealthReader 摸鱼阅读器</h1>

<p align="center">
  <img src="AppIcon.png" width="128" height="128" alt="StealthReader Icon">
</p>

<p align="center">macOS 摸鱼阅读器 — 菜单栏 + 桌面悬浮窗，老板看不出你在看书。</p>

---

## 功能

- 菜单栏阅读
- 桌面半透明悬浮窗，可调大小/透明度/颜色
- 支持 TXT、EPUB 格式
- 按字数翻页（非章节切换）
- 全局快捷键翻页（任何应用中可用）
- 独立翻页面板，可拖到屏幕任意位置
- 书库管理，自动保存阅读进度
- 启动时自动恢复上次阅读

## 编译运行

需要 macOS 13+ 和 Xcode Command Line Tools。

```bash
# 克隆
git clone https://github.com/mx3353672833-debug/StealthReader.git
cd StealthReader

# 编译 + 打包成 .app
./build-app.sh

# 安装到 Applications
cp -R .build/release-app/StealthReader.app /Applications/

# 运行
open /Applications/StealthReader.app
```

## 使用

1. 点击菜单栏书图标 → **打开文件** 加载 TXT/EPUB
2. 点 **显示桌面** 开启悬浮窗
3. 悬浮窗可拖动、可拖边缘调大小
4. 鼠标悬停悬浮窗显示翻页按钮
5. 设置里可调：每页字数、字号、透明度、颜色、快捷键

## 全局快捷键

首次运行需要授予辅助功能权限（系统会自动弹窗提示）。

默认：`←` 上一页，`→` 下一页。可在设置中自定义。

## License

MIT

# fear-greed-index-for-macos

一个轻量的 macOS 菜单栏小工具，用来在菜单栏显示 Fear & Greed Index。

## 说明

- macOS 第三方菜单栏常驻项目会显示在右上角状态区，这是系统限制。
- 应用每 1 小时自动刷新一次，也支持手动刷新。
- 菜单栏使用小型分段指标图显示，并在图中叠加一个小数字。
- 数据源使用 `fear-and-greed-index.p.rapidapi.com/v1/fgi`。
- 当前版本只依赖 Xcode Command Line Tools，不需要完整 Xcode。

## 运行

```bash
cd "/Users/huangdanyang/Documents/New project/fear-greed-index-for-macos"
chmod +x setup-api-key.command run.sh
./setup-api-key.command
./run.sh
```

`run.sh` 现在会先调用 [build-app.sh](/Users/huangdanyang/Documents/New project/fear-greed-index-for-macos/build-app.sh:1) 生成 `.app`，再直接打开它。整个流程使用 `clang` 编译 [main.m](/Users/huangdanyang/Documents/New project/fear-greed-index-for-macos/main.m:1)，只依赖 Xcode Command Line Tools。

启动后，你会在菜单栏看到一个小型分段 gauge 指标图，图中会叠加一个小数字；点开菜单可以查看完整数值和分类。

API key 不再写在代码里。应用会优先读取环境变量 `FEAR_GREED_RAPIDAPI_KEY`，其次读取 `~/Library/Application Support/fear-greed-index-for-macos/config.plist`。

## 打包

```bash
cd "/Users/huangdanyang/Documents/New project/fear-greed-index-for-macos"
chmod +x build-app.sh
./build-app.sh
open "./dist/fear-greed-index-for-macos.app"
```

打包脚本会：

- 用 `clang` 直接编译 [main.m](/Users/huangdanyang/Documents/New project/fear-greed-index-for-macos/main.m:1)
- 生成标准 `.app` 目录结构
- 写入 [Info.plist](/Users/huangdanyang/Documents/New project/fear-greed-index-for-macos/Info.plist:1)
- 尝试做一次 ad-hoc 签名，减少本地启动阻碍

## 一键安装

你也可以直接双击 [install-to-Applications.command](/Users/huangdanyang/Documents/New project/fear-greed-index-for-macos/install-to-Applications.command:1)。

它会自动：

- 先执行打包脚本
- 请求管理员权限复制到 `/Applications`
- 替换旧版本
- 去掉隔离属性
- 安装完成后自动打开应用

## 开机自启

安装到 `Applications` 后，可以执行：

```bash
cd "/Users/huangdanyang/Documents/New project/fear-greed-index-for-macos"
chmod +x enable-login-launch.command disable-login-launch.command
./enable-login-launch.command
```

这会在 `~/Library/LaunchAgents` 下创建一个 LaunchAgent，让应用在登录 macOS 时自动启动。

如果要关闭开机自启：

```bash
cd "/Users/huangdanyang/Documents/New project/fear-greed-index-for-macos"
./disable-login-launch.command
```

如果你后面想继续做成正式可分发版本，也可以再迁回 Xcode 工程，做归档、签名和公证。

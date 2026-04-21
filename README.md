# fear-greed-index-for-macos

[中文](#中文说明) | [English](#english)

## 中文说明

一个轻量的 macOS 菜单栏小工具，用来在菜单栏显示 Fear & Greed Index。

## 说明
### 功能

- macOS 第三方菜单栏常驻项目会显示在右上角状态区，这是系统限制。
- 应用每 1 小时自动刷新一次，也支持手动刷新。
- 菜单栏使用小型分段指标图显示，并在图中叠加一个小数字。
- 数据源使用 `fear-and-greed-index.p.rapidapi.com/v1/fgi`。
- 当前版本只依赖 Xcode Command Line Tools，不需要完整 Xcode。
- 显示在 macOS 右上角菜单栏状态区
- 使用小型分段指标图显示，并在图中叠加一个小数字
- 启动时立即拉取一次数据
- 应用运行期间每 1 小时自动刷新一次
- 支持菜单内手动刷新
- 支持安装到 `Applications`
- 支持登录 macOS 后自动启动

### 数据源

- `https://fear-and-greed-index.p.rapidapi.com/v1/fgi`
- 需要你自己的 RapidAPI key

### API Key 配置

API key 不会写在代码里。应用会按下面顺序读取：

## 运行
1. 环境变量 `FEAR_GREED_RAPIDAPI_KEY`
2. 本地配置文件 `~/Library/Application Support/fear-greed-index-for-macos/config.plist`

最简单的配置方式：

```bash
cd /path/to/fear-greed-index-for-macos
chmod +x setup-api-key.command
./setup-api-key.command
```

### 运行

```bash
cd /path/to/fear-greed-index-for-macos
chmod +x setup-api-key.command run.sh
./setup-api-key.command
./run.sh
```

`run.sh` 会先调用 `build-app.sh` 生成 `.app`，再直接打开它。整个流程使用 `clang` 编译 `main.m`，只依赖 Xcode Command Line Tools。

启动后，你会在菜单栏看到一个小型分段 gauge 指标图，图中会叠加一个小数字；点开菜单可以查看完整数值和分类。

API key 不再写在代码里。应用会优先读取环境变量 `FEAR_GREED_RAPIDAPI_KEY`，其次读取 `~/Library/Application Support/fear-greed-index-for-macos/config.plist`。

## 打包
### 打包

```bash
cd /path/to/fear-greed-index-for-macos
- 写入 `Info.plist`
- 尝试做一次 ad-hoc 签名，减少本地启动阻碍

## 一键安装
### 安装到 Applications

你也可以直接双击 `install-to-Applications.command`。

- 去掉隔离属性
- 安装完成后自动打开应用

## 开机自启
### 开机自启

安装到 `Applications` 后，可以执行：


这会在 `~/Library/LaunchAgents` 下创建一个 LaunchAgent，让应用在登录 macOS 时自动启动。

如果要关闭开机自启：
关闭开机自启：

```bash
cd /path/to/fear-greed-index-for-macos
./disable-login-launch.command
```

如果你后面想继续做成正式可分发版本，也可以再迁回 Xcode 工程，做归档、签名和公证。
# fear-greed-index-for-macos
## English

A lightweight macOS menu bar app that shows the Fear & Greed Index.

### Features

- Lives in the macOS top-right menu bar area
- Uses a segmented gauge icon with a small numeric overlay
- Fetches data immediately on launch
- Automatically refreshes once every hour while the app is running
- Supports manual refresh from the menu
- Can be installed into `Applications`
- Supports launching automatically at login

### Data Source

- `https://fear-and-greed-index.p.rapidapi.com/v1/fgi`
- Requires your own RapidAPI key

### API Key Setup

The API key is not stored in source code. The app reads it in this order:

1. Environment variable `FEAR_GREED_RAPIDAPI_KEY`
2. Local config file `~/Library/Application Support/fear-greed-index-for-macos/config.plist`

The easiest setup:

```bash
cd /path/to/fear-greed-index-for-macos
chmod +x setup-api-key.command
./setup-api-key.command
```

### Run

```bash
cd /path/to/fear-greed-index-for-macos
chmod +x setup-api-key.command run.sh
./setup-api-key.command
./run.sh
```

`run.sh` builds the app through `build-app.sh` and then opens it. The project uses `clang` to compile `main.m` and only depends on Xcode Command Line Tools.

### Build

```bash
cd /path/to/fear-greed-index-for-macos
chmod +x build-app.sh
./build-app.sh
open "./dist/fear-greed-index-for-macos.app"
```

The build script:

- Compiles `main.m` with `clang`
- Creates a standard `.app` bundle structure
- Writes `Info.plist`
- Applies ad-hoc signing when available

### Install to Applications

You can also double-click `install-to-Applications.command`.

It will:

- Run the build script
- Request administrator permission to copy into `/Applications`
- Replace an existing version
- Remove quarantine attributes
- Launch the app after installation

### Launch at Login

After installing to `Applications`, run:

```bash
cd /path/to/fear-greed-index-for-macos
chmod +x enable-login-launch.command disable-login-launch.command
./enable-login-launch.command
```

This creates a LaunchAgent in `~/Library/LaunchAgents` so the app starts automatically when you log in.

To disable launch at login:

```bash
cd /path/to/fear-greed-index-for-macos
./disable-login-launch.command
```
huangdanyang@Dans-MacBook-Air fear-greed-index-for-macos % git add README.m

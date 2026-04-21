# fear-greed-index-for-macos

一个轻量的 macOS 菜单栏小工具，用来在菜单栏显示 Fear & Greed Index。

## 说明

- macOS 第三方菜单栏常驻项目会显示在右上角状态区，这是系统限制。
- 应用每 1 小时自动刷新一次，也支持手动刷新。
- 菜单栏使用小型分段指标图显示，并在图中叠加一个小数字。
- 数据源使用 `fear-and-greed-index.p.rapidapi.com/v1/fgi`。

## 运行

```bash
cd "/path/to/fear-greed-index-for-macos"
chmod +x setup-api-key.command run.sh
./setup-api-key.command
./run.sh
```


启动后，你会在菜单栏看到一个小型分段 gauge 指标图，图中会叠加一个小数字；点开菜单可以查看完整数值和分类。


## 开机自启

可以执行：

```bash
cd "/path/to/fear-greed-index-for-macos"
chmod +x enable-login-launch.command disable-login-launch.command
./enable-login-launch.command
```

这会在 `~/Library/LaunchAgents` 下创建一个 LaunchAgent，让应用在登录 macOS 时自动启动。

如果要关闭开机自启：

```bash
cd "/path/to/fear-greed-index-for-macos"
./disable-login-launch.command
```

# fear-greed-index-for-macos

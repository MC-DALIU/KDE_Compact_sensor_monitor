# 紧凑监视器 (Compact Monitor)

**一个塞进 KDE Plasma 6 面板的极简硬件监视器。**

[English](README.md) · [简体中文](README.zh_CN.md)

把 CPU、内存、显卡、硬盘、网速、电池、风扇等传感器以**纯文本**形式显示在任务栏上，风格参照
Windows 上的 [TrafficMonitor](https://github.com/zhongyang219/TrafficMonitor)。

![面板上的紧凑监视器](Screenshots/Main.png)

> [!IMPORTANT]
> **本项目由 AI 生成。**
> 仓库里几乎所有代码和文档都是 AI 编程助手根据一系列需求和截图写出来的，之后在真实
> 环境（Manjaro Linux / Plasma 6.7.4 / Wayland）里运行和测试过。它**不是**资深 QML 开发者的手写
> 作品，因此难免有粗糙之处。欢迎提 issue 和 PR——只是提醒一下，维护者读的也是 AI 写的代码。

## 为什么又写一个系统监视器？

Plasma 自带的「系统监视器」用文本模式（`org.kde.ksysguard.textonly`）虽然也能显示数值，但每个
传感器都带着粗大的彩色条和大量内边距，摆几个就把任务栏占满了。这个小部件只画文字，宽度完全跟着
内容走：上面那张图是 10 个传感器、两行。

```
↑ 1.2 KiB/s   CPU 6.9%    GPU 0%    RAM 31.9%   CPU 1.7 GHz
↓ 992 B/s     CPU 44.9 °C BAT 79%   DISK 27.6%  FAN 2,640.0 RPM
```

## 功能

* **小**：只画文字，宽度跟着内容走，可单行或双行
* **两种排列方式**
  * *紧凑* —— 每一行各自居中，最省空间
  * *整齐对齐* —— 表格化：按列填充（1 3 5 / 2 4 6），上传/下载、温度/使用率这类相关传感器会上下相邻
* 整齐对齐时，**名称和数值可以分别设置左 / 居中 / 右对齐**
* **自动识别短名称**：名称留空时自动显示 `CPU`、`RAM`、`DISK`、`FAN`、`BAT`、`↓`…（3–4 个字符，由 ID 推导）
* **字体**：任意已安装字体、可加粗；字号可手动指定 6–48 像素，也可自动适应面板高度
* **逐传感器颜色**，可选在数值前画一条小色条；并带**深浅色主题自动适配**，保证任何主题下都看得清
* **传感器管理**：添加 / 删除 / 上下排序，可搜索的传感器选择器，逐个设置名称与颜色
* **阈值告警**：传感器高于/低于设定值时发送桌面通知；带**回差**（死区）和冷却时间，
  数值在阈值附近来回抖动也不会反复提醒
* **导入 / 导出**：传感器、外观设置、告警规则一并存成 JSON 文件；导入时自动跳过有问题的项并汇总报告
* **外部内容占位**：在传感器旁边留出**一块或多块**区域，任何程序都能往里写内容——见
  [外部内容占位](#外部内容占位)
* **多语言**：内置中文与英文；默认跟随系统语言，也可以单独给这个小部件指定语言。新增一种语言只需
  一个文件，见[翻译](#翻译)
* **细节**：悬停提示列出**全部**传感器（Plasma 自带的提示框布局只画前 8 行，所以本部件自己提供了
  提示内容）、刷新间隔（100ms–10s）、传感器间距、可选分隔符、点击弹出大号视图
* 右键 →「配置 紧凑监视器…」进入 Plasma 标准配置界面

## 截图

| 面板效果                                | 配置 → 外观                     |
| --------------------------------------- | -------------------------------- |
| ![面板上的小部件](Screenshots/Main.png) | ![外观页](Screenshots/Menu1.png) |

| 配置 → 传感器                     |
| ---------------------------------- |
| ![传感器页](Screenshots/Menu2.png) |

| 配置 → 告警                       |
| --------------------------------- |
| ![告警页](Screenshots/Menu3.png)  |

## 运行要求

* KDE Plasma **6**——在 6.7.4（Manjaro / Wayland）上开发，并在 6.3.6（Debian 13）上验证过，后者是
  目前试过的最旧版本
* `libksysguard` —— 提供小部件读取数据用的 `org.kde.ksysguard.sensors` QML 模块
* `ksystemstats` 正在运行（正常 Plasma 会话里本来就有）
* `org.kde.plasma.plasma5support` —— 只有导入/导出会用到（Plasma 6 自带）

纯 QML 小部件：不需要编译、没有 C++、没有构建系统。

## 安装

最省事的方式是下载打包文件——来自 [store.kde.org](https://store.kde.org/p/2374718) 或
[Release 附件](https://github.com/MC-DALIU/KDE_Compact_sensor_monitor/releases)——然后安装它：

```bash
kpackagetool6 --type Plasma/Applet --install compact-monitor-<版本号>.plasmoid
```

或者在面板上点右键 →「添加部件…」→「**从本地文件安装小部件…**」，选中那个 `.plasmoid` 文件。
文件名里的版本号只是用来区分各次发布；真正起作用的是 `.plasmoid` 后缀和包内 `metadata.json` 的
`Id` 与 `Version`，所以**改名不影响安装和更新**。

> [!NOTE]
> Plasma 的「添加部件… → 获取新小部件…」里**搜不到**本部件（第三方 Plasma 6 条目不在那里列出），
> 所以请到商店页面下载文件后按上面的方式手动安装。

想用源码安装则：

```bash
git clone https://github.com/MC-DALIU/KDE_Compact_sensor_monitor.git plasma-compact-monitor
cd plasma-compact-monitor
./install.sh
```

`install.sh` 会安装（或更新）小部件并重启 `plasmashell`：

```bash
./install.sh               # 安装并重启 plasmashell
./install.sh --no-restart  # 只安装
./install.sh --uninstall   # 卸载
```

或者手动：

```bash
kpackagetool6 --type Plasma/Applet --install org.mcdaliu.compactmonitor
# 更新时用 --upgrade，或先 --remove 再 --install
```

`./package.sh` 可以从源码目录生成同一个归档。那个安装对话框和 KDE Store 需要的都是**单个归档**
（`metadata.json` 在归档根目录），所以刚 clone 下来的仓库目录不能这样安装。

然后在面板上点右键 →「添加部件…」→ 搜索 **紧凑监视器**。

> [!WARNING]
> **安装/更新后必须重启 plasmashell。**
> plasmashell 会按插件 ID 缓存小部件的 QML，只把部件删掉重新添加**不会**加载新代码：
>
> ```bash
> systemctl --user restart plasma-plasmashell
> ```
>
> 或者注销重新登录。

## 配置

右键小部件 →「配置 紧凑监视器…」，有两个页面。

### 外观

| 选项               | 说明                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------- |
| 显示行数           | 单行 / 双行                                                                           |
| 排列方式           | *紧凑*：每行各自居中，最省空间；*整齐对齐*：按列填充、列与列对齐（1 3 5 / 2 4 6） |
| 键对齐             | 整齐对齐时，名称在其列内的对齐方式（左 / 居中 / 右，默认左）                          |
| 值对齐             | 整齐对齐时，数值在其列内的对齐方式（左 / 居中 / 右，默认左）                          |
| 传感器间距         | 两个传感器之间的像素间距                                                              |
| 分隔符             | 显示在传感器之间的字符，留空则不显示（表格模式下不会出现在最后一列之后）              |
| 字体 / 字号 / 粗体 | 「跟随系统」或任意已安装字体；6–48 像素，或自动适应面板高度                          |
| 名称               | 是否在数值前显示传感器名称（留空的自定义名称会用自动识别的短名）                      |
| 文字颜色           | 勾选「自定义」后所有文字都用该颜色；不勾选时各用自己传感器的颜色                      |
| 深浅色             | 勾选后按当前主题/面板背景自动调整颜色明暗（浅色调暗、深色调亮），并显示检测结果       |
| 颜色条             | 勾选后，设置过颜色的传感器前面会画一条小色条                                          |
| 外部内容占位       | 留出一块或多块区域显示其它程序推过来的内容（像传感器一样添加）                        |
| 接口文件           | 名为 `music` 的区域读取 `<目录>/music.json`，目录可配置                               |
| 读取间隔           | 多久读一次这些文件——每个间隔一个进程，没配置区域时完全不读                            |
| 内容位置           | 每块区域选择插在传感器的哪个位置，因此可与传感器混排                                  |
| 内容字号           | 可单独设字号，或「跟随」小部件——全高区域尤其有用                                      |
| 界面语言           | 「跟随系统」或任何有语言文件的语言（内置中文与英文）                                  |
| 刷新间隔           | 传感器更新间隔，默认 1000 毫秒                                                        |

页面顶部有实时预览（预览使用**当前已应用**的传感器列表，所以排列、字体、对齐、颜色的改动按「应用」
之前就能看到效果）。

### 传感器

每行一个传感器：色块（点击选颜色）、传感器原名、实时数值与 ID、自定义名称输入框（灰色提示就是留空
时会用的自动短名）、「名称」复选框、上移 / 下移 / 删除按钮。「添加传感器…」打开可搜索的传感器树，
「恢复默认」回到自带的 4 个传感器，「导入…」/「导出…」读写 JSON 文件。

### 告警

每条规则占两行：传感器（带实时数值和 ID）、*高于* / *低于*、阈值、冷却时间（秒）、回差、启用勾选框、
删除按钮。回差右边的灰字会告诉你这条规则什么时候才会重新提醒。「添加告警…」从可搜索的传感器树里挑一个；同一个传感器可以加多条规则（例如电量低于 20、
高于 90）。阈值右边的灰字是它按传感器单位换算后的样子，行里的实时数值可以帮你判断阈值该填多少。

## 阈值告警

规则在传感器越过阈值时通知你：

* **条件** —— *高于* 或 *低于*，与传感器的**原始数值**比较（也就是界面显示的那个数字，尚未做单位换算；
  输入框右边会显示换算后的值，方便对照）
* **回差（死区）** —— 数值要退回到什么程度，规则才允许再次提醒。默认按阈值的 5% 自动计算：
  「CPU 温度高于 80」这条规则要等温度掉回 76 以下才会重新武装，所以 81/79 来回横跳只会提醒一次；
  填 `0` 表示关闭回差。
* **冷却时间** —— 无论发生什么，两次通知的间隔都不会短于这个时间
* **启用** —— 临时关掉规则而不用删除

触发分两步：规则处于**已武装**状态时，数值越过阈值就提醒，然后规则**解除武装**，直到数值退回阈值
以外、且幅度超过回差，才会重新武装。冷却时间则是另一道独立的限制，保证提醒频率不会超过它。

通知走系统的桌面通知服务（`org.freedesktop.Notifications`），所以外观和 Plasma 的其它通知一样，
也受「系统设置 → 通知」影响。触发后的通知长这样：

![阈值告警通知：「CPU 超过阈值 / 当前 100.0%（阈值 90）」](Screenshots/Alert.png)

规则保存在小部件配置里，也会随导出的 JSON 一起走。

## 外部内容占位

插件可以留出**一块或多块**区域，用来显示别的程序推过来的内容：音乐播放器的当前曲目、脚本的输出、编译
状态，什么都行。每块区域有一个名字，**这个名字同时就是它读取的文件名**——"给音乐播放器一块叫 `music`
的区域"，它就往 `~/.cache/compact-monitor/music.json` 里写。不需要库、不需要端口、不需要插件，任何
语言、甚至一个 shell 脚本都能做到。

区域在小部件设置里**单独的「外部内容」页**上配置：名字、插在传感器的哪个位置（可以排在最前面，也可以
插在任意一个传感器之后——所以区域和传感器可以自由混排）、半高还是全高、固定/最小/最大宽度、单独的字号
（或「跟随」传感器），以及没有内容时是否保留空间。默认没有内容时这块区域会自动收起。

高度是按**传感器文字本身**衡量的，不是按面板，所以全高的区域绝不会把小部件顶得比面板还高。整齐对齐
布局下，全高区域会**独占一列**，传感器继续排在它的两侧；紧凑布局下它取传感器文字块的高度。全高的区域
通常配一个更大的字号更好看。

### 协议

把要显示的内容写进该区域的文件——`~/.cache/compact-monitor/<名字>.json`，或「接口文件目录」指定的位置：

* **纯文本** —— 整个文件都会被显示，换行即换行：

  ```bash
  echo "正在播放：某首歌" > ~/.cache/compact-monitor/music.json
  ```

* **一个 JSON 对象** —— 可以指定颜色、对齐方式和更长的悬停提示：

  ```json
  { "text": "CPU 92 °C", "color": "#ff5555", "align": "center", "tooltip": "CPU 温度偏高" }
  ```

  | 字段 | 含义 |
  | --- | --- |
  | `text` | 显示的文字；`\n` 换行 |
  | `color` | 可选，文字颜色，`#rgb`、`#rrggbb` 或 `#aarrggbb` |
  | `align` | 可选，`left`（默认）、`center` 或 `right` |
  | `tooltip` | 可选，鼠标悬停时显示的更长文字 |

文件为空表示"没有内容"。内容一律按**纯文本**渲染，不会被当成标记语言解释；文件只在本地读取，**不会
上传到任何地方**。正好被读到写了一半的文件会被忽略，等它完整了再显示，所以写入方不必小心翼翼；不过
"写临时文件再改名"始终是最稳妥的发布方式。

换成别的语言也一样——插件不关心你是怎么写的：

```python
# Python
import json, pathlib
pathlib.Path.home().joinpath(".cache/compact-monitor/music.json").write_text(
    json.dumps({"text": "正在播放：某首歌", "color": "#66ccff"}, ensure_ascii=False), encoding="utf-8")
```

```bash
# 源码里带了一个小工具
tools/compact-monitor-push --id music "正在播放：某首歌"
tools/compact-monitor-push --id music --color '#66ccff' --align center "某首歌"
tools/compact-monitor-push --id music --clear
```

### 开销

所有占位文件由**同一条命令**读取，而且读取用的是 shell 自己的内建命令，而不是每个区域 fork 一个 `cat`，
所以开销**不随区域数量增长**。在笔记本上实测（5 个区域、1 秒间隔）：

| | 每次读取 | 1Hz 下的占用 |
| --- | --- | --- |
| 1 个区域 | 1.7 ms | 约 0.17% 单核 |
| 5 个区域 | 1.7 ms | 约 0.17% 单核 |
| 对照：空 shell | 1.4 ms | 约 0.14% 单核 |

**没有配置任何区域时完全不执行**；「外部内容」页的「读取间隔」可以调大（2 秒、5 秒……）进一步降低。作为参照：
面板上传感器数据由 `ksystemstats` 每秒更新一次，那部分开销比这里大得多。

## 传感器 ID

传感器列表来自 `ksystemstats`，查看本机全部 ID：

```bash
qdbus6 --literal org.kde.ksystemstats1 /org/kde/ksystemstats1 \
    org.kde.ksystemstats1.allSensors | grep -o '"[a-z0-9/_-]*"'
```

常用 ID：

| 传感器                   | ID                                                                              |
| ------------------------ | ------------------------------------------------------------------------------- |
| CPU 使用率 / 温度 / 频率 | `cpu/all/usage`、`cpu/all/averageTemperature`、`cpu/all/averageFrequency` |
| 物理内存 / 交换分区      | `memory/physical/usedPercent`、`memory/swap/usedPercent`                    |
| 上传 / 下载速率          | `network/all/upload`、`network/all/download`                                |
| 磁盘读 / 写速率          | `disk/all/read`、`disk/all/write`                                           |
| 显卡                     | `gpu/gpu0/usage`、`gpu/gpu0/temperature`、`gpu/gpu0/power`                |
| 风扇 / 温度              | `lmsensors/<芯片名>/fan1`、`lmsensors/<芯片名>/temp1`                       |
| 电池                     | `power/<电池>/chargePercentage`、`power/<电池>/chargeRate`                  |

默认配置是 `network/all/upload`(↑) `network/all/download`(↓) `cpu/all/usage`(CPU)
`memory/physical/usedPercent`(RAM)，双行显示。

## 自动识别的短名称

自定义名称留空时，会按传感器 ID 自动给一个 3–4 字符的短名（`contents/ui/SensorNames.js`）：
先取 ID 的第一段做映射，个别指标再按最后一段细分。

| 传感器 ID                                         | 短名    |  | 传感器 ID                     | 短名 |
| ------------------------------------------------- | ------- | - | ----------------------------- | ---- |
| `cpu/all/usage`、`cpu/all/averageTemperature` | CPU     |  | `power/…/chargePercentage` | BAT  |
| `gpu/gpu0/usage`                                | GPU     |  | `power/…/chargeRate`       | PWR  |
| `memory/physical/usedPercent`                   | RAM     |  | `lmsensors/…/fan1`         | FAN  |
| `memory/swap/usedPercent`                       | SWAP    |  | `lmsensors/…/temp1`        | TEMP |
| `disk/nvme0n1/read`                             | DISK    |  | `lmsensors/…/in0`          | VOLT |
| `network/all/download` / `upload`             | ↓ / ↑ |  | `network/wlp1s0/signal`     | WIFI |

其它情况取第一段大写、截断到 4 个字符（`wifi/foo/bar` → `WIFI`）。想改风格直接编辑
`SensorNames.js` 里的 `GROUPS` / `METRICS` / `HARDWARE_PREFIXES` 三张表。

## 导入 / 导出格式

「传感器」页的「导出…」写出这样的 JSON：

```json
{
  "applet": "org.mcdaliu.compactmonitor",
  "version": 2,
  "exportedAt": "2026-09-25T13:44:10.398Z",
  "appearance": {
    "lineCount": 2, "tableLayout": true, "labelAlignment": 0, "valueAlignment": 2,
    "autoFontSize": true, "fontSize": 12, "fontFamily": "", "bold": true,
    "showNames": true, "itemSpacing": 8, "separator": "", "showColorBar": false,
    "customTextColor": false, "textColor": "#ffffff", "autoAdaptColors": true,
    "updateInterval": 1000
  },
  "sensors": [
    { "sensorId": "network/all/upload", "label": "↑", "color": "#2ec27e", "showLabel": true },
    { "sensorId": "cpu/all/usage", "label": "CPU", "color": "#e5a50a", "showLabel": true }
  ],
  "alerts": [
    { "sensorId": "cpu/all/usage", "condition": "above", "threshold": 90, "cooldown": 300,
      "enabled": true, "hysteresis": -1 }
  ]
}
```

告警规则里的 `hysteresis` 是回差：填数字表示具体数值，`0` 表示关闭，`-1`（或省略）表示按阈值的
5% 自动计算。

导入时也接受直接给一个数组。`appearance` 和 `alerts` 两段都可以省略，所以旧版本导出的文件照样能导入。
只有 `sensorId` 是必需的，`label`/`color`/`showLabel` 都可以省略
（`color` 除 `#rrggbb` 外也接受 KDE 的 `r,g,b` 写法，`showLabel` 接受 `true/false/1/0`）。逐项检查，
有问题的项**跳过并汇总报告**到页面顶部的提示条（最多列 8 条，同时写进 plasmashell 日志）：

| 情况                       | 处理                             |
| -------------------------- | -------------------------------- |
| 不是对象、缺少 `sensorId` | 跳过                             |
| 本机没有这个传感器 ID      | 跳过                             |
| 同一个 ID 出现多次         | 后面的跳过                       |
| 颜色无法识别               | 保留该项、忽略颜色（算一条提示） |
| 外观设置的数值超出范围     | 收敛到允许范围内并报告           |
| 外观设置的类型不对         | 保持原值并报告                   |
| 告警规则缺少 `sensorId`、传感器不存在、阈值不是数字 | 跳过 |
| 告警规则的回差是负数或不是数字 | 按自动处理，并报告           |
| JSON 解析失败 / 文件读不到 | 红色错误提示，不导入任何内容     |

导入会**替换**当前传感器列表、写入外观设置、替换告警规则。外观改动会立刻写进小部件配置，所以下次
打开「外观」页就能看到。

## 实现要点（踩坑记录）

* 传感器数据用 libksysguard 的 QML 模块 `org.kde.ksysguard.sensors`（`Sensor` /
  `SensorTreeModel`），底层是 `ksystemstats`，与系统监视器共用同一套数据，**不需要**任何 C++。
* 面板布局只读取 **applet 根对象** 的 `Layout.preferredWidth` / `implicitWidth` 来决定部件宽度
  （见 plasma-desktop `containments/panel/contents/ui/main.qml`），所以 `main.qml` 把紧凑表示的
  宽度镜像到了根对象上；只设置紧凑表示自身的尺寸会被当成最小宽度（28px）。
* 自动字号由面板给的高度反推：`min(高度/行数 × 0.78, gridUnit × 0.8)`，并限制在 7–28 像素之间。
* 深浅色适配（`contents/ui/ColorUtils.js`）走 WCAG 相对亮度/对比度：只调整**明度**、保留色相与
  饱和度，用二分法找到"刚好达到 4.0:1 对比度"的颜色，所以绿色不会像直接 RGB 反相那样变成品红。
  背景色取 `Kirigami.Theme.backgroundColor`——面板里 Plasma 会通过 ColorScope 把面板背景色传进来，
  所以"深色面板 + 浅色主题"这种组合也能判断正确。
* 文件读写没有 C++ 侧 API 可用，走 `org.kde.plasma.plasma5support` 的 `executable` 数据引擎：
  命令**经过 shell** 执行，所以 `printf %s … > 文件` 这种重定向可以直接用；注意完成事件的键名是
  `"exit code"`（带空格）而不是 `exitCode`，输出还可能分多次到达，需要自己累加。
* 配置对话框会把 `cfg_<配置项名>` 作为初始属性传给配置页，保存时再读回来写进配置，因此配置页里
  所有可编辑值都命名为 `cfg_*`。
* `Kirigami.FormLayout` 按子项的 **`implicitHeight`** 决定行高，只写 `Layout.preferredHeight` 会被
  当成 0 高度（而且绑定求值太早看不到子项），让子项溢出到上一行；而标了
  `Kirigami.FormData.isSection: true` 的项才会跨两列，否则会被放进「字段」列、整体偏右。
* Qt 6 里 delegate 一旦声明了 `required property`，模型角色就不再注入上下文，`index` 也要显式声明
  `required property int index`。
* 逐传感器颜色优先于全局自定义颜色，所以「自定义文字颜色」做成**覆盖式**：勾选后所有文字统一用它，
  传感器颜色只留给色条。
* 配置页里用 `import ".."` 相对导入父目录的 `SensorView.qml` 才能在外观页里做实时预览。
  预览内容比配置窗口宽时不是用 `scale` 变换缩小的：变换缩放会让字形重新栅格化，笔画看起来粗细
  不均。改成缩小**字号**直到内容放得下，宽度用一个隐藏副本测量（量可见的那个会和结果互相影响、
  来回抖动）。另外预览没放在 `Kirigami.FormLayout` 里——那里的 section 项不会拉伸到页面宽度，
  预览会一直只有表单隐式宽度那么宽。
* 告警状态按**规则内容本身**做 key，而不是按它在列表里的位置：读 `Plasmoid.configuration`
  会让"规则列表"那个绑定重新求值（即使规则内容没变——配置映射终究不是普通属性），如果这时候重置
  状态，一小时冷却也拦不住第二次通知。
* 用脚本接口写**只有一个元素的 `StringList` 会写坏它**：`writeConfig("placeholders", ["a|b|c"])`
  会把值按字符用逗号存进去，而且每读写一次就多一层转义，读回来甚至还是字符串而不是列表。这类设置请走
  配置对话框（正常路径），或者停掉 Plasma 后手动编辑 `plasma-org.kde.plasma.desktop-appletsrc`。
* 桌面通知同样走 `executable` 数据引擎：`gdbus call` 调
  `org.freedesktop.Notifications.Notify`，每个参数都用 `ShellUtils.quote()` 包好（面板上的
  panel-spacer 部件也是这么做的）。告警规则按 `sensorId|条件|阈值|冷却|启用|回差` 一条字符串存在
  StringList 里，由 `contents/ui/AlertRules.js` 编解码。
* QML 的 JavaScript 里不要在 `const` / `let` 声明之前使用它：那是暂时性死区错误，而且发生在信号
  处理函数里时，函数剩下的部分会被静默跳过（调告警时被这个坑了一晚上）。
* 配置页里**没有 `Plasmoid` 对象**：配置对话框用自己的上下文加载配置页，所以读
  `Plasmoid.configuration` 会抛 "ReferenceError: Plasmoid is not defined"，并且**静默**打断该函数
  剩下的部分（本项目的导入导出就是这么坏的，最后靠
  `journalctl --user -u plasma-plasmashell` 才看出来——而 offscreen 测试里我把 `Plasmoid` 打了桩，
  恰好把被测对象本身替掉了）。页面需要什么值，就声明成 `cfg_*` 属性：对话框会把**每一个**配置键
  交给当前页面（`props["cfg_" + key] = config[key]`），保存时把页面声明过的键写回。所以传感器页
  也声明了外观设置和告警规则——它们要跟着它的 JSON 文件一起走。另外 Plasma 还会额外提供
  `cfg_<key>Default`（给"恢复默认"用），所以日志里会抱怨 `cfg_lineCountDefault` 之类未知属性，
  这部分无害。
* 外部内容是**轮询**而不是流式读取：QML 没有文件 API，而 `executable` 数据引擎只在命令结束后才返回输出
  ——实测中长驻的 `tail -F` 一行都拿不到，所以只能每个刷新间隔 `cat` 一次。
* 不要把 QML 的类型关键字当作 JS 标识符：较旧的 QML 引擎（如 Debian 13 的 Qt 6.8）会把
  `short`、`color`、`list`、`url`、`action`、`real`、`int` 之类直接判为 "Expected token
  `identifier`" 而拒绝解析，Qt 6.9 则接受。所以颜色对话框的属性叫 `selectedColor` 而不是 `color`、
  区域设置里的变量叫 `shortCode`；也正因如此，改这类名字时必须把**所有引用处**一起改，而不只是声明处。
* 翻译是 `contents/i18n/` 下每种语言一个 QML 文件，由一个单例（`contents/ui/i18n/I18n.qml`）查表；
  界面里的绑定会读取它的 `strings` 属性，所以换语言时整个界面会自动重新求值，不用重启任何东西。
  至于为什么不用 `i18n()` / `.po`，见[翻译](#翻译)。
* Plasma 自带的提示框布局把 `subText` 限制在 8 行（`org.kde.plasma.core/DefaultToolTip.qml` 里的
  `maximumLineCount: 8`），传感器一多就会被悄悄截断。所以本部件把
  `contents/ui/ToolTipContent.qml` 作为 `toolTipItem` 交给外壳；它放在一个不可见的宿主里，这样在
  提示框接管它之前不会画到部件上。**注意**：`toolTipItem` 是 `PlasmoidItem` 自己的属性，**不是**
  `Plasmoid` 上下文对象的属性——写成 `Plasmoid.toolTipItem: ...` 会让整个部件加载失败并报
  "Cannot assign to non-existent property"，这个报错可以用
  `journalctl --user -u plasma-plasmashell` 看到。`toolTipTextFormat` 是同一个坑——它同样是
  `PlasmoidItem` 的属性。
* 配置页里所有会换行的说明文字都用 `HintLabel`：`QQC2.Label` 打开 `wrapMode` 后 `implicitWidth`
  仍是不换行的整行宽度，直接放进 `Kirigami.FormLayout` 会把整个表单撑宽，窗口比它窄时右侧内容就被
  切掉。同理，传感器列表里带 `elide` 的长 ID 也必须显式 `Layout.minimumWidth: 0`。

## 常见问题

| 现象                                       | 原因 / 处理                                            |
| ------------------------------------------ | ------------------------------------------------------ |
| 更新后小部件什么都不显示，或变成一个小方块 | 要么是 plasmashell 的 QML 缓存（重启 plasmashell），要么是 QML 报错：`journalctl --user -u plasma-plasmashell` 会打印出错的文件和行号 |
| 某个传感器一直显示 `--`                   | 本机没有这个传感器 ID，用选择器确认一下                |
| 颜色看起来发灰                             | 那是自动对比度调整，把「深浅色」关掉就保持原色         |
| 小部件太宽                                 | 减少传感器、关掉名称、调小字号，或改用「紧凑」排列     |
| 占位区一直是空的 | 确认已启用、确认「数据文件」就是你写入的那个文件、确认文件不是空的；它是每个刷新间隔读一次 |
| 想删掉                                     | `./install.sh --uninstall`，再把面板上残留的图标移除 |

## 已知限制 / 后续可做

* 数值没有定宽对齐，长度会随数字变化（整齐对齐至少能保证列本身稳定）
* 还不支持曲线、历史图表
* 目前只翻译了中文和英文，其它语言每种一个文件即可，见[翻译](#翻译)

## 翻译

翻译文件在 `org.mcdaliu.compactmonitor/contents/i18n/`，一种语言一个文件——英文是 `en.qml`：

```qml
import QtQuick

QtObject {
    readonly property var strings: ({
        "外观": "Appearance",
        "%1 秒": "%1 seconds"
    })
}
```

**键**就是界面里的中文源字符串，必须保持原样；`%1`、`%2`… 会被调用时的参数替换，所以翻译里可以
调整它们的顺序。文件里缺少某个键时，会回退显示中文源字符串，因此**翻一半也能用**。

新增一种语言：

1. 把 `contents/i18n/en.qml` 复制成 `<语言代码>.qml`（用 Qt 认识的代码，如 `de`、`fr`、`pt_BR`）
2. 翻译**值**，别动键
3. 把该语言加进 `contents/ui/i18n/I18n.qml` 的 `supportedLanguages`
4. 试一下：默认跟随系统语言，也可以在外观页的语言下拉框里手动切换

中文不需要文件——源字符串本身就是中文。补充说明：这里用映射表而不是 `i18n()` 查表，是因为纯 QML
的小部件无法在运行时切换 `i18n()` 的语言；而可能想到的 JSON 文件也读不了（Qt 在没有
`QML_XHR_ALLOW_FILE_READ=1` 时拒绝 `file://` 的 XHR）。

## 参与贡献

欢迎提 issue、贴自己面板的截图、提 PR。用户可见的改动请写进
[CHANGELOG.md](CHANGELOG.md) 的 *Unreleased* 段。发版流程：归入新的版本段 → 把
[`metadata.json`](org.mcdaliu.compactmonitor/metadata.json) 里的 `KPlugin.Version` 改成同一个版本号
→ 跑 `./package.sh` → 打 `v<版本号>` 的 Git tag 并把 `.plasmoid` 作为附件传到 GitHub Release
（顺便上传到 store.kde.org）。改 QML 的话请至少跑一下

```bash
qmllint org.mcdaliu.compactmonitor/contents/ui/*.qml
```

并在测试时重启 plasmashell。也请注意本项目由 AI 生成，欢迎指出其中的不一致之处。

## 致谢

* [KDE](https://kde.org) Plasma、[libksysguard](https://invent.kde.org/plasma/libksysguard) 和
  `ksystemstats` 提供了传感器基础设施
* [TrafficMonitor](https://github.com/zhongyang219/TrafficMonitor) 提供了最初的灵感和想要接近的外观
* 截图使用 Breeze 主题

## 许可证

GPL-2.0-or-later —— 见 [LICENSE](LICENSE)。每个源文件都带 SPDX 头；`LICENSE` 文件是 GPL-2.0 全文，
"or later" 由这些源文件头表达。

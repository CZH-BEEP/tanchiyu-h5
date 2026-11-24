# 轨道残骸站：微信小游戏质量改造计划

## Context

用户反馈当前《轨道残骸站》仍像粗糙 H5 原型：UI 有占位感、图标体系不真实、场景没有产品感、玩法反馈弱。目标是把它升级到接近微信小程序游戏的质量：统一视觉、真实图标、明确目标闭环、首局引导、反馈演出、可输可赢、手机端稳定可玩。

约束：
- 保持静态 H5，支持 GitHub Pages 和双击运行。
- 保持 `orbit/index.html` 单文件内联 CSS/JS。
- 图片资产继续使用 `orbit/icons/*.png`，不使用 emoji 或外链素材。
- 不引入构建工具、npm、框架或 CDN。

## Critical Files

- `orbit/index.html`：核心页面、样式、玩法逻辑、存档逻辑全部在这里。
- `orbit/icons/*.png`：当前本地图标资产，后续全部 UI 图标必须从这里取。
- `index.html`：大厅入口，仅在最终需要更新展示文案时微调。

## Recommended Implementation

### 1. 建立轻量组件体系

在 `orbit/index.html` 内新增/整理 JS 模板函数：

- `uiIcon(name, size)`
- `uiBadge(icon, value, label, state)`
- `uiButton({ id, icon, label, type, disabled })`
- `uiProgress(value, state, label)`
- `uiPanel(title, body, className)`
- `uiCost(costObject)`
- `uiResourceDelta(deltaObject)`

目的：HUD、资源、建筑、英雄、按钮、任务条都走同一套组件，不再各写各的。

验收：页面不再出现 emoji、临时符号或裸数字；数值全部在“图标 + 数值”徽章中。

### 2. 统一视觉设计令牌

完善 `:root`：

- 深空背景色、主蓝、警告橙、危险红、成功绿。
- 统一圆角、2px 描边、按钮高度、图标尺寸、卡片内边距。
- 统一面板内发光、按钮阴影、警告态红光、完成态金光。

验收：HUD、面板、按钮、建筑卡、英雄卡、任务卡看起来属于同一套微信小游戏 UI。

### 3. 重做主场景表现

保留 DOM 实现，不上复杂 Canvas。

场景拆成：

- `scene-bg`：星空、漂浮星尘、深空渐变。
- `orbit-ring`：轨道环、扫描线、事件颜色反馈。
- `station-core`：用真实 PNG 图标替换 `◎`。
- `station-modules`：已建舱段围绕核心排布，用对应 PNG 图标展示。
- `debris-field`：固定残骸层，不再每秒随机重建。
- `event-banner`：用图标、颜色、短标题表达太阳风暴/陨石雨/辐射潮/补给船。

验收：第一屏像“轨道空间站经营游戏”，不是数据面板。

### 4. 强化核心玩法闭环

整理玩法为：

1. 拾荒：获得残骸和信用点，消耗精力。
2. 出舱：高收益，消耗氧气和 EVA 时间。
3. 建造：解锁 10 种功能舱，视觉上接入空间站。
4. 加工：把残骸、水、电转换成氧气、合金、食物、信用点。
5. 乘员管理：健康、氧压、饱食、士气四条状态。
6. 推进航线：3 章 × 8 关。

需要拆分：

- `manualProcess()`：玩家点击加工，有音效和反馈。
- `autoProduce()`：定时产出，不弹重复 toast。

新增：

- `getCurrentObjective(S)`：当前目标卡。
- 胜利条件：完成 III-08 或建成关键舱段并完成最终航线。
- 失败条件：健康归零、氧气长期归零、补给崩溃。

验收：玩家不用读长说明也知道下一步做什么，并且游戏能输能赢。

### 5. 首局引导

新增存档字段：

- `guideStep`
- `guideDone`
- `hasSeenIntro`
- `saveVersion`

引导控制在 5 步：

1. 欢迎接管残骸站。
2. 高亮“拾荒”。
3. 高亮“建造太阳翼”。
4. 高亮“加工”。
5. 高亮“推进航线”。

实现方式：

- `renderGuide()`
- `advanceGuide(action)`
- `.guide-focus` 发光高亮
- 支持跳过和刷新恢复。

验收：首局 30 秒内完成“拾荒 → 建造 → 加工 → 推进”的完整闭环。

### 6. 反馈演出升级

新增 `#fxLayer` 和浮字系统：

- `spawnFloatText(text, type, anchor)`
- `flashPanel(target, type)`
- `playBuildFx(moduleId)`
- `playRouteFx()`
- `playEventFx(eventType)`

反馈分级：

- 轻反馈：按钮按压、资源数字跳动。
- 中反馈：建造完成、加工完成、事件触发。
- 重反馈：章节推进、失败、胜利。

验收：每次关键点击都有明确“结果感”，不是数字静默变化。

### 7. 存档与重开

重构状态初始化：

- `defaultState()`
- `loadState()`
- `normalizeState(raw)`
- `saveState()`
- `resetRun(keepSettings)`

增加：

- 存档版本。
- 坏档兜底。
- 老存档补字段。
- 胜利/失败后重开。
- 设置弹窗里支持清档、重看引导、音效开关。

验收：刷新不丢进度，坏 localStorage 不白屏，双击运行正常。

### 8. 移动端打磨

- 底部主操作按钮高度不小于 44px。
- 顶部徽章横向滚动但不挤压。
- 建筑区在手机上更像卡片列表，不像网页表格。
- 禁用按钮显示原因。
- `touch-action: manipulation`。

验收：手机竖屏能单手玩，首屏就能看到场景、目标和主操作。

## Verification

实施后验证：

1. 新用户流程：打开 → 引导 → 拾荒 → 建造太阳翼 → 加工 → 推进 I-02。
2. 普通循环：拾荒、出舱、建造多个舱段、加工、休整、事件触发。
3. 失败流程：资源耗尽或健康归零后出现失败界面，可重开。
4. 胜利流程：推进至最终航线后出现胜利界面。
5. 存档：刷新、关闭再开、坏档、旧档都能恢复或兜底。
6. 环境：本地双击、GitHub Pages、手机竖屏。
7. 视觉：页面没有 emoji/临时符号/裸数字，图标统一来自 `orbit/icons`。

## Execution Order

1. 组件体系 + 设计令牌。
2. 场景主视觉重做。
3. 玩法闭环和目标卡。
4. 首局引导。
5. 反馈演出。
6. 存档/胜败/重开。
7. 移动端验证和推送。

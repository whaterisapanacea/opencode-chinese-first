# 中文优先 · opencode-chinese-first

让 OpenCode 在桌面端和命令行端默认使用简体中文进行思考、计划和回答。即使用户用英文提问，也保持中文；代码、命令、路径、日志、专有名词等必须保留原文的内容除外。

## 特性

- **全局生效**：桌面端与 CLI 共用 `~/.config/opencode` 全局配置。
- **默认常驻**：通过全局 `instructions` 注入技能内容，不依赖模型是否主动加载技能。
- **保留原文**：代码、命令、路径、错误日志、专有名词不强行翻译。
- **可覆盖**：用户明确要求其他语言时，只在该请求范围内切换。
- **无依赖**：纯 Markdown，不需要额外运行时。

## 默认生效原理

OpenCode V2 的技能本身是按需加载的，配置里没有“技能级别”字段。本项目用两步让中文成为默认：

1. 把 `SKILL.md` 安装到全局技能目录 `~/.config/opencode/skills/chinese-first/`；
2. 把 `SKILL.md` 加入全局 `opencode.jsonc` 的 `instructions` 数组。

这样桌面端和 CLI 的每个会话都会加载同一份语言规则，同时该技能也会出现在可用技能列表中，可以用 `@chinese-first` 手动加载。

## 安装

### 方式一：安装脚本

Windows PowerShell：

```powershell
git clone https://github.com/whaterisapanacea/opencode-chinese-first.git
cd opencode-chinese-first
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

macOS / Linux：

```sh
git clone https://github.com/whaterisapanacea/opencode-chinese-first.git
cd opencode-chinese-first
sh ./install.sh
```

脚本会复制技能文件，并在全局配置没有 `instructions` 字段时自动加入；如果已经存在该字段，会打印需要手动合并的片段，不会覆盖现有配置。

### 方式二：手动安装

1. 创建技能目录：

   ```powershell
   New-Item -ItemType Directory -Force "$HOME\.config\opencode\skills\chinese-first"
   ```

2. 把仓库中的 `SKILL.md` 复制到该目录：

   ```powershell
   Copy-Item .\SKILL.md "$HOME\.config\opencode\skills\chinese-first\SKILL.md"
   ```

3. 编辑 `~/.config/opencode/opencode.jsonc`，加入：

   ```jsonc
   {
     "$schema": "https://opencode.ai/config.json",
     "instructions": [
       "~/.config/opencode/skills/chinese-first/SKILL.md"
     ]
   }
   ```

   如果已经有 `instructions` 数组，把路径追加进去即可，不要重复创建同名键。

4. 重启 OpenCode，或运行：

   ```sh
   opencode reload
   ```

### 验证

```sh
opencode debug config
```

输出中应能看到 `instructions` 包含 `chinese-first/SKILL.md`。

再用英文提一个测试问题：

```sh
opencode run "Answer in one sentence: what is your default response language?"
```

如果规则生效，回答应使用中文。

## 使用

安装后默认自动生效，不需要每次手动选择技能。

需要手动加载或查看技能时，可以在提示词中写：

```text
@chinese-first
```

也可以让模型通过 `skill` 工具加载，技能 ID 为 `chinese-first`。

## 规则摘要

- 内部推理、计划、解释和最终回答默认使用简体中文。
- 用户用英文提问时仍先回答中文，除非用户明确要求英文。
- 代码、标识符、命令、路径、URL、日志、错误堆栈、许可证文本等保持原文。
- 有通用中文译名的术语用中文；没有通用译名的保留英文并用中文解释。
- 中文与英文、数字之间按常见排版加空格；代码块内部不改写。
- 不要反复声明“我将使用中文回答”。

完整规则见 [`SKILL.md`](./SKILL.md)。

## 卸载

1. 删除技能目录：

   ```powershell
   Remove-Item -Recurse -Force "$HOME\.config\opencode\skills\chinese-first"
   ```

2. 从 `~/.config/opencode/opencode.jsonc` 的 `instructions` 数组中移除对应路径。

3. 运行 `opencode reload` 或重启 OpenCode。

## 兼容性

- 面向 OpenCode V2。
- 桌面端和 CLI 共用同一份全局配置，安装一次即可同时生效。
- 如果项目内有自己的 `AGENTS.md` 或 `instructions`，它们会与本规则合并；项目明确要求其他语言时，以项目要求为准。

## 许可证

本项目使用 [Mozilla Public License 2.0](./LICENSE)（MPL-2.0）。

This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at <https://mozilla.org/MPL/2.0/>.

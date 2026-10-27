# HBuilderX Push Light — 完整颜色清单（VSCode 主题）

> 本源：VSCode 扩展 `ZQun.theme-hbuilderx-push-light`（HBuilderX Push Light，基于
> **HBuilderX Soft Green Light**）。下文是从 Marketplace 下载的 vsix 包（v1.0.6）与
> GitHub master 分支（`ZQun/theme-hbuilderx-push-light`，已做 2024-05-11 Mac 视网膜
> 校准 `#fffae6 → #fffae8`）逐字比对、剔除注释后的**完整、无截断**原始数据。
>
> 源文件（唯一主题文件）：
> - Marketplace VSIX：`https://marketplace.visualstudio.com/items?itemName=ZQun.theme-hbuilderx-push-light`
> - GitHub：`https://github.com/ZQun/theme-hbuilderx-push-light/blob/master/themes/hbuilderx-soft-green-light-color-theme.json`
> - 与 GitHub master 的唯一差异：所有 `#fffae6` 在 master 上已改作 `#fffae8`（下文使用 master 值）。

## 关键配色速查

| 语义 | 值 |
| --- | --- |
| editor.background（画布主背景） | `#fffae8` |
| editor.foreground（正文） | `#404b53`（深灰蓝） |
| editor.selectionBackground（选区） | `#eee8d5`（米白） |
| editor.lineHighlightBackground（当前行） | `#e8dfc4` |
| 强调绿 accent | `#41a863` |
| 符号/徽标黄 | `#b58900` |
| statusBar/sideBar/terminal 背景同主背景 | `#fffae8` |
| terminal.foreground | `#616161` |
| 主题类型 | light（`"type": "light"`） |

## 一、colors（75 个活动键；另有大量 `//` 注释掉的备用配色，属于作者留作可选覆盖，默认不生效）

```
activityBar.activeBorder = #41a863
activityBar.background = #fbf5e1
activityBar.foreground = #584c27
activityBarBadge.background = #b58900
button.background = #b58900
button.hoverBackground = #cc9a00
dropdown.background = #fffae8
dropdown.border = #d8ca9e
editor.background = #fffae8
editor.foreground = #404b53
editor.lineHighlightBackground = #e8dfc4
editor.selectionBackground = #eee8d5
editorGroup.border = #d8ca9e
editorGroupHeader.tabsBackground = #fffae8
editorIndentGuide.activeBackground = #d8ca9e
editorIndentGuide.background = #f7f2e4
editorLineNumber.foreground = #9f9371
editorWhitespace.foreground = #404040
editorWidget.background = #eee8d5
focusBorder = #41a863
input.background = #fffdf4
input.border = #d8ca9e
input.foreground = #586e75
input.placeholderForeground = #586e75aa
inputOption.activeBorder = #41a863
list.activeSelectionBackground = #e0edd3
list.activeSelectionForeground = #41a863
list.focusBackground = #dfca8866
list.highlightForeground = #b58900
list.hoverBackground = #e0edd3
list.inactiveSelectionBackground = #e0edd3
list.inactiveSelectionForeground = #41a863
notifications.background = #fffae8
panel.border = #d8ca9e
panelTitle.activeBorder = #41a863
scrollbarSlider.activeBackground = #cfb56a
scrollbarSlider.background = #cfb56a99
scrollbarSlider.hoverBackground = #cfb56a
sideBar.background = #fffae8
sideBar.border = #d8ca9e
sideBarSectionHeader.background = #fffae8
sideBarTitle.foreground = #586e75
statusBar.background = #fffae8
statusBar.debuggingBackground = #41a863
statusBar.debuggingForeground = #fffae8
statusBar.foreground = #586e75
statusBar.noFolderBackground = #eee8d5
statusBarItem.activeBackground = #ded0a0
statusBarItem.hoverBackground = #eae0c0
statusBarItem.prominentBackground = #ddd6c1
tab.activeBackground = #d9eee0
tab.activeForeground = #2a2a2a
tab.border = #fffae8
tab.inactiveBackground = #fffae8
tab.inactiveForeground = #41a863
terminal.ansiBlack = #000000
terminal.ansiBlue = #5597ef
terminal.ansiBrightBlack = #686868
terminal.ansiBrightBlue = #7faff4
terminal.ansiBrightCyan = #6fdada
terminal.ansiBrightGreen = #74fa61
terminal.ansiBrightMagenta = #fe9cff
terminal.ansiBrightRed = #fe8885
terminal.ansiBrightWhite = #f1f1f1
terminal.ansiBrightYellow = #e2d301
terminal.ansiCyan = #39cbcc
terminal.ansiGreen = #097e00
terminal.ansiMagenta = #fe76ff
terminal.ansiRed = #fd6c67
terminal.ansiWhite = #bbbbbb
terminal.ansiYellow = #cdcb00
terminal.background = #fffae8
terminal.foreground = #616161
titleBar.activeBackground = #eee8d5
tree.indentGuidesStroke = #d8ca9e
```

> 注：editorCursor.foreground 未在活动键中出现（文件里被注释为 `#000000`，见"备用键"）。
> 启用态里没有明确 cursor 颜色，Neovim 侧可用 `#404b53` 或 `#41a863` 作为 Cursor。

## 二、tokenColors（87 条规则，scope → foreground / style）

按作者书写顺序列出（未排序，与文件一致）：

```
console.error                → #CA0000
console.input                → #00AE50
console.prompt               → #B651BC  style=bold
console.warning              → #CD6600
console.debug                → #5D6666
hyperlink                     → #0D1171
markup.deleted               → #FFFFFF
markup.inserted              → #000000
markup.changed               → #F8F8F8
markup.underline             → style=underline
markup.bold                  → style=bold
markup.italic                → style=italic
property                     → #934B3C
comment                      → #95A3AB
constant                     → #cd0084
constant.other.placeholder.py→ #7B0000
entity                       → #CC3611
entity.name.type             → #6C65B0
entity.other.inherited-class → #000000
entity.name.function         → #DB7800
entity.name.function.argument→ #A28D00
entity.name.tag              → #2369B6
entity.other.attribute-name  → #CB2D01
keyword                      → #577909  style=bold
keyword.control              → #829d00
storage                      → #473cc4  style=bold
token.storage.js, token.storage.ts → #577909 style=bold
keyword.operator.expression.delete.js / in.js / of.js / instanceof.js
    / keyword.operator.new.js / typeof.js / void.js → #577909 style=bold
meta.selector                → #577909  style=bold
string | punctuation.definition.string → #2aa198
string, entity.other.inherited-class  → #348f85
Number                       → #9B3AFF
support                      → #3C7A03
variable                     → #404b54
variable.parameter           → #404b54
keyword.operator             → #839e00
keyword.operator.logical.js/ts→ #CA004B
keyword.operator.arithmetic.js/comparison.js/ts → #56B6C2
invalid.deprecated           → #333333
invalid.illegal              → #333333
string source                → #080808
String constant              → #696969
string variable              → #234A97
string.regexp                → #CF5628
[regexp.character-class, constant.character.escaped, source.ruby.embedded,
 arbitrary-repitition]      → #CF5628
string.regexp constant.character.escape → #811F24
text source                  → #080808
function name                → #AE7A00
function argument            → #99A600
support.function             → #CA004B
support.constant             → #C44F00
support.variable             → #295502
entity.name.type.namespace   → #3f4b53
support.class, entity.name.type.class → #4488d5
entity.name.class.identifier.namespace.type → #E5C07B
entity.name.class            → #61AFEF
entity.name.type             → #4488d5
support.constant.color.w3c-standard-color-name.css/scss → #D19A66
support.constant.color...css, entity.other.attribute-name.class.css → #D19A66
support.type.vendored.property-name.css → #56B6C2
punctuation.definition.template-expression.{begin,end}.js/ts → #404b54
support.module.node.js ... → #E5C07B
variable.other.readwrite.js, meta.object-literal.key.js, ... → #404b54
support.constant.json.js/ts  → #D19A66
keyword.operator.expression.instanceof.js/ts → #577909
keyword.operator.expression.typeof.js/ts → #577909
support.type.object.console.js/ts → #404b44
entity.name.function.js, support.function.console.js/ts → #a97b00
keyword.operator.js/ts            → #56B6C2
support.type.object.dom.js/ts     → #56B6C2
support.variable.dom.js / property.dom.js / ts → #404b53
var.this.js/ts, variable.language.this.js/ts → #4488d7
markup.list  → #7D451C
markup.heading / heading.entity.name → #142B5A
markup.quote → #0B6125
markup.italic → #080808
markup.bold  → #080808  style=bold
markup.underline → #080808 style=underline
markup.link  → #234A97  style=underline
markup.raw   → #234A97
markup.deleted → #47565F
markup.inserted → #CC0000
markup.changed → #FFFFFF
token.infor-error-token…（作者自用 token）
token.info-token  → #316BCD
token.warn-token → #CD9731
token.error-token → #CD3131
token.debug-token → #800080
```

## 三、Neovim 映射建议（语义对准）

| VSCode scope | Neovim hl-group | 颜色 |
| --- | --- | --- |
| comment | Comment, CommentSQL | `#95A3AB` |
| keyword / storage / keyword.operator.expression | Keyword, StorageClass | `#577909`（粗体） |
| storage | StorageClass | `#473cc4`（粗体） |
| entity.name.function / function | Function | `#DB7800` / `#AE7A00` |
| string / punctuation.definition.string | String | `#348150`（主）/ `#2aa198`（定义引号） |
| Number / constant | Constant, Number | `#9B3AFF` / `#cd0084` |
| entity.name.type / support.class | Type | `#4488d5` |
| variable / variable.parameter | Identifier | `#404b54` |
| keyword.operator（算术/比较） | Operator | `#56B6C2` |
| logic | 运算符逻辑 | `#CA004B` |
| punctuation（并入 strings/命名空间） | 标点可随正文 | `#404b53` |
| meta 标签 / entity.name.tag | 标签 | `#2369B6` |
| attribute | 属性 | `#CB2D01` |
| 预定义 support | Support | `#3C7A03` |

> 可移植/更中性的取色建议：Neovim LSP语义映射时优先用 subject 的顶层 scope
> （comment / string / keyword / storage / entity / support / variable / constant /
> function / number）。作者所用字体为无衬线等宽，可忽略 style=italic 差异。
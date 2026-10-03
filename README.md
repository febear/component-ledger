# Component Ledger / 组件引用增量台账

MoonBit 编写的确定性统计内核与命令行程序。输入一个仓库的完整组件引用快照及后续版本事件，输出组件引用数、引用文件数、逐事件增量和重复事件回执。

用途：组件资产统计的 CI 任务经常重跑，分支事件可能乱序到达。直接累加 MR 增量容易重复计数或用旧结果覆盖新状态。本项目把版本前置条件、重放去重和完整快照统计放在一个可测试内核中。

状态：公开申报原型，未立项、未获奖。赛事是否认可选题和工作量，须由主办方审核。

## 运行

包中附带已编译 CLI，有 Node.js 即可直接运行：

```sh
node dist/component-ledger.cjs < examples/replay.json
```

源码重新编译和验收：

环境：MoonBit CLI（本次测试版本 `0.1.20260920`）、Node.js、Python 3（仅验收脚本需要）。官方安装说明：https://www.moonbitlang.com/download/

```sh
bash scripts/verify.sh
node _build/js/debug/build/cmd/main/main.js < examples/replay.json
```

核心用 MoonBit 实现；两段 JavaScript FFI 只负责标准输入读取和退出码，不包含统计逻辑。仅依赖 MoonBit 标准库，未使用第三方业务代码。CLI 当前针对 JavaScript 后端验证。

## 输入协议 v1

`examples/replay.json` 是完整示例：先将 Button 使用数从 2 更新为 3，再更新为 5，最后重放第一条事件。结果仍为 5，最后一条回执是 `duplicate`。

- `initial`：`repo`、`revision`、`usages`。
- `changes[]`：`id`、`repo`、`base`、`head`、`usages`。
- `usages[]`：`file`、`component`、正整数 `count`。每个 file/component 组合只能出现一行。
- 每次 `usages` 都是该版本的**完整快照**，不是仅变更文件。空数组表示仓库已无组件引用。
- `component` 是采集器已解析的规范身份，例如包路径加导出名；`file` 由采集器提供规范仓库相对路径。字符串精确匹配，大小写有意义；库不自动消解别名或路径。
- count 表示采集器定义的静态引用点数量，files 表示至少有一个引用点的文件数；不是运行时渲染次数、用户数或人日收益。
- schema_version 必须为 1。所有数字必须为可表示的 32 位整数；单行计数上限一亿，组件合计上限十亿，以免溢出。未知字段不参与统计。

## 状态和幂等边界

1. 新事件的 base 必须等于当前 revision，repo 必须一致；否则整次请求失败。
2. 相同 id、相同内容为重复事件；行顺序变化不算内容变化。重复事件不产生增量。
3. 相同 id、不同内容拒绝；因此建议 id 使用 MR ID 与 head SHA 的组合，不能只使用 MR 编号。
4. head 不能复用已见 revision。真实回滚应使用新的提交 SHA，快照内容可以回到旧内容。
5. 任一事件失败时只返回错误，退出码 2，不输出可提交的部分统计。成功退出码 0。
6. 输出按 UTF-16 字典序排序；文件移动而引用总量不变时，组件总量增量为零。引用文件数变化会单独反映。

这是无外部副作用的**整段历史重放**内核。去重记录只存在于当前请求内；跨进程重试需要调用方保留同一 initial 与完整事件历史。不能把最终 totals 当成带有历史去重能力的新 initial。生产集成还需要调用方实现事件持久化、并发串行化或 CAS 提交及可信 SHA 校验。

## 可复现验收

34 个 MoonBit 黑盒用例覆盖添加、删除、移动、文件数变化、乱序基线、冲突重试、跨仓库输入、版本复用、空身份、重复行、负数/零/小数、计数溢出、Unicode 与组合键碰撞。CLI 再执行同一组输入，核对实际进程退出码；40 组固定随机种子历史使用独立计数器核对最终总量及增量守恒，并测试非法 JSON。

测试用例使用完全合成的 `demo/shop` 数据，没有公司代码、真实资产清单、银行卡或客户资料。

## 范围和后续

本版不解析 TSX，不声称识别全部 React 组件；需要现有 AST/符号解析采集器提供快照。不连接 GitHub/GitLab，不部署数据库，不自动发评论，不处理真正并发写入。

提交申请后，再按评审意见决定是否增加快照采集适配器、持久化接口和 Mooncakes 发布；避免未立项前扩大范围。源码模块名为 `febear/component-ledger`；尚未发布到 Mooncakes。

## 来源与 AI 使用

实现为本次任务中新编写的 MoonBit 源码，AI 辅助设计、编码与测试，参赛者仍须审核并能解释实现。MoonBit 语言/标准库文档用于学习 API；没有拷贝查重项目代码。

查重参考：`moonbit-community/diff` 是通用 diff 库，`CJR-ai-nb/evowitness` 是契约兼容性反例工具；本项目关注完整快照统计与版本事件重放。公开搜索不能证明生态中没有同类工具，更不等于主办方认可创新性。

MIT 许可证见 LICENSE。参赛规则：https://moonbitlang.github.io/Hackathon2026/

预编译 dist 包含 MoonBit 标准库生成代码，其许可证另见 dist/LICENSE-moonbit-core.txt。修改源码后必须重新 build 并更新 dist，不能将旧预编译文件当成新结果。

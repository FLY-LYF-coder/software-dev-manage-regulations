# 安装到其他设备

> 面向对象：想把本仓库的 7 个 skill 安装到另一台设备上的 MiniMax Code agent 使用的人。
> 适用：Windows / macOS / Linux。

---

## 0. 先看三条运行时规则

1. **运行时只认三个技能位置**（本仓库的 `skills/` 目录本身**不是**注册位置）：
   | 类型 | 位置 | 可见性 |
   |---|---|---|
   | 内置 | `{{DATA_DIR}}/.builtin-skills/<name>/SKILL.md` | 所有 agent，受保护不可改 |
   | 全局（用户） | `{{DATA_DIR}}/skills/<name>/SKILL.md` | 所有 agent |
   | agent 私有 | `{{DATA_DIR}}/agents/<agent>/skills/<name>/SKILL.md` | 仅该 agent |

   `{{DATA_DIR}}` 默认：`~/.minimax`（macOS/Linux）、`%USERPROFILE%\.minimax`（Windows）；可用环境变量 `MINIMAX_DATA_DIR` 覆盖。

2. **技能在下个会话生效**，运行时不需要重启。

3. **不能直接 `git clone` 成单个技能**：运行时的"从 Git URL 安装"要求仓库根目录含 `SKILL.md`，而本仓库是多 skill 仓库（根目录没有 `SKILL.md`，7 个 skill 在 `skills/<name>/` 下）。因此用本仓库自带的安装脚本分发。

---

## 1. 把仓库带到目标设备

**方式 A：有 git（推荐，可升级）**

```bash
git clone <本仓库的 git 地址> ~/software-dev-manage-regulations
cd ~/software-dev-manage-regulations
```

**方式 B：无 git**

把整个仓库目录压缩后拷贝到目标设备，解压后进入该目录即可（升级时用新版本覆盖）。

---

## 2. 运行安装脚本

### macOS / Linux

```bash
cd ~/software-dev-manage-regulations
chmod +x install.sh
./install.sh                        # 全局安装（所有 agent 可见）
./install.sh agent my-agent         # 仅安装到指定 agent 私有目录
```

### Windows（PowerShell）

```powershell
cd <仓库目录>
.\install.ps1                                        # 全局安装
.\install.ps1 -Scope agent -AgentName my-agent       # 仅指定 agent
```

### 脚本做了什么

| 动作 | 结果 |
|---|---|
| 复制 7 个 skill 目录 | `{{DATA_DIR}}/skills/<name>/` 或 `{{DATA_DIR}}/agents/<agent>/skills/<name>/` |
| 复制规范与模板 | `{{DATA_DIR}}/docs/team-management/`（含 11 份模板） |
| 同名 skill | **整体替换**，不留残留旧文件 |
| 输出 | 安装清单 + 后续步骤提示 |

自定义运行时目录：`MINIMAX_DATA_DIR=/your/dir ./install.sh` 或 `.\install.ps1 -DataDir C:\your\dir`。

---

## 3. 设置 agent 默认工作目录（推荐）

工作目录指向本仓库时，产物落盘（`artifacts/`）、上下文包链接、路径解析都最顺。让目标设备上的 agent 执行：

```text
mavis({ command: "agent update", args: { agent_name: "mavis", default_workspace_dir: "<仓库绝对路径>" } })
```

或在 MiniMax Code 的 agent 配置界面直接设置"默认工作目录"。

---

## 4. 规范与模板如何被找到（D0 定位顺序）

7 个 skill 里的 `source_docs` 与 `templates` 都是仓库相对路径 `docs/team-management/...`。每个 skill 的 §3 前置检查第一条 **D0 规范与模板定位**规定了三级解析顺序：

1. 环境变量 `TEAM_MGMT_ROOT`
2. **以本 SKILL.md 所在目录为基准逐级向上查找 `docs/team-management/`**
3. 当前工作目录下的 `docs/team-management/`

安装脚本已把规范与模板放到 `{{DATA_DIR}}/docs/team-management/`，因此**规则 ② 在默认安装下必然命中**（全局安装与 agent 私有安装都已实测验证）。

若目标设备上 agent 的工作目录不在仓库内，额外设置环境变量即可：

```bash
export TEAM_MGMT_ROOT=~/software-dev-manage-regulations   # macOS/Linux
$env:TEAM_MGMT_ROOT="C:\path\to\software-dev-manage-regulations"   # PowerShell
```

---

## 5. 验证

**下一个会话**中：

1. 按名加载一个 skill，确认返回正文与 `Location:` 头：

   ```text
   skill({ name: "task-card" })
   ```

2. 确认 7 个 skill 出现在该 agent 的可用技能列表中。
3. 走一次真实流程，确认模板与规范可被读取，例如：提出一个需求 → 应触发 `user-request-intake` → 产出 `artifacts/requirement-package/REQ-….md`。

---

## 6. 升级

```bash
cd ~/software-dev-manage-regulations
git pull            # 或用新版目录覆盖
./install.sh        # 重新安装，整体替换
```

**升级纪律**：规范升版时必须按规范 §11 同步检查相关 skills 并登记 `CHANGELOG.md`。本仓库 `CHANGELOG.md` 第 3 节已列出升版时须反向核对的 4 项（源文档锚点、模板字段一致性、skills 引用有效性等）。

---

## 7. 故障排查

| 现象 | 原因 | 处理 |
|---|---|---|
| 可用技能列表里没有这些 skill | 还没到下个会话，或装到了错误目录 | 重开会话；核对 `{{DATA_DIR}}/skills/<name>/SKILL.md` 是否存在 |
| skill 能加载，但报"模板缺失/规范缺失" | D0 三条规则都没命中 | 设 `TEAM_MGMT_ROOT`；或确认 `{{DATA_DIR}}/docs/team-management/` 存在 |
| 读到的规范是旧版 | 仓库更新了但没重跑安装脚本 | 重跑安装脚本 |
| `install.ps1` 中文乱码或语法报错 | 手工编辑后存成了无 BOM 的 UTF-8 | PowerShell 5.1 要求 **UTF-8 with BOM**，重新另存为该编码 |
| Windows 提示脚本被禁止运行 | 执行策略限制 | `powershell -ExecutionPolicy Bypass -File .\install.ps1` |
| `install.sh` 提示 `Permission denied` | 没有执行权限 | `chmod +x install.sh` |

---

## 8. 跨设备一致性约定

1. **单一事实源**：仓库中的 `docs/team-management/TEAM_MANAGEMENT.md` 是唯一权威规范；安装脚本只是把它**复制**成运行时副本 `{{DATA_DIR}}/docs/team-management/`，运行时副本通过重跑脚本刷新。
2. **skill 不复制规范全文**：每个 skill 只引用章节号与模板路径，因此规范改一处、7 个 skill 同时生效，不存在副本漂移。
3. **模板同理**：11 份模板的权威副本在仓库 `docs/team-management/templates/`，运行时副本在 `{{DATA_DIR}}/docs/team-management/templates/`。
4. **变更必须留痕**：任何规范、模板、skills 的改动都要在 `CHANGELOG.md` 登记变更原因、影响范围、批准人（规范 §11）。

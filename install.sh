#!/usr/bin/env bash
# =============================================================================
# 安装 software-dev-manage-regulations 的 7 个 skill 到本机 MiniMax Code 运行时
#
#   用法:
#     ./install.sh                 # 全局安装（所有 agent 可见）
#     ./install.sh global
#     ./install.sh agent my-agent  # 仅安装到指定 agent 私有目录
#
#   环境变量:
#     MINIMAX_DATA_DIR   运行时数据目录，默认 ~/.minimax
#
#   说明:
#     - 安装 = 复制 skill 目录 + 复制规范与模板（供 skill 的 D0 定位步骤解析）
#     - 同名 skill 会被整体替换（避免残留旧文件）
#     - 安装后【下一个会话】生效，运行时无需重启
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${MINIMAX_DATA_DIR:-$HOME/.minimax}"
SCOPE="${1:-global}"
AGENT_NAME="${2:-mavis}"

case "$SCOPE" in
  global) SKILLS_DIR="$DATA_DIR/skills" ;;
  agent)
    [ -n "$AGENT_NAME" ] || { echo "错误: agent 作用域需要指定 agent 名" >&2; exit 2; }
    SKILLS_DIR="$DATA_DIR/agents/$AGENT_NAME/skills"
    ;;
  -h|--help|help) sed -n '2,20p' "$0"; exit 0 ;;
  *) echo "错误: 作用域只能是 global 或 agent" >&2; exit 2 ;;
esac

echo "仓库根目录 : $REPO_ROOT"
echo "运行时目录 : $DATA_DIR"
echo "安装作用域 : $SCOPE"
echo "技能目录   : $SKILLS_DIR"
echo "-----------------------------------------------------------"

if [ ! -d "$REPO_ROOT/skills" ]; then
  echo "错误: 未找到 $REPO_ROOT/skills，请在仓库根目录运行本脚本" >&2
  exit 1
fi

mkdir -p "$SKILLS_DIR"

count=0
for src in "$REPO_ROOT"/skills/*/; do
  [ -d "$src" ] || continue
  name="$(basename "$src")"
  [ -f "$src/SKILL.md" ] || { echo "跳过 $name（无 SKILL.md）"; continue; }
  dst="$SKILLS_DIR/$name"
  rm -rf "$dst"
  cp -R "$src" "$dst"
  echo "已安装 : $name -> $dst"
  count=$((count + 1))
done

# 规范与模板：供 skill 的 D0 定位步骤（从 SKILL.md 所在目录逐级向上查找 docs/team-management/）解析
DOCS_DST="$DATA_DIR/docs/team-management"
mkdir -p "$DATA_DIR/docs"
rm -rf "$DOCS_DST"
cp -R "$REPO_ROOT/docs/team-management" "$DOCS_DST"
echo "已安装 : 规范与模板 -> $DOCS_DST"

echo "-----------------------------------------------------------"
echo "完成：共安装 $count 个 skill。"
echo ""
echo "后续步骤："
echo "  1) 【下个会话生效】运行时无需重启；新会话中用 skill 工具按名加载验证，例如 task-card。"
echo "  2) 建议设置 agent 默认工作目录为本仓库，产物落盘与上下文包最顺："
echo "     - 让 agent 执行：mavis({ command: \"agent update\", args: { agent_name: \"$AGENT_NAME\", default_workspace_dir: \"$REPO_ROOT\" } })"
echo "     - 或在 MiniMax Code 的 agent 配置界面直接设置默认工作目录。"
echo "  3) 若 agent 的工作目录不在本仓库，请设置环境变量 TEAM_MGMT_ROOT=$REPO_ROOT"
echo "     （skill 的 D0 定位顺序：TEAM_MGMT_ROOT → SKILL.md 向上查找 → 工作目录）。"
echo "  4) 升级：重新拉取仓库后再次运行本脚本即可整体替换。"

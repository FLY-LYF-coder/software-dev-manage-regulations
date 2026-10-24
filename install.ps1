<#
.SYNOPSIS
    安装 software-dev-manage-regulations 的 7 个 skill 到本机 MiniMax Code 运行时（Windows）。

.EXAMPLE
    .\install.ps1                                  # 全局安装（所有 agent 可见）
    .\install.ps1 -Scope agent -AgentName my-agent  # 仅安装到指定 agent 私有目录

.NOTES
    - 安装 = 复制 skill 目录 + 复制规范与模板（供 skill 的 D0 定位步骤解析）
    - 同名 skill 会被整体替换（避免残留旧文件）
    - 安装后【下一个会话】生效，运行时无需重启
#>
[CmdletBinding()]
param(
    [ValidateSet('global', 'agent')]
    [string]$Scope = 'global',

    [string]$AgentName = 'mavis',

    [string]$DataDir = ''
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

if ([string]::IsNullOrWhiteSpace($DataDir)) {
    if (-not [string]::IsNullOrWhiteSpace($env:MINIMAX_DATA_DIR)) {
        $DataDir = $env:MINIMAX_DATA_DIR
    } else {
        $DataDir = Join-Path $env:USERPROFILE '.minimax'
    }
}

switch ($Scope) {
    'global' { $SkillsDir = Join-Path $DataDir 'skills' }
    'agent'  { $SkillsDir = Join-Path (Join-Path (Join-Path $DataDir 'agents') $AgentName) 'skills' }
}

Write-Output "仓库根目录 : $RepoRoot"
Write-Output "运行时目录 : $DataDir"
Write-Output "安装作用域 : $Scope"
Write-Output "技能目录   : $SkillsDir"
Write-Output ('-' * 58)

$RepoSkills = Join-Path $RepoRoot 'skills'
if (-not (Test-Path $RepoSkills)) {
    Write-Error "未找到 $RepoSkills，请在仓库根目录运行本脚本"
}

New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null

$count = 0
foreach ($src in Get-ChildItem -Path $RepoSkills -Directory) {
    if (-not (Test-Path (Join-Path $src.FullName 'SKILL.md'))) {
        Write-Output "跳过 $($src.Name)（无 SKILL.md）"
        continue
    }
    $dst = Join-Path $SkillsDir $src.Name
    if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
    Copy-Item -Recurse -LiteralPath $src.FullName -Destination $dst
    Write-Output "已安装 : $($src.Name) -> $dst"
    $count++
}

# 规范与模板：供 skill 的 D0 定位步骤（从 SKILL.md 所在目录逐级向上查找 docs/team-management/）解析
$DocsParent = Join-Path $DataDir 'docs'
$DocsDst    = Join-Path $DocsParent 'team-management'
New-Item -ItemType Directory -Force -Path $DocsParent | Out-Null
if (Test-Path $DocsDst) { Remove-Item -Recurse -Force $DocsDst }
Copy-Item -Recurse -LiteralPath (Join-Path $RepoRoot 'docs\team-management') -Destination $DocsDst
Write-Output "已安装 : 规范与模板 -> $DocsDst"

Write-Output ('-' * 58)
Write-Output "完成：共安装 $count 个 skill。"
Write-Output ''
Write-Output '后续步骤：'
Write-Output '  1) 【下个会话生效】运行时无需重启；新会话中用 skill 工具按名加载验证，例如 task-card。'
Write-Output '  2) 建议设置 agent 默认工作目录为本仓库，产物落盘与上下文包最顺：'
Write-Output "     - 让 agent 执行：mavis({ command: `"agent update`", args: { agent_name: `"$AgentName`", default_workspace_dir: `"$RepoRoot`" } })"
Write-Output '     - 或在 MiniMax Code 的 agent 配置界面直接设置默认工作目录。'
Write-Output "  3) 若 agent 的工作目录不在本仓库，请设置环境变量 TEAM_MGMT_ROOT=$RepoRoot"
Write-Output '     （skill 的 D0 定位顺序：TEAM_MGMT_ROOT → SKILL.md 向上查找 → 工作目录）。'
Write-Output '  4) 升级：重新拉取仓库后再次运行本脚本即可整体替换。'

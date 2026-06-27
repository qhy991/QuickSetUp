# Quick

Linux 用户级 AI 开发工具一键安装脚本（无需 sudo）。

适用于外网受限环境：优先使用国内镜像（npmmirror），GitHub 推荐 SSH。

## 包含工具

| 工具 | 说明 |
|------|------|
| **Node.js** | 用户级安装到 `~/.local/node` |
| **Claude Code** | `@anthropic-ai/claude-code` |
| **Codex CLI** | `@openai/codex` |
| **codex-transfer** | Codex Responses API → Infini-AI 协议转换代理 |

## 快速开始

```bash
git clone git@github.com:qhy991/Quick.git
cd Quick
bash install-ai-tools.sh
source ~/.profile

claude --version
codex --version
```

## Infini-AI 一键配置（推荐）

Claude Code 直连 Infini-AI MaaS；Codex 经本地 `codex-transfer` 代理调用 Infini-AI GenStudio。

```bash
bash apply-config.sh infini-ai

# 填入 Infini-AI API Key
vim ~/.claude/settings.json
vim ~/.codex-transfer/config.json

# 安装并启动 codex-transfer
bash scripts/install-codex-transfer.sh
bash scripts/start-codex-transfer.sh

source ~/.profile
claude    # /status 验证
codex doctor
```

详细说明见 [CONFIG-GUIDE.zh-CN.md](./CONFIG-GUIDE.zh-CN.md)。

## 脚本说明

| 脚本 | 作用 |
|------|------|
| `install-ai-tools.sh` | 一键安装 Node.js + Claude Code + Codex + PATH |
| `install-node.sh` | 仅安装 Node.js |
| `install-claude-codex.sh` | 仅安装 Claude Code 和 Codex |
| `setup-shell-path.sh` | 写入 `~/.profile` PATH 配置 |
| `apply-config.sh` | 应用 Claude/Codex/codex-transfer 配置模板 |
| `scripts/install-codex-transfer.sh` | 安装 codex-transfer 本地代理 |
| `scripts/start-codex-transfer.sh` | 启动 codex-transfer（:4446） |
| `scripts/stop-codex-transfer.sh` | 停止 codex-transfer |
| `DOWNLOAD-METHODS.md` | 外网受限时的下载与离线安装方法 |
| `CONFIG-GUIDE.zh-CN.md` | Base URL、API Key、模型映射配置说明 |
| `config-templates/` | 可填写的 `.claude` / `.codex` / `.codex-transfer` 配置模板 |

## 其他配置场景

```bash
bash apply-config.sh claude-gateway   # Claude 第三方网关
bash apply-config.sh codex-proxy      # Codex 自定义 Base URL
bash apply-config.sh codex-official   # Codex OpenAI 官方
```

## 首次登录

```bash
claude    # 或在 settings.json 配置 ANTHROPIC_API_KEY / AUTH_TOKEN
codex     # infini-ai 场景需先启动 codex-transfer
```

## 环境变量（可选）

```bash
NODE_VERSION=22.16.0          # Node.js 版本
NODE_MIRROR=https://npmmirror.com/mirrors/node
NPM_REGISTRY=https://registry.npmmirror.com
CLAUDE_VERSION=latest
CODEX_VERSION=latest
CODEX_TRANSFER_API_KEY=sk-... # codex-transfer 启动用（也可写在 config.json）
```

## 离线安装

详见 [DOWNLOAD-METHODS.md](./DOWNLOAD-METHODS.md)。

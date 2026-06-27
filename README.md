# QuickSetUp

Linux 用户级 AI 开发工具一键安装与配置（无需 sudo）。

适用于外网受限环境：优先使用国内镜像（npmmirror），GitHub 推荐 SSH。

仓库地址：[github.com/qhy991/QuickSetUp](https://github.com/qhy991/QuickSetUp)

## 包含工具

| 工具 | 说明 |
|------|------|
| **Node.js** | 用户级安装到 `~/.local/node` |
| **Claude Code** | `@anthropic-ai/claude-code` |
| **Codex CLI** | `@openai/codex` |
| **codex-transfer** | 本地代理：Codex Responses API → Infini-AI Chat Completions |

## 完整流程（从零到可用）

### 1. 安装

```bash
git clone git@github.com:qhy991/QuickSetUp.git
cd QuickSetUp
bash install-ai-tools.sh
source ~/.profile

claude --version
codex --version
```

### 2. 应用 Infini-AI 配置

```bash
bash apply-config.sh infini-ai
```

会写入以下文件：

| 文件 | 作用 |
|------|------|
| `~/.claude/settings.json` | Claude Code 直连 Infini-AI |
| `~/.codex/config.toml` | Codex 指向本地 codex-transfer |
| `~/.codex-transfer/config.json` | codex-transfer 上游与模型映射 |

### 3. 填入 API Key

在 [无问芯穹控制台](https://cloud.infini-ai.com) 获取 GenStudio API Key，填入：

```bash
vim ~/.claude/settings.json          # ANTHROPIC_API_KEY / ANTHROPIC_AUTH_TOKEN
vim ~/.codex-transfer/config.json    # apiKey
```

两处填**同一个 Key** 即可。

> **注意：** 若存在 `~/.codex-transfer/env`，不要保留 `CODEX_TRANSFER_API_KEY=YOUR_INFINI_AI_API_KEY` 占位符，否则会覆盖 `config.json` 中的真实 Key。推荐只在 `config.json` 里填写 Key，或删除 env 中的占位行。

### 4. 安装并启动 codex-transfer

Codex CLI 使用 OpenAI **Responses API**，Infini-AI 提供 **Chat Completions API**，二者不兼容，必须通过本地代理转换。

```bash
bash scripts/install-codex-transfer.sh
bash scripts/start-codex-transfer.sh
```

> **重要：** `codex-transfer` **不会**随系统开机自动启动。机器重启后需重新执行 `bash scripts/start-codex-transfer.sh`，否则 Codex 会报 `error sending request for url (http://127.0.0.1:4446/v1/responses)`。

确认代理正常：

```bash
curl -s http://127.0.0.1:4446/health
# 期望：upstream 为 https://cloud.infini-ai.com/maas/v1，upstreamOk 为 true
```

### 5. 验证

```bash
source ~/.profile

claude -p "hello" --output-format text    # Claude 直连测试
codex doctor                              # Codex 环境检查
codex exec "hello" < /dev/null            # Codex 经代理测试
```

Claude 交互模式下可执行 `/status`，确认 Base URL 为 `https://cloud.infini-ai.com/maas`。

## 架构说明

```
Claude Code                          Codex CLI
~/.claude/settings.json              ~/.codex/config.toml
        │                                    │
        │ 直连 Anthropic Messages            │ 本地 Responses API
        ▼                                    ▼
https://cloud.infini-ai.com/maas     http://127.0.0.1:4446/v1
                                            │
                                            │ codex-transfer（协议转换）
                                            ▼
                               https://cloud.infini-ai.com/maas/v1
```

- **Claude Code**：直连 `https://cloud.infini-ai.com/maas`（Anthropic Messages 协议，**不带** `/v1`）
- **Codex CLI**：只连本地 `http://127.0.0.1:4446/v1`，由 codex-transfer 转发到 `https://cloud.infini-ai.com/maas/v1`
- **Codex 不要直连 Infini-AI**，`/v1/responses` 接口不存在，会报 404

## 关键配置参考

### Claude（`~/.claude/settings.json`）

```json
{
  "model": "claude-opus-4-6",
  "env": {
    "ANTHROPIC_BASE_URL": "https://cloud.infini-ai.com/maas",
    "ANTHROPIC_API_KEY": "YOUR_INFINI_AI_API_KEY",
    "ANTHROPIC_AUTH_TOKEN": "YOUR_INFINI_AI_API_KEY",
    "ANTHROPIC_MODEL": "claude-opus-4-6",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-6",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-6",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-4-5",
    "ANTHROPIC_SMALL_FAST_MODEL": "claude-haiku-4-5"
  }
}
```

### codex-transfer（`~/.codex-transfer/config.json`）

```json
{
  "port": 4446,
  "upstream": "https://cloud.infini-ai.com/maas/v1",
  "apiKey": "YOUR_INFINI_AI_API_KEY",
  "modelMap": {
    "gpt-5.5": "glm-5.2",
    "*": "glm-5.2"
  }
}
```

`modelMap` 将 Codex 请求的模型名映射到 Infini-AI 实际可用模型；`"*"` 为兜底。

### Codex（`~/.codex/config.toml`）

由 `apply-config.sh infini-ai` 自动写入，核心项：

```toml
model_provider = "infini_transfer"
model = "gpt-5.5"
base_url = "http://127.0.0.1:4446/v1"   # 在 [model_providers.infini_transfer] 下
sandbox_mode = "danger-full-access"       # 部分 Linux 主机 bwrap 沙箱会失败
```

## 脚本说明

| 脚本 | 作用 |
|------|------|
| `install-ai-tools.sh` | 一键安装 Node.js + Claude Code + Codex + PATH |
| `apply-config.sh infini-ai` | 应用 Infini-AI 配置模板（推荐） |
| `scripts/install-codex-transfer.sh` | 安装 codex-transfer 到 `~/.local/codex-transfer` |
| `scripts/start-codex-transfer.sh` | 启动 codex-transfer（默认 `:4446`） |
| `scripts/stop-codex-transfer.sh` | 停止 codex-transfer |
| `install-node.sh` | 仅安装 Node.js |
| `install-claude-codex.sh` | 仅安装 Claude Code 和 Codex |
| `setup-shell-path.sh` | 写入 `~/.profile` PATH 配置 |

更多配置场景与故障排查见 [CONFIG-GUIDE.zh-CN.md](./CONFIG-GUIDE.zh-CN.md)。

## 其他配置场景

```bash
bash apply-config.sh claude-gateway   # Claude 第三方网关
bash apply-config.sh codex-proxy      # Codex 自定义 Base URL
bash apply-config.sh codex-official   # Codex OpenAI 官方
```

## 常见问题

### codex-transfer 未启动（含机器重启后）

`codex-transfer` 是后台进程，**重启机器后不会自动恢复**。若 Codex 报错：

```
stream disconnected before completion: error sending request for url (http://127.0.0.1:4446/v1/responses)
```

执行：

```bash
bash scripts/start-codex-transfer.sh
curl -s http://127.0.0.1:4446/health
```

### Codex 报 404 / 405

- 确认 `~/.codex/config.toml` 中 `base_url` 为 `http://127.0.0.1:4446/v1`，不是 Infini-AI 地址
- 确认 `~/.codex-transfer/config.json` 中 `upstream` 为 `https://cloud.infini-ai.com/maas/v1`

### API Key 不生效

检查 `~/.codex-transfer/env` 是否残留占位符 `YOUR_INFINI_AI_API_KEY`，它会覆盖 `config.json`。

### Codex STALL（bwrap 沙箱失败）

在 `~/.codex/config.toml` 设置 `sandbox_mode = "danger-full-access"`（infini-ai 模板已包含）。

## 环境变量（可选）

```bash
NODE_VERSION=22.16.0
NODE_MIRROR=https://npmmirror.com/mirrors/node
NPM_REGISTRY=https://registry.npmmirror.com
CODEX_TRANSFER_UPSTREAM=https://cloud.infini-ai.com/maas/v1   # 覆盖 upstream
```

## 离线安装

详见 [DOWNLOAD-METHODS.md](./DOWNLOAD-METHODS.md)。

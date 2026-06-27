# Claude Code & Codex 配置指南

填写模板 → 复制到 `~/.claude` / `~/.codex` / `~/.codex-transfer` → 启动代理 → 即可使用。

## 配置文件位置

| 工具 | 配置文件 | 说明 |
|------|----------|------|
| **Claude Code** | `~/.claude/settings.json` | 全局设置，含 `env` 块 |
| **Codex CLI** | `~/.codex/config.toml` | 模型、Provider、沙箱 |
| **codex-transfer** | `~/.codex-transfer/config.json` | 本地代理：Responses API → Infini-AI |
| **Codex API Key** | `~/.codex/auth.env` | 直连 OpenAI/代理场景用（infini-ai 场景不需要） |

项目级配置（可选）：
- Claude: 项目内 `.claude/settings.json` 或 `.claude/settings.local.json`
- Codex: 项目内 `.codex/config.toml`（需信任项目）

---

## 快速开始（Infini-AI，推荐）

```bash
cd Quick

bash apply-config.sh infini-ai

# 编辑占位符
vim ~/.claude/settings.json
vim ~/.codex-transfer/config.json

# 安装并启动 codex-transfer
bash scripts/install-codex-transfer.sh
bash scripts/start-codex-transfer.sh

source ~/.profile
claude    # 内执行 /status 验证
codex doctor
```

---

## Infini-AI GenStudio 架构

```
Claude Code                          Codex CLI
~/.claude/settings.json              ~/.codex/config.toml
        │                                    │
        │ 直连                               │ 本地代理
        ▼                                    ▼
https://cloud.infini-ai.com/maas     http://127.0.0.1:4446/v1
                                            │
                                            │ codex-transfer
                                            ▼
                               https://cloud.infini-ai.com/mass/coding
```

**为什么 Codex 需要 codex-transfer？**

Codex CLI 使用 OpenAI **Responses API**，Infini-AI 提供 **Chat Completions API**。`codex-transfer` 在本地做协议转换，Codex 只需指向 `http://127.0.0.1:4446/v1`。

---

## Claude Code（Infini-AI）

模板：`config-templates/claude/settings.infini-ai.template.json`

```json
{
  "model": "claude-opus-4-7",
  "env": {
    "ANTHROPIC_BASE_URL": "https://cloud.infini-ai.com/maas",
    "ANTHROPIC_MODEL": "claude-opus-4-7",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5.2",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-v4-flash",
    "ANTHROPIC_API_KEY": "YOUR_INFINI_AI_API_KEY",
    "ANTHROPIC_AUTH_TOKEN": "YOUR_INFINI_AI_API_KEY"
  }
}
```

| 字段 | 说明 |
|------|------|
| `ANTHROPIC_BASE_URL` | Infini-AI MaaS 地址（**不带** `/v1` 后缀） |
| `ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN` | Infini-AI 平台 API Key |
| `ANTHROPIC_MODEL` | 默认主模型 |
| `ANTHROPIC_DEFAULT_*_MODEL` | Opus / Sonnet / Haiku 档位默认模型 |

### 切换 Claude 主模型

```bash
claude
/model glm-5.2          # 或 claude-opus-4-7 / deepseek-v4-pro 等
```

### 验证

```bash
claude
/status    # 查看当前 Base URL 和认证来源
```

---

## Codex（Infini-AI，经 codex-transfer）

### 1. 安装 codex-transfer

```bash
bash scripts/install-codex-transfer.sh
```

### 2. 配置 `~/.codex-transfer/config.json`

模板：`config-templates/codex-transfer/config.template.json`

```json
{
  "port": 4446,
  "upstream": "https://cloud.infini-ai.com/mass/coding",
  "apiKey": "YOUR_INFINI_AI_API_KEY",
  "insecure": false,
  "reasoningEffort": true,
  "modelMap": {
    "claude-opus-4-7": "claude-opus-4-7",
    "glm-5.2": "glm-5.2",
    "gpt-5.5": "gpt-5.5",
    "gpt-5.2": "glm-5.2",
    "deepseek-v4-flash": "deepseek-v4-flash",
    "deepseek-v4-pro": "deepseek-v4-pro",
    "*": "glm-5.2"
  }
}
```

| 字段 | 说明 |
|------|------|
| `upstream` | Infini-AI GenStudio Coding API 地址 |
| `apiKey` | Infini-AI API Key |
| `modelMap` | Codex 请求的模型名 → Infini-AI 实际模型 |
| `"*"` | 兜底映射 |

### 3. 启动 / 停止

```bash
bash scripts/start-codex-transfer.sh
curl -s http://127.0.0.1:4446/health

bash scripts/stop-codex-transfer.sh
```

API Key 也可通过环境变量传入（可选）：

```bash
export CODEX_TRANSFER_API_KEY=YOUR_INFINI_AI_API_KEY
bash scripts/start-codex-transfer.sh
```

### 4. 配置 `~/.codex/config.toml`

模板：`config-templates/codex/config.infini-transfer.template.toml`

```toml
model_provider = "infini_transfer"
model = "gpt-5.5"
review_model = "gpt-5.5"
model_reasoning_effort = "high"
disable_response_storage = true
network_access = "enabled"
sandbox_mode = "danger-full-access"

[model_providers.infini_transfer]
name = "Infini-AI GenStudio via codex-transfer"
base_url = "http://127.0.0.1:4446/v1"
wire_api = "responses"
requires_openai_auth = false
```

| 字段 | 说明 |
|------|------|
| `base_url` | **必须** 指向本地 codex-transfer，不要写 Infini-AI 直连 |
| `sandbox_mode` | 部分 Linux 主机 bwrap 沙箱会失败，需设为 `danger-full-access` |
| `[projects.*]` | 工作区路径加 `trust_level = "trusted"`（按需手动添加） |

### 验证

```bash
bash scripts/start-codex-transfer.sh
codex doctor
codex -p "hello"
```

---

## 其他 Claude 场景

### 场景 A：第三方网关（自定义 Base URL）

模板：`config-templates/claude/settings.gateway.template.json`

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://your-gateway.example.com",
    "ANTHROPIC_AUTH_TOKEN": "your-gateway-token",
    "ANTHROPIC_MODEL": "claude-sonnet-4-6"
  }
}
```

### 场景 B：Anthropic 官方 API

模板：`config-templates/claude/settings.official-api.template.json`

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "sk-ant-..."
  }
}
```

---

## 其他 Codex 场景

### OpenAI 官方 + 自定义 Base URL

模板：`config-templates/codex/config.openai-proxy.template.toml`

```toml
openai_base_url = "https://your-proxy.example.com/v1"
model = "gpt-5.3-codex"
model_provider = "openai"
```

API Key 写在 `~/.codex/auth.env`：

```bash
OPENAI_API_KEY=sk-...
```

### OpenAI 官方 API

模板：`config-templates/codex/config.official-api.template.toml`

### 完全自定义 Provider

模板：`config-templates/codex/config.custom-provider.template.toml`

---

## 常见故障

### codex-transfer not reachable on :4446

```bash
bash scripts/start-codex-transfer.sh
curl -s http://127.0.0.1:4446/health
```

确认 `~/.codex-transfer/config.json` 中 `apiKey` 已填写，或已 `export CODEX_TRANSFER_API_KEY`。

### Codex STALL（bwrap 沙箱）

```
bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted
```

在 `~/.codex/config.toml` 设置：

```toml
sandbox_mode = "danger-full-access"
```

### Claude 仍走 Anthropic 官方

检查 `~/.claude/settings.json`：

```json
"ANTHROPIC_BASE_URL": "https://cloud.infini-ai.com/maas"
```

修改后**重启 Claude Code**。

### Review 用了错误模型

检查链路：

1. `~/.codex/config.toml` → `model` / `review_model`
2. `~/.codex-transfer/config.json` → `modelMap`

---

## 安全提醒

- `~/.codex-transfer/config.json`、`~/.claude/settings.json` 含密钥，**勿提交 Git**
- 项目级 `.claude/settings.local.json` 应加入 `.gitignore`
- 安装完成后可删除本地含真实 Key 的备份文件（`*.bak.*`）

---

## 模板文件一览

```
config-templates/
├── claude/
│   ├── settings.infini-ai.template.json      # Infini-AI MaaS（推荐）
│   ├── settings.gateway.template.json        # 第三方网关
│   └── settings.official-api.template.json   # Anthropic 官方
├── codex/
│   ├── config.infini-transfer.template.toml  # Infini-AI + codex-transfer（推荐）
│   ├── config.infini-ai.template.toml        # 直连 maas/v1（可能不兼容 Responses API）
│   ├── config.openai-proxy.template.toml     # OpenAI + 自定义 URL
│   ├── config.official-api.template.toml     # OpenAI 官方
│   ├── config.custom-provider.template.toml  # 自定义 Provider
│   └── auth.env.template                     # API Key
└── codex-transfer/
    ├── config.template.json                  # 本地代理配置
    └── env.template                          # 可选环境变量
```

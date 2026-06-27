# Claude Code & Codex 配置指南

填写模板 → 复制到 `~/.claude` / `~/.codex` → 即可使用。

## 配置文件位置

| 工具 | 配置文件 | 说明 |
|------|----------|------|
| **Claude Code** | `~/.claude/settings.json` | 全局设置，含 `env` 块 |
| **Codex CLI** | `~/.codex/config.toml` | 模型、Base URL、Provider |
| **Codex API Key** | `~/.codex/auth.env` | 密钥（由 `apply-config.sh` 自动加载） |

项目级配置（可选）：
- Claude: 项目内 `.claude/settings.json` 或 `.claude/settings.local.json`
- Codex: 项目内 `.codex/config.toml`（需信任项目；**不能**覆盖 `openai_base_url` 等机器级密钥）

---

## 快速开始

```bash
cd Quick   # 或 git clone 后的目录

# 交互选择场景并应用模板
bash apply-config.sh

# 或直接指定场景
bash apply-config.sh claude-gateway   # Claude 第三方网关
bash apply-config.sh codex-proxy      # Codex 自定义 Base URL

# 编辑占位符
vim ~/.claude/settings.json
vim ~/.codex/config.toml
vim ~/.codex/auth.env

source ~/.profile
claude    # 内执行 /status 验证
codex doctor
```

---

## Claude Code 配置

官方文档：[Settings](https://code.claude.com/docs/en/settings) · [LLM Gateway](https://code.claude.com/docs/en/llm-gateway-connect) · [Env Vars](https://code.claude.com/docs/en/env-vars)

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

| 变量 | 用途 |
|------|------|
| `ANTHROPIC_BASE_URL` | 网关地址 |
| `ANTHROPIC_AUTH_TOKEN` | Bearer Token（网关场景） |
| `ANTHROPIC_API_KEY` | 直连 Anthropic 官方时用（见场景 B） |
| `ANTHROPIC_MODEL` | 默认模型 |

### 场景 B：Anthropic 官方 API

模板：`config-templates/claude/settings.official-api.template.json`

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "sk-ant-..."
  }
}
```

### 验证

```bash
claude
/status    # 查看当前 Base URL 和认证来源
```

### 已有插件配置时

若 `~/.claude/settings.json` 里已有插件（如 marketplace），**只合并 `env` 块**，不要覆盖整个文件。`apply-config.sh` 会自动合并。

---

## Codex CLI 配置

官方文档：[Config Advanced](https://developers.openai.com/codex/config-advanced) · [Config Reference](https://developers.openai.com/codex/config-reference) · [Auth](https://developers.openai.com/codex/auth)

### 场景 A：OpenAI 官方 + 自定义 Base URL（代理/网关）

模板：`config-templates/codex/config.openai-proxy.template.toml`

```toml
openai_base_url = "https://your-proxy.example.com/v1"
model = "gpt-5.3-codex"
model_provider = "openai"
cli_auth_credentials_store = "file"
```

> **注意：** 自定义 OpenAI Base URL 用顶层 `openai_base_url`，**不要**创建 `[model_providers.openai]`。

API Key 写在 `~/.codex/auth.env`：

```bash
OPENAI_API_KEY=sk-...
```

### 场景 B：OpenAI 官方 API

模板：`config-templates/codex/config.official-api.template.toml`

```toml
model = "gpt-5.3-codex"
model_provider = "openai"
```

Key 同样放在 `~/.codex/auth.env`。

### 场景 C：完全自定义 Provider

模板：`config-templates/codex/config.custom-provider.template.toml`

```toml
model = "your-model"
model_provider = "my-proxy"

[model_providers.my-proxy]
base_url = "https://gateway.example.com/v1"
env_key = "MY_PROXY_API_KEY"
wire_api = "responses"
```

`~/.codex/auth.env`：

```bash
MY_PROXY_API_KEY=your-key
```

### 登录方式（二选一）

| 方式 | 命令 | 凭证位置 |
|------|------|----------|
| API Key（推荐无头服务器） | 配置 `auth.env` | 环境变量 |
| 交互登录 | `codex login` | `~/.codex/auth.json` |
| ChatGPT 订阅 | `codex login` 选 ChatGPT | `~/.codex/auth.json` |

### 验证

```bash
source ~/.profile
codex doctor
codex -p "hello"
```

---

## 环境变量速查

### Claude Code（也可写在 shell，但 settings.json 更持久）

```bash
export ANTHROPIC_BASE_URL="https://gateway.example.com"
export ANTHROPIC_AUTH_TOKEN="your-token"
# 或
export ANTHROPIC_API_KEY="sk-ant-..."
```

### Codex

```bash
export OPENAI_API_KEY="sk-..."
# openai_base_url 请写在 ~/.codex/config.toml，不要依赖已弃用的 OPENAI_BASE_URL
```

---

## 安全提醒

- `~/.codex/auth.env`、`~/.codex/auth.json`、`~/.claude/settings.json` 含密钥，**勿提交 Git**
- 项目级 `.claude/settings.local.json` 应加入 `.gitignore`
- 安装完成后可删除本地含真实 Key 的备份文件（`*.bak.*`）

---

## 模板文件一览

```
config-templates/
├── claude/
│   ├── settings.gateway.template.json      # 第三方网关
│   └── settings.official-api.template.json # Anthropic 官方
└── codex/
    ├── config.openai-proxy.template.toml   # OpenAI + 自定义 URL
    ├── config.official-api.template.toml   # OpenAI 官方
    ├── config.custom-provider.template.toml# 自定义 Provider
    └── auth.env.template                   # API Key
```

#!/usr/bin/env bash
# 将填写好的配置模板应用到 ~/.claude、~/.codex 和 ~/.codex-transfer
# 用法:
#   bash apply-config.sh                    # 交互选择场景
#   bash apply-config.sh claude-gateway     # Claude 第三方网关
#   bash apply-config.sh claude-official    # Claude 官方 API
#   bash apply-config.sh codex-proxy          # Codex + 自定义 openai_base_url
#   bash apply-config.sh codex-official       # Codex 官方 OpenAI
#   bash apply-config.sh codex-custom         # Codex 自定义 model_provider
#   bash apply-config.sh infini-ai            # Infini-AI MaaS（Claude 直连 + Codex 经 codex-transfer）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/config-templates"
CLAUDE_DIR="$HOME/.claude"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
CODEX_TRANSFER_DIR="$HOME/.codex-transfer"
PROFILE="$HOME/.profile"
MARKER="# codex-auth-env"

usage() {
  cat <<EOF
用法: bash apply-config.sh [场景]

场景:
  claude-gateway    Claude Code + 第三方网关 (BASE_URL + AUTH_TOKEN)
  claude-official   Claude Code + Anthropic 官方 API Key
  codex-proxy       Codex + openai_base_url 代理
  codex-official    Codex + OpenAI 官方 API
  codex-custom      Codex + 自定义 model_providers
  infini-ai         Infini-AI GenStudio（推荐：Claude 直连 + Codex 经 codex-transfer）

模板目录: $TEMPLATE_DIR
目标:
  Claude         -> $CLAUDE_DIR/settings.json
  Codex          -> $CODEX_DIR/config.toml
  codex-transfer -> $CODEX_TRANSFER_DIR/config.json
EOF
}

backup() {
  local f="$1"
  [[ -f "$f" ]] && cp "$f" "${f}.bak.$(date +%Y%m%d%H%M%S)"
}

merge_claude_env() {
  local src="$1"
  if [[ ! -f "$CLAUDE_DIR/settings.json" ]]; then
    mkdir -p "$CLAUDE_DIR"
    cp "$src" "$CLAUDE_DIR/settings.json"
    echo "已创建 $CLAUDE_DIR/settings.json"
    return
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - <<PY
import json, pathlib
src = json.loads(pathlib.Path("$src").read_text())
dst_path = pathlib.Path("$CLAUDE_DIR/settings.json")
dst = json.loads(dst_path.read_text())
if "model" in src:
    dst["model"] = src["model"]
dst.setdefault("env", {}).update(src.get("env", {}))
dst_path.write_text(json.dumps(dst, indent=2, ensure_ascii=False) + "\n")
print("已合并 model/env 到现有 settings.json（保留插件等配置）")
PY
  else
    echo "警告: 已有 settings.json 且无 python3，请手动合并 env 块"
    echo "模板: $src"
  fi
}

apply_codex_auth_env() {
  local auth_template="${1:-$TEMPLATE_DIR/codex/auth.env.template}"
  mkdir -p "$CODEX_DIR"
  if [[ ! -f "$CODEX_DIR/auth.env" ]]; then
    cp "$auth_template" "$CODEX_DIR/auth.env"
    echo "已创建 $CODEX_DIR/auth.env — 请编辑填入 API Key"
  else
    echo "保留已有 $CODEX_DIR/auth.env"
  fi
  if ! grep -q "$MARKER" "$PROFILE" 2>/dev/null; then
    cat >> "$PROFILE" <<EOF

$MARKER
if [ -f "\$HOME/.codex/auth.env" ]; then
    set -a
    . "\$HOME/.codex/auth.env"
    set +a
fi
EOF
    echo "已在 ~/.profile 添加 auth.env 自动加载"
  fi
}

apply_codex_transfer_config() {
  mkdir -p "$CODEX_TRANSFER_DIR/logs"
  if [[ ! -f "$CODEX_TRANSFER_DIR/config.json" ]]; then
    cp "$TEMPLATE_DIR/codex-transfer/config.template.json" "$CODEX_TRANSFER_DIR/config.json"
    echo "已创建 $CODEX_TRANSFER_DIR/config.json — 请编辑填入 YOUR_INFINI_AI_API_KEY"
  else
    echo "保留已有 $CODEX_TRANSFER_DIR/config.json"
  fi
  if [[ ! -f "$CODEX_TRANSFER_DIR/env" ]]; then
    cp "$TEMPLATE_DIR/codex-transfer/env.template" "$CODEX_TRANSFER_DIR/env"
    echo "已创建 $CODEX_TRANSFER_DIR/env（可选）"
  fi
}

pick="${1:-}"

if [[ -z "$pick" ]]; then
  echo "请选择配置场景:"
  echo "  1) claude-gateway"
  echo "  2) claude-official"
  echo "  3) codex-proxy"
  echo "  4) codex-official"
  echo "  5) codex-custom"
  echo "  6) 全部 (claude-gateway + codex-proxy)"
  echo "  7) infini-ai (Infini-AI GenStudio，推荐)"
  read -rp "输入编号 [1-7]: " n
  case "$n" in
    1) pick=claude-gateway ;;
    2) pick=claude-official ;;
    3) pick=codex-proxy ;;
    4) pick=codex-official ;;
    5) pick=codex-custom ;;
    6) pick=all ;;
    7) pick=infini-ai ;;
    *) echo "无效选择"; usage; exit 1 ;;
  esac
fi

apply_claude_gateway() {
  merge_claude_env "$TEMPLATE_DIR/claude/settings.gateway.template.json"
}

apply_claude_official() {
  merge_claude_env "$TEMPLATE_DIR/claude/settings.official-api.template.json"
}

apply_codex_proxy() {
  mkdir -p "$CODEX_DIR"
  backup "$CODEX_DIR/config.toml"
  cp "$TEMPLATE_DIR/codex/config.openai-proxy.template.toml" "$CODEX_DIR/config.toml"
  apply_codex_auth_env
  echo "已写入 $CODEX_DIR/config.toml"
}

apply_codex_official() {
  mkdir -p "$CODEX_DIR"
  backup "$CODEX_DIR/config.toml"
  cp "$TEMPLATE_DIR/codex/config.official-api.template.toml" "$CODEX_DIR/config.toml"
  apply_codex_auth_env
  echo "已写入 $CODEX_DIR/config.toml"
}

apply_codex_custom() {
  mkdir -p "$CODEX_DIR"
  backup "$CODEX_DIR/config.toml"
  cp "$TEMPLATE_DIR/codex/config.custom-provider.template.toml" "$CODEX_DIR/config.toml"
  apply_codex_auth_env
  echo "已写入 $CODEX_DIR/config.toml"
}

apply_infini_ai() {
  merge_claude_env "$TEMPLATE_DIR/claude/settings.infini-ai.template.json"
  mkdir -p "$CODEX_DIR"
  backup "$CODEX_DIR/config.toml"
  cp "$TEMPLATE_DIR/codex/config.infini-transfer.template.toml" "$CODEX_DIR/config.toml"
  apply_codex_transfer_config
  echo "已配置 Infini-AI:"
  echo "  Claude -> https://cloud.infini-ai.com/maas"
  echo "  Codex  -> http://127.0.0.1:4446/v1 (codex-transfer -> Infini-AI mass/coding)"
}

case "$pick" in
  claude-gateway) apply_claude_gateway ;;
  claude-official) apply_claude_official ;;
  codex-proxy) apply_codex_proxy ;;
  codex-official) apply_codex_official ;;
  codex-custom) apply_codex_custom ;;
  all)
    apply_claude_gateway
    apply_codex_proxy
    ;;
  infini-ai) apply_infini_ai ;;
  -h|--help|help) usage; exit 0 ;;
  *) echo "未知场景: $pick"; usage; exit 1 ;;
esac

cat <<EOF

下一步:
  1. 编辑配置文件，替换 YOUR_* 占位符
     Claude:         $CLAUDE_DIR/settings.json
     Codex:          $CODEX_DIR/config.toml
     codex-transfer: $CODEX_TRANSFER_DIR/config.json
  2. 安装并启动 codex-transfer（infini-ai 场景必需）:
     bash $SCRIPT_DIR/scripts/install-codex-transfer.sh
     bash $SCRIPT_DIR/scripts/start-codex-transfer.sh
  3. source ~/.profile
  4. claude --version && codex doctor
  5. Claude 内执行 /status 验证网关和认证

详细说明: CONFIG-GUIDE.zh-CN.md
EOF

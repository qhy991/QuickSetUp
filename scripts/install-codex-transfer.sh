#!/usr/bin/env bash
# 安装 codex-transfer：Codex Responses API → Infini-AI Chat Completions 协议转换
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUICK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_DIR="${CODEX_TRANSFER_HOME:-$HOME/.local/codex-transfer}"
CONFIG_DIR="${CODEX_TRANSFER_CONFIG_DIR:-$HOME/.codex-transfer}"

mkdir -p "$INSTALL_DIR" "$CONFIG_DIR/logs"

if [[ ! -f "$CONFIG_DIR/config.json" ]]; then
  cp "$QUICK_ROOT/config-templates/codex-transfer/config.template.json" "$CONFIG_DIR/config.json"
  echo "已创建 $CONFIG_DIR/config.json — 请编辑填入 YOUR_INFINI_AI_API_KEY"
fi

if [[ ! -f "$CONFIG_DIR/env" ]]; then
  cp "$QUICK_ROOT/config-templates/codex-transfer/env.template" "$CONFIG_DIR/env"
  echo "已创建 $CONFIG_DIR/env — 可选，用于 export CODEX_TRANSFER_API_KEY"
fi

cd "$INSTALL_DIR"
if [[ ! -f package.json ]]; then
  npm init -y >/dev/null
fi
npm install @classicicn/codex-transfer@^0.4.1

echo "已安装 codex-transfer 到 $INSTALL_DIR"
echo "二进制: $INSTALL_DIR/node_modules/.bin/codex-transfer"
echo "配置:   $CONFIG_DIR/config.json"
echo ""
echo "下一步:"
echo "  1. 编辑 $CONFIG_DIR/config.json 填入 Infini-AI API Key"
echo "  2. bash $QUICK_ROOT/scripts/start-codex-transfer.sh"
echo "  3. curl -s http://127.0.0.1:4446/health"

#!/usr/bin/env bash
# 启动 codex-transfer 本地代理（默认 :4446）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUICK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CONFIG="${CODEX_TRANSFER_CONFIG:-$HOME/.codex-transfer/config.json}"
PID_FILE="$HOME/.codex-transfer/logs/codex-transfer.pid"
INSTALL_DIR="${CODEX_TRANSFER_HOME:-$HOME/.local/codex-transfer}"
BIN="$INSTALL_DIR/node_modules/.bin/codex-transfer"

if [[ ! -x "$BIN" ]]; then
  echo "未找到 codex-transfer: $BIN" >&2
  echo "请先运行: bash $QUICK_ROOT/scripts/install-codex-transfer.sh" >&2
  exit 1
fi

if [[ -f "$HOME/.codex-transfer/env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$HOME/.codex-transfer/env"
  set +a
fi

has_api_key() {
  [[ -n "${CODEX_TRANSFER_API_KEY:-}" || -n "${GENSTUDIO_API_KEY:-}" ]] && return 0
  python3 -c "
import json, sys
with open('$CONFIG') as f:
    cfg = json.load(f)
    key = cfg.get('apiKey', '')
sys.exit(0 if key and key != 'YOUR_INFINI_AI_API_KEY' else 1)
" 2>/dev/null
}

if ! has_api_key; then
  echo "未找到 API Key。请在 $CONFIG 填写 apiKey，或 export CODEX_TRANSFER_API_KEY。" >&2
  exit 1
fi

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "codex-transfer 已在运行 (PID $(cat "$PID_FILE"))"
  curl -sS "http://127.0.0.1:4446/health" || true
  echo
  exit 0
fi

mkdir -p "$HOME/.codex-transfer/logs"
"$BIN" -d -c "$CONFIG"
sleep 1
curl -sS "http://127.0.0.1:4446/health"
echo

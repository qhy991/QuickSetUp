#!/usr/bin/env bash
# 停止 codex-transfer 本地代理
set -euo pipefail

PID_FILE="$HOME/.codex-transfer/logs/codex-transfer.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo "未找到 PID 文件: $PID_FILE"
  exit 1
fi

PID="$(cat "$PID_FILE")"
if kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  echo "已停止 codex-transfer (PID $PID)"
else
  echo "进程 $PID 不存在，清理 PID 文件"
  rm -f "$PID_FILE"
fi

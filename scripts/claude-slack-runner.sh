#!/bin/bash
# Claude Code Slack Runner
# 슬랙 스레드 맥락과 질문을 받아 Claude Code에 전달
#
# 사용법:
#   ./claude-slack-runner.sh "<질문>" [<base64_스레드_컨텍스트>]

set -euo pipefail

# SSH 비대화 세션에서 nvm PATH 로드
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAP_DIR="${CLAP_SERVER_DIR:-$(dirname "$SCRIPT_DIR")}"
PROMPT_FILE="${SCRIPT_DIR}/prompts/slack-bot.md"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <question> [<base64_thread_context>]" >&2
  exit 1
fi

QUESTION="$1"
THREAD_CONTEXT_B64="${2:-}"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

# 스레드 컨텍스트 디코딩
if [ -n "$THREAD_CONTEXT_B64" ]; then
  THREAD_CONTEXT=$(echo "$THREAD_CONTEXT_B64" | base64 -d 2>/dev/null || echo "(스레드 컨텍스트 디코딩 실패)")
else
  THREAD_CONTEXT="(단독 메시지 - 스레드 컨텍스트 없음)"
fi

# 프롬프트 템플릿에서 변수 치환
TEMPLATE=$(<"$PROMPT_FILE")
PROMPT="${TEMPLATE/\{\{QUESTION\}\}/$QUESTION}"
PROMPT="${PROMPT/\{\{THREAD_CONTEXT\}\}/$THREAD_CONTEXT}"

cd "$CLAP_DIR"
exec claude -p "$PROMPT" --output-format text
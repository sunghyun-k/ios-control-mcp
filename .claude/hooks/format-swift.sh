#!/bin/bash
# PostToolUse hook: Edit|Write 후 Swift 파일 자동 포맷팅
#
# 사용법: stdin으로 JSON 데이터를 받음
# 예: echo '{"tool_input":{"file_path":"test.swift"}}' | ./format-swift.sh

FILE=$(cat | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

if [[ "$FILE" == *.swift ]]; then
    swiftformat "$FILE" 2>/dev/null || true
fi

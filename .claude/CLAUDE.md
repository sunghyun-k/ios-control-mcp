# ios-control-mcp

iOS 시뮬레이터/실기기 자동화 MCP 서버.

## 지침

- 한국어로 응답, 주석/커밋도 한국어 가능
- **MCP 도구의 description과 응답은 영어로** (LLM 인터페이스)
- 작업 완료 시 커밋

## 빌드

```bash
mise exec -- tuist build MCPServer 2>&1 | grep -E "(error|warning)"
```

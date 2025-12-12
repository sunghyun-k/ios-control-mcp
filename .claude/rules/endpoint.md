---
paths: UIAutomationServer/**/*.swift
---

# UIAutomationServer 엔드포인트 추가

## 체크리스트

1. **Common**: `Requests.swift`에 RequestBody 타입 추가 (Codable, Sendable)
2. **Handler**: `Handlers/`에 핸들러 구현 (HTTPHandler 프로토콜)
3. **Entry**: `Entry.swift`에 라우트 등록
4. **Client**: `iOSAutomation/Client/UIAutomationClient.swift`에 메서드 추가

## Handler 템플릿

```swift
struct FooHandler: HTTPHandler {
    @MainActor
    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard let bundleId = request.routeParameters["bundleId"] else {
            return .badRequest("Missing bundleId")
        }
        // ...
        return .ok()
    }
}
```

## 주의사항

- `@MainActor` 필수 (XCUIElement 접근)
- 에러 응답: `.badRequest()`, `.notFound()` 등 사용
- 요소 대기: `element.waitForExistence(timeout: 5)`

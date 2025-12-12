# Swift 코드 스타일

## 최신 API 사용 (Deprecated API 금지)

```swift
// URL
URL(filePath: path)                    // ✓
URL(fileURLWithPath: path)             // ✗ deprecated

url.appending(path: "foo")             // ✓
url.appendingPathComponent("foo")      // ✗ deprecated

url.appending(component: "bar")        // ✓ (단일 컴포넌트)

// FileManager
FileManager.default.currentDirectoryURL  // ✓ (macOS 13+)
```

## Concurrency

- `Sendable` 준수 필수 (특히 Codable 타입)
- `@MainActor`는 UI 관련 코드에만
- `async/await` 사용, completion handler 지양

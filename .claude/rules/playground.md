# Playground 테스트

기능 테스트 및 디버깅을 위한 playground 환경.

## 파일 위치

`MCPServer/Tests/iOSAutomationTests/Playground.swift`

## 실행 방법

```bash
mise run playground
```

## 사용법

1. `Playground.swift` 파일을 수정하여 테스트할 코드 작성
2. `mise run playground` 실행
3. print 출력으로 결과 확인

## 예시

```swift
import Foundation
import Testing
@testable import iOSAutomation

@Test("Playground")
func playground() async throws {
    let deviceManager = DeviceManager()
    let devices = try deviceManager.listAllDevices()

    for device in devices {
        print("[\(device.type)] \(device.name)")
    }
}
```

## 참고

- `@testable import iOSAutomation`으로 internal 멤버 접근 가능
- async/await 사용 가능
- 실패 시 `throw` 또는 `#expect()` 매크로 사용

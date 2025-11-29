import Foundation

@MainActor
class RunnerDaemonProxy {
    static let shared = RunnerDaemonProxy()

    private let proxy: NSObject

    private init() {
        let session = ObjCBridge.invokeClassMethod("XCTRunnerDaemonSession", selector: "sharedSession")!
        proxy = session
            .perform(NSSelectorFromString("daemonProxy"))
            .takeUnretainedValue() as! NSObject
    }

    func send(string: String, typingFrequency: Int = Constants.defaultTypingFrequency) async throws {
        let selector = NSSelectorFromString("_XCT_sendString:maximumFrequency:completion:")
        let imp = proxy.method(for: selector)
        typealias Method = @convention(c) (NSObject, Selector, NSString, Int, @escaping (Error?) -> ()) -> ()
        let method = unsafeBitCast(imp, to: Method.self)
        return try await withCheckedThrowingContinuation { continuation in
            method(proxy, selector, string as NSString, typingFrequency, { error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                } else {
                    continuation.resume(with: .success(()))
                }
            })
        }
    }

    func synthesize(eventRecord: EventRecord) async throws {
        let selector = NSSelectorFromString("_XCT_synthesizeEvent:completion:")
        let imp = proxy.method(for: selector)
        typealias Method = @convention(c) (NSObject, Selector, NSObject, @escaping (Error?) -> ()) -> ()
        let method = unsafeBitCast(imp, to: Method.self)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            method(proxy, selector, eventRecord.eventRecord, { error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                } else {
                    continuation.resume(with: .success(()))
                }
            })
        }
    }
}

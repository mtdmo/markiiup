import CoreServices
import Foundation

final class WorkspaceFileWatcher {
    typealias EventHandler = @Sendable ([String]) -> Void

    private let rootURL: URL
    private let handler: EventHandler
    private let queue = DispatchQueue(label: "com.mtdmo.markiiupMac.workspace-watcher", qos: .utility)
    private var stream: FSEventStreamRef?

    init(rootURL: URL, handler: @escaping EventHandler) {
        self.rootURL = rootURL.standardizedFileURL
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() {
        guard stream == nil else {
            return
        }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: retainCallback,
            release: releaseCallback,
            copyDescription: nil
        )

        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer
        )

        let watchedPaths = [rootURL.path] as CFArray
        let createdStream = FSEventStreamCreate(
            kCFAllocatorDefault,
            eventCallback,
            &context,
            watchedPaths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.35,
            flags
        )

        guard let createdStream else {
            return
        }

        stream = createdStream
        FSEventStreamSetDispatchQueue(createdStream, queue)
        FSEventStreamStart(createdStream)
    }

    func stop() {
        guard let stream else {
            return
        }

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    private let eventCallback: FSEventStreamCallback = { _, info, eventCount, eventPaths, _, _ in
        guard let info else {
            return
        }

        let watcher = Unmanaged<WorkspaceFileWatcher>.fromOpaque(info).takeUnretainedValue()
        let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as? [String] ?? []
        guard eventCount > 0, !paths.isEmpty else {
            return
        }

        watcher.handler(Array(paths.prefix(Int(eventCount))))
    }

    private let retainCallback: CFAllocatorRetainCallBack = { info in
        guard let info else {
            return nil
        }

        _ = Unmanaged<WorkspaceFileWatcher>.fromOpaque(info).retain()
        return info
    }

    private let releaseCallback: CFAllocatorReleaseCallBack = { info in
        guard let info else {
            return
        }

        Unmanaged<WorkspaceFileWatcher>.fromOpaque(info).release()
    }
}

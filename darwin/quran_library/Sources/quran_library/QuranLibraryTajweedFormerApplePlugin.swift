#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
import AppKit
import SwiftUI
#endif
import Foundation
import TajweedFormer

/// Optional Apple inference bridge. It does not judge or correct a recitation.
@MainActor
public final class QuranLibraryTajweedFormerApplePlugin: NSObject, @preconcurrency FlutterPlugin {
    private let channel: FlutterMethodChannel
    private var client: TajweedClient?
    private var keeper: TajweedClient?
    private var model: TajweedModel?
    private var session: TajweedSession?
    private var collector: Task<Void, Never>?
    private var busy = false
    private var detached = false
    #if os(macOS)
    private weak var viewController: NSViewController?
    private var sharingHost: NSView?
    private var sharingHostReady = false
    #endif

    private init(channel: FlutterMethodChannel) { self.channel = channel }

    public nonisolated static func register(with registrar: FlutterPluginRegistrar) {
        MainActor.assumeIsolated { registerOnMain(with: registrar) }
    }

    private static func registerOnMain(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let channel = FlutterMethodChannel(name: "quran_library/tajweedformer_apple", binaryMessenger: registrar.messenger())
        #else
        let channel = FlutterMethodChannel(name: "quran_library/tajweedformer_apple", binaryMessenger: registrar.messenger)
        #endif
        let plugin = QuranLibraryTajweedFormerApplePlugin(channel: channel)
        #if os(macOS)
        plugin.viewController = registrar.viewController
        #endif
        registrar.addMethodCallDelegate(plugin, channel: channel)
        registrar.publish(plugin)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        detached = true
        Task { @MainActor in
            await self.closeClient()
            #if os(macOS)
            self.removeSharingHost()
            #endif
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "available" {
            #if arch(arm64)
            result(true)
            #else
            result(false)
            #endif
            return
        }
        guard !busy && !detached else {
            result(FlutterError(code: "session_busy", message: "A V4 operation is already running", details: nil))
            return
        }
        busy = true
        Task { @MainActor in
            defer { self.busy = false }
            do { result(try await self.execute(call)) }
            catch let error as TajweedError {
                result(FlutterError(code: error.code, message: error.message, details: ["fix": error.fix, "docs": error.docs]))
            } catch {
                result(FlutterError(code: "tajweedformer_error", message: error.localizedDescription, details: nil))
            }
        }
    }

    private func requiredModel() throws -> TajweedModel {
        guard let model else { throw BridgeError("TajweedFormer is not initialized") }
        return model
    }

    private func requiredSession() throws -> TajweedSession {
        guard let session else { throw BridgeError("No take is open") }
        return session
    }

    private func execute(_ call: FlutterMethodCall) async throws -> Any? {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "configuredKey":
            return try hostKey()
        case "prefetch":
            let key = args["key"] as? String ?? ""
            let next = try prefetchClient(key.isEmpty ? hostKey() : key)
            try await next.prefetch(unmeteredOnly: args["unmeteredOnly"] as? Bool ?? false,
                                    onProgress: { done, total in
                Task { @MainActor in
                    self.channel.invokeMethod("prefetchProgress",
                                              arguments: ["done": done, "total": total])
                }
            })
            return true
        case "removeModels":
            let key = args["key"] as? String ?? ""
            try prefetchClient(key.isEmpty ? hostKey() : key).removeModels()
            return true
        case "initialize":
            guard client == nil, let key = args["key"] as? String, !key.isEmpty else { throw BridgeError("A key and a new client are required") }
            keeper?.close()
            keeper = nil
            let next = try TajweedClient(key: key)
            do {
                #if os(macOS)
                try await installSharingHost(next)
                #endif
                let loaded = try await next.model()
                if detached {
                    await loaded.close()
                    throw BridgeError("Flutter engine was detached")
                }
                guard let calibration = loaded.calibration,
                      let json = String(data: calibration.data, encoding: .utf8),
                      let wordBar = loaded.tokens.wordBar else { throw BridgeError("Model metadata is incomplete") }
                client = next
                model = loaded
                return ["version": loaded.version, "build": loaded.build,
                        "blank": loaded.tokens.blank, "wordBar": wordBar,
                        "tokens": (0..<loaded.tokens.count).map { loaded.tokens.name($0) },
                        "defaultContext": loaded.defaultContext,
                        "calibrationJson": json, "calibrationSha256": calibration.sha256]
            } catch {
                next.close()
                throw error
            }
        case "reference":
            let loaded = try requiredModel()
            guard let reference = loaded.reference, let surah = args["surah"] as? Int,
                  let ayah = args["ayah"] as? Int, let bar = loaded.tokens.wordBar else {
                throw BridgeError("Reference or verse is unavailable")
            }
            try await reference.fetch()
            let data = try reference.units(surah: surah, ayah: ayah)
            var word = 0
            var starts = [0]
            let words = data.units.enumerated().map { index, id in
                let current = word
                if id == bar { word += 1; starts.append(index + 1) }
                return current
            }
            guard starts == data.wordStarts else { throw BridgeError("Reference word boundaries disagree") }
            return ["units": data.units, "words": words, "wordCount": word + 1]
        case "diagnose":
            guard let client else { throw BridgeError("TajweedFormer is not initialized") }
            let diagnosis = await client.diagnose()
            return try JSONSerialization.jsonObject(with: Data(diagnosis.json.utf8))
        case "sample":
            guard session == nil else { throw BridgeError("A take is already open") }
            let loaded = try requiredModel()
            guard let clip = loaded.sampleClips.first else { throw BridgeError("No sample clip is available") }
            let take = try await loaded.listen(from: clip, options: TajweedSessionOptions(pace: .fast))
            return try await runSource(take)
        case "recognize":
            guard session == nil else { throw BridgeError("A take is already open") }
            let samples = try Self.samples(args)
            let take = try await requiredModel().listen(from: samples, sampleRate: 16000, options: TajweedSessionOptions(pace: .fast))
            return try await runSource(take)
        case "start":
            guard session == nil else { throw BridgeError("A take is already open") }
            let take = try await requiredModel().session(options: TajweedSessionOptions(sampleRate: 16000))
            if detached { await take.cancel(); throw BridgeError("Flutter engine was detached") }
            session = take
            collector = Task { @MainActor in
                for await chunk in take.chunks {
                    self.channel.invokeMethod("chunk", arguments: Self.decoded(chunk.decoded).merging(["speech": chunk.speech]) { _, new in new })
                }
            }
            return nil
        case "push":
            try requiredSession().push(Self.samples(args))
            return nil
        case "finish":
            let take = try requiredSession()
            do {
                let heads = try await take.finish()
                await collector?.value
                session = nil
                collector = nil
                return Self.heads(heads)
            } catch {
                await take.cancel()
                collector?.cancel()
                session = nil
                collector = nil
                throw error
            }
        case "cancel":
            await cancelTake()
            return nil
        case "close":
            await closeClient()
            return nil
        default:
            throw BridgeError("Unknown V4 method")
        }
    }

    private func runSource(_ take: TajweedSession) async throws -> [String: Any] {
        do {
            var final: TajweedDecoded?
            for await chunk in take.chunks { if chunk.decoded.isFinal { final = chunk.decoded } }
            let heads = try await take.finish()
            guard let final else { throw BridgeError("No final output from the audio") }
            return Self.decoded(final).merging(["heads": Self.heads(heads)]) { _, new in new }
        } catch { await take.cancel(); throw error }
    }

    private func cancelTake() async {
        let take = session
        session = nil
        await take?.cancel()
        collector?.cancel()
        collector = nil
    }

    private func closeClient() async {
        await cancelTake()
        await model?.close()
        model = nil
        client?.close()
        client = nil
        keeper?.close()
        keeper = nil
    }

    /// Reads the host's git-ignored QuranLabKey from Info.plist.
    private func hostKey() throws -> String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "QuranLabKey") as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !key.hasPrefix("$(") else { throw BridgeError("QuranLabKey is not configured") }
        return key
    }

    /// A dedicated download client so prefetch works before initialize; the
    /// files it fetches stay in the SDK's own storage for the next model().
    private func prefetchClient(_ key: String) throws -> TajweedClient {
        guard client == nil else { throw BridgeError("TajweedFormer is already initialized") }
        if let keeper { return keeper }
        let next = try TajweedClient(key: key)
        keeper = next
        return next
    }

    #if os(macOS)
    /// The SDK's sharing modifier must be attached to the active Flutter
    /// window before a take can begin. The host never intercepts app input.
    private func installSharingHost(_ client: TajweedClient) async throws {
        guard let owner = viewController, owner.view.window != nil else {
            throw BridgeError("A visible Flutter window is required for the SDK sharing sheet")
        }
        let oldHost = sharingHost
        sharingHostReady = false
        let root = Color.clear.quranLabSharing(client).onAppear { [weak self] in
            self?.sharingHostReady = true
        }
        let host = SharingHostView(rootView: AnyView(root))
        host.frame = owner.view.bounds
        host.autoresizingMask = [.width, .height]
        owner.view.addSubview(host)
        sharingHost = host
        for _ in 0..<100 {
            if sharingHostReady && host.window != nil {
                oldHost?.removeFromSuperview()
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        host.removeFromSuperview()
        sharingHost = oldHost
        sharingHostReady = oldHost != nil
        throw BridgeError("The SDK sharing host did not become visible")
    }

    private func removeSharingHost() {
        sharingHost?.removeFromSuperview()
        sharingHost = nil
        sharingHostReady = false
    }
    #endif

    private static func samples(_ args: [String: Any]) throws -> [Float] {
        guard let data = (args["samples"] as? FlutterStandardTypedData)?.data,
              data.count % MemoryLayout<Float>.size == 0 else { throw BridgeError("Invalid PCM samples") }
        var samples = [Float](repeating: 0, count: data.count / MemoryLayout<Float>.size)
        _ = samples.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        return samples
    }

    private static func decoded(_ value: TajweedDecoded) -> [String: Any] {
        let tokens: [[String: Any]] = value.tokens.map { token in
            ["id": token.id, "name": token.name, "firstMs": token.firstMs,
             "peakMs": token.peakMs, "lastMs": token.lastMs,
             "confidence": token.confidence.map { $0 as Any } ?? NSNull()]
        }
        return ["text": value.text, "tokens": tokens, "settled": value.settled, "isFinal": value.isFinal]
    }

    private static func heads(_ value: TajweedHeads) -> [String: Any] {
        var result: [String: Any] = [:]
        for name in value.names {
            guard let head = value[name] else { continue }
            let data = head.values.withUnsafeBufferPointer { Data(buffer: $0) }
            result[name] = ["frames": head.frames, "classes": head.classes,
                            "frameMs": head.frameMs, "values": FlutterStandardTypedData(float32: data)]
        }
        return result
    }
}

#if os(macOS)
/// The SDK's sheet is a separate system presentation. Passing through mouse
/// hits here keeps the full-window host from blocking the Flutter interface.
@MainActor
private final class SharingHostView: NSHostingView<AnyView> {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
#endif

private struct BridgeError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

package com.alheekmah.quranPackage

import android.content.Context
import ai.quranlab.tajweedformer.TajweedClient
import ai.quranlab.tajweedformer.TajweedDecoded
import ai.quranlab.tajweedformer.TajweedError
import ai.quranlab.tajweedformer.TajweedHeads
import ai.quranlab.tajweedformer.TajweedModel
import ai.quranlab.tajweedformer.TajweedSession
import ai.quranlab.tajweedformer.TajweedSessionOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Optional API-26+ inference bridge; it never issues recitation verdicts. */
class TajweedFormerAndroidBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, AutoCloseable {
    private val channel = MethodChannel(messenger, "quran_library/tajweedformer_android")
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val mutex = Mutex()
    private var client: TajweedClient? = null
    private var prefetchKeeper: TajweedClient? = null
    private var model: TajweedModel? = null
    private var session: TajweedSession? = null
    private var collector: Job? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "available") { result.success(true); return }
        scope.launch {
            try {
                val value = mutex.withLock { execute(call) }
                result.success(value)
            } catch (e: TajweedError) {
                result.error(e.code, e.message, mapOf("fix" to e.fix, "docs" to e.docs))
            } catch (e: Exception) {
                result.error("tajweedformer_error", e.message ?: e.javaClass.simpleName, null)
            }
        }
    }

    private fun requireModel(): TajweedModel = model ?: error("TajweedFormer is not initialized")
    private fun requireSession(): TajweedSession = session ?: error("No take is open")

    private suspend fun execute(call: MethodCall): Any? = when (call.method) {
        "initialize" -> {
            check(client == null) { "TajweedFormer is already initialized" }
            val key = call.argument<String>("key") ?: error("A key is required")
            prefetchKeeper?.close()
            prefetchKeeper = null
            val next = TajweedClient(context, key)
            try {
                val loaded = next.model()
                val calibration = loaded.calibration ?: error("This model has no calibration")
                client = next
                model = loaded
                mapOf("version" to loaded.version, "build" to loaded.build,
                    "blank" to loaded.tokens.blank, "wordBar" to loaded.tokens.wordBar,
                    "tokens" to loaded.tokens.names, "defaultContext" to loaded.defaultContext,
                    "calibrationJson" to calibration.json, "calibrationSha256" to calibration.sha256)
            } catch (e: Exception) { next.close(); throw e }
        }
        "reference" -> {
            val m = requireModel()
            val ref = m.reference ?: error("This model has no reference")
            ref.fetch()
            val units = ref.units(call.argument<Int>("surah") ?: error("surah is required"),
                call.argument<Int>("ayah") ?: error("ayah is required"))
            var word = 0
            val words = units.map { id -> val current = word; if (id == m.tokens.wordBar) word++; current }
            mapOf("units" to units.toList(), "words" to words, "wordCount" to word + 1)
        }
        "diagnose" -> client?.diagnose()?.toMap() ?: error("TajweedFormer is not initialized")
        "prefetch" -> {
            val key = call.argument<String>("key") ?: error("A key is required")
            val unmeteredOnly = call.argument<Boolean>("unmeteredOnly") ?: false
            val next = prefetchClient(key)
            next.prefetch(unmeteredOnly = unmeteredOnly) { done, total ->
                scope.launch {
                    channel.invokeMethod("prefetchProgress",
                        mapOf("done" to done, "total" to total))
                }
            }
            true
        }
        "removeModels" -> {
            val key = call.argument<String>("key") ?: error("A key is required")
            prefetchClient(key).removeModels()
            true
        }
        "sample" -> {
            val m = requireModel()
            val clip = m.sampleClips.firstOrNull() ?: error("No sample clip is available")
            check(session == null) { "A take is already open" }
            val current = m.listen(clip, TajweedSessionOptions(pace = TajweedSessionOptions.Pace.FAST))
            runSource(current)
        }
        "recognize" -> {
            check(session == null) { "A take is already open" }
            val samples = call.argument<FloatArray>("samples") ?: error("samples are required")
            val current = requireModel().listen(samples, 16000, TajweedSessionOptions(pace = TajweedSessionOptions.Pace.FAST))
            runSource(current)
        }
        "start" -> {
            check(session == null) { "A take is already open" }
            val current = requireModel().session(TajweedSessionOptions(sampleRate = 16000))
            session = current
            collector = scope.launch {
                try {
                    current.chunks.collect { chunk ->
                        channel.invokeMethod("chunk", decoded(chunk.decoded) + mapOf("speech" to chunk.speech))
                    }
                } catch (e: Exception) {
                    if (session === current) channel.invokeMethod("streamError", e.message ?: "Stream failed")
                }
            }
            null
        }
        "push" -> { requireSession().push(call.argument<FloatArray>("samples") ?: error("samples are required")); null }
        "finish" -> {
            val current = requireSession()
            try {
                val heads = current.finish()
                collector?.join()
                encodeHeads(heads)
            } catch (e: Exception) {
                current.cancel()
                collector?.cancel()
                throw e
            } finally { session = null; collector = null }
        }
        "cancel" -> { cancelTake(); null }
        "close" -> { closeClient(); null }
        else -> throw IllegalArgumentException("Unknown method: ${call.method}")
    }

    private suspend fun runSource(current: TajweedSession): Map<String, Any> {
        try {
            var final: TajweedDecoded? = null
            current.chunks.collect { if (it.decoded.isFinal) final = it.decoded }
            val heads = current.finish()
            val last = final ?: error("No final output from the audio")
            return decoded(last) + mapOf("heads" to encodeHeads(heads))
        } catch (e: Exception) { current.cancel(); throw e }
    }

    private fun decoded(value: TajweedDecoded): Map<String, Any> = mapOf(
        "text" to value.text, "settled" to value.settled, "isFinal" to value.isFinal,
        "tokens" to value.tokens.map { mapOf("id" to it.id, "name" to it.name,
            "firstMs" to it.firstMs, "peakMs" to it.peakMs, "lastMs" to it.lastMs,
            "confidence" to it.confidence.toDouble()) })

    private fun encodeHeads(heads: TajweedHeads): Map<String, Any> = heads.names.associateWith { name ->
        val h = heads[name] ?: error("Missing head $name")
        mapOf("frames" to h.frames, "classes" to h.classes, "frameMs" to h.frameMs, "values" to h.values)
    }

    private fun cancelTake() {
        val current = session
        session = null
        current?.cancel()
        collector?.cancel()
        collector = null
    }

    /// A dedicated download client so prefetch works before initialize; its
    /// downloaded files stay in the SDK's own storage for the next model().
    private fun prefetchClient(key: String): TajweedClient {
        check(client == null) { "TajweedFormer is already initialized" }
        val existing = prefetchKeeper
        if (existing != null) return existing
        val next = TajweedClient(context, key)
        prefetchKeeper = next
        return next
    }

    private fun closeClient() {
        cancelTake()
        model?.close()
        model = null
        client?.close()
        client = null
        prefetchKeeper?.close()
        prefetchKeeper = null
    }

    override fun close() { scope.cancel(); closeClient() }
}

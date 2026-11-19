package com.alheekmah.quranPackage;

import androidx.annotation.NonNull;
import android.os.Build;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodChannel;

public class QuranLibraryPlugin implements FlutterPlugin {
    private MethodChannel channel;
    private AutoCloseable bridge;
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "quran_library/tajweedformer_android");
        if (Build.VERSION.SDK_INT >= 26) {
            try {
                Class<?> type = Class.forName("com.alheekmah.quranPackage.TajweedFormerAndroidBridge");
                Object instance = type.getConstructor(android.content.Context.class,
                        io.flutter.plugin.common.BinaryMessenger.class)
                        .newInstance(binding.getApplicationContext(), binding.getBinaryMessenger());
                bridge = (AutoCloseable) instance;
                channel.setMethodCallHandler((MethodChannel.MethodCallHandler) instance);
                return;
            } catch (ClassNotFoundException ignored) {
                // The SDK is an explicit build-time opt-in.
            } catch (ReflectiveOperationException e) {
                throw new IllegalStateException("Unable to attach TajweedFormer bridge", e);
            }
        }
        channel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("available")) result.success(false);
            else result.error("runtime_unsupported", "TajweedFormer requires its optional Android bridge and Android 8 or later", null);
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) channel.setMethodCallHandler(null);
        if (bridge != null) {
            try { bridge.close(); } catch (Exception ignored) { }
        }
        channel = null;
        bridge = null;
    }
}

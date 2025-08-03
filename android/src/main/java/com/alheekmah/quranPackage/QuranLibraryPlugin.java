package com.alheekmah.quranPackage;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.PluginRegistry;

public class QuranLibraryPlugin implements FlutterPlugin {
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        // No implementation needed for manifest merging
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        // No implementation needed for manifest merging
    }

    // Maintain compatibility with apps that don't use the v2 embedding
    public static void registerWith(PluginRegistry.Registrar registrar) {
        // No implementation needed for manifest merging
    }
}

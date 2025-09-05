import 'dart:convert' show json;
import 'dart:developer' show log;
import 'dart:io' show File, Directory;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart' show NativeDatabase;
// ignore: implementation_imports
import 'package:drift/src/runtime/api/runtime_api.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, Clipboard, ClipboardData, ByteData;
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_library/quran.dart'
    show
        ToastUtils,
        AyahModel,
        QuranCtrl,
        QuranLibrary,
        FontSizeExtension,
        TextSpanExtension,
        ContextExtensions,
        QuranGetters;

import '/src/tafsir/core/extensions/helpers.dart';
import 'core/data/models/tafsir.dart';

part 'controller/tafsir_ctrl.dart';
part 'controller/tafsir_ui.dart';
part 'core/data/data_source/tafsir_database.dart';
part 'core/data/data_source/tafsir_database.g.dart';
part 'core/data/models/tafsir_and_translate_names.dart';
part 'core/data/models/tafsir_name_model.dart';
part 'core/data/models/tafsir_style.dart';
part 'core/data/models/translation_model.dart';
part 'core/extensions/download_extension.dart';
part 'core/extensions/show_tafsir_extension.dart';
part 'core/utils/storage_constants.dart';
part 'pages/show_tafsir.dart';
part 'widgets/actual_tafsir_widget.dart';
part 'widgets/change_tafsir.dart';
part 'widgets/tafsir_pages_build.dart';

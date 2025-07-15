import 'dart:convert' show json, jsonDecode, jsonEncode;
import 'dart:developer' show log;
import 'dart:io' show File, Platform, Directory;
import 'dart:math' as math show max;

import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler_animation.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'src/core/utils/smooth_page_physics.dart';
import 'src/data/models/tafsir/tafsir.dart';

part 'src/core/extensions/convert_arabic_to_english_numbers_extension.dart';
part 'src/core/extensions/convert_number_extension.dart';
part 'src/core/extensions/download_estension.dart';
part 'src/core/extensions/extensions.dart';
part 'src/core/extensions/font_size_extension.dart';
part 'src/core/extensions/fonts_download_widget.dart';
part 'src/core/extensions/fonts_extension.dart';
part 'src/core/extensions/sajda_extension.dart';
part 'src/core/extensions/show_tafsir_extension.dart';
part 'src/core/extensions/string_extensions.dart';
part 'src/core/extensions/surah_info_extension.dart';
part 'src/core/extensions/text_span_extension.dart';
part 'src/core/utils/assets_path.dart';
part 'src/core/utils/storage_constants.dart';
part 'src/core/utils/toast_utils.dart';
part 'src/data/data_source/tafsir_database.dart';
part 'src/data/data_source/tafsir_database.g.dart';
part 'src/data/models/ayah_model.dart';
part 'src/data/models/quran_constants.dart';
part 'src/data/models/quran_fonts_models/download_fonts_dialog_style.dart';
part 'src/data/models/quran_fonts_models/sajda_model.dart';
part 'src/data/models/quran_page.dart';
part 'src/data/models/styles_models/banner_style.dart';
part 'src/data/models/styles_models/basmala_style.dart';
part 'src/data/models/styles_models/bookmark.dart';
part 'src/data/models/styles_models/surah_info_style.dart';
part 'src/data/models/styles_models/surah_name_style.dart';
part 'src/data/models/styles_models/surah_names_model.dart';
part 'src/data/models/tafsir/tafsir_and_translate_names.dart';
part 'src/data/models/tafsir/tafsir_name_model.dart';
part 'src/data/models/tafsir/tafsir_style.dart';
part 'src/data/models/tafsir/translation_model.dart';
part 'src/data/repositories/quran_repository.dart';
part 'src/flutter_quran_utils.dart';
part 'src/presentation/controllers/bookmark/bookmarks_ctrl.dart';
part 'src/presentation/controllers/quran/quran_ctrl.dart';
part 'src/presentation/controllers/quran/quran_getters.dart';
part 'src/presentation/controllers/quran/quran_state.dart';
part 'src/presentation/controllers/surah/surah_ctrl.dart';
part 'src/presentation/controllers/tafsir/tafsir_ctrl.dart';
part 'src/presentation/controllers/tafsir/tafsir_ui.dart';
part 'src/presentation/pages/quran_library_screen.dart';
part 'src/presentation/pages/surah_display_screen.dart';
part 'src/presentation/widgets/all_quran_widget.dart';
part 'src/presentation/widgets/ayah_long_click_dialog.dart';
part 'src/presentation/widgets/bsmallah_widget.dart';
part 'src/presentation/widgets/change_tafsir.dart';
part 'src/presentation/widgets/custom_span.dart';
part 'src/presentation/widgets/default_drawer.dart';
part 'src/presentation/widgets/fonts_download_dialog.dart';
part 'src/presentation/widgets/quran_fonts_page.dart';
part 'src/presentation/widgets/quran_library_search_screen.dart';
part 'src/presentation/widgets/quran_line.dart';
part 'src/presentation/widgets/quran_line_page.dart';
part 'src/presentation/widgets/quran_text_scale.dart';
part 'src/presentation/widgets/show_tafseer.dart';
part 'src/presentation/widgets/surah_header_widget.dart';


/// A comprehensive library for displaying the Holy Quran in Flutter applications.
///
/// This library provides a set of widgets, controllers, and data models to facilitate
/// the integration of Quranic text, tafsir (exegesis), and various display styles
/// into Flutter projects. It aims to offer a highly customizable and performant
/// solution for Quranic applications.
///
/// The core components of this library include:
/// - **Data Models**: Representing Ayahs, Surahs, Quran pages, and Tafsir data.
/// - **Controllers**: Managing the state and logic for Quran display, search, and bookmarking.
/// - **Widgets**: Reusable UI components for rendering Quranic text, surah headers, and interactive elements.
/// - **Utilities & Extensions**: Helper functions and Dart extensions for common tasks like number conversion, text normalization, and asset management.
///
/// This file (`quran.dart`) serves as the main entry point for the library, parting
/// all necessary components and defining the `part` directives for modular organization.
///
/// To use this library, import `package:quran_library/quran_library.dart` and utilize
/// the provided classes and functions. Ensure that all required assets (fonts, JSONs, DB) are correctly configured in `pubspec.yaml`.






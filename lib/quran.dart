import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:developer' show log;
import 'dart:io' show File, Platform, Directory, InternetAddress;
import 'dart:math' as math show max;

import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler_animation.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:archive/archive.dart' show ZipDecoder;
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'core/utils/ui_helper.dart';
import 'src/audio/audio.dart';
import 'src/quran/core/helpers/responsive.dart';
import 'src/tafsir/tafsir.dart';

part 'src/audio/widgets/slider/bottom_slider.dart';
part 'src/audio/widgets/slider/controller/slider_controller.dart';
part 'src/flutter_quran_utils.dart';
part 'src/quran/core/extensions/convert_arabic_to_english_numbers_extension.dart';
part 'src/quran/core/extensions/convert_number_extension.dart';
part 'src/quran/core/extensions/extensions.dart';
part 'src/quran/core/extensions/font_size_extension.dart';
part 'src/quran/core/extensions/fonts_download_widget.dart';
part 'src/quran/core/extensions/fonts_extension.dart';
part 'src/quran/core/extensions/sajda_extension.dart';
part 'src/quran/core/extensions/string_extensions.dart';
part 'src/quran/core/extensions/surah_info_extension.dart';
part 'src/quran/core/extensions/text_span_extension.dart';
part 'src/quran/core/utils/assets_path.dart';
part 'src/quran/core/utils/storage_constants.dart';
part 'src/quran/core/utils/toast_utils.dart';
part 'src/quran/data/models/ayah_model.dart';
part 'src/quran/data/models/quran_constants.dart';
part 'src/quran/data/models/quran_fonts_models/download_fonts_dialog_style.dart';
part 'src/quran/data/models/quran_fonts_models/sajda_model.dart';
part 'src/quran/data/models/quran_page.dart';
part 'src/quran/data/models/styles_models/banner_style.dart';
part 'src/quran/data/models/styles_models/basmala_style.dart';
part 'src/quran/data/models/styles_models/bookmark.dart';
part 'src/quran/data/models/styles_models/surah_info_style.dart';
part 'src/quran/data/models/styles_models/surah_name_style.dart';
part 'src/quran/data/models/styles_models/surah_names_model.dart';
part 'src/quran/data/repositories/quran_repository.dart';
part 'src/quran/presentation/controllers/bookmark/bookmarks_ctrl.dart';
part 'src/quran/presentation/controllers/quran/quran_ctrl.dart';
part 'src/quran/presentation/controllers/quran/quran_getters.dart';
part 'src/quran/presentation/controllers/quran/quran_state.dart';
part 'src/quran/presentation/controllers/surah/surah_ctrl.dart';
part 'src/quran/presentation/pages/quran_library_screen.dart';
part 'src/quran/presentation/pages/surah_display_screen.dart';
part 'src/quran/presentation/widgets/ayah_long_click_dialog.dart';
part 'src/quran/presentation/widgets/bsmallah_widget.dart';
part 'src/quran/presentation/widgets/default_drawer.dart';
part 'src/quran/presentation/widgets/default_fonts_page/default_first_two_surahs.dart';
part 'src/quran/presentation/widgets/default_fonts_page/default_fonts.dart';
part 'src/quran/presentation/widgets/default_fonts_page/default_fonts_page.dart';
part 'src/quran/presentation/widgets/default_fonts_page/default_fonts_page_build.dart';
part 'src/quran/presentation/widgets/default_fonts_page/default_other_surahs.dart';
part 'src/quran/presentation/widgets/download_fonts_page/custom_span.dart';
part 'src/quran/presentation/widgets/download_fonts_page/page_build.dart';
part 'src/quran/presentation/widgets/download_fonts_page/quran_fonts_page.dart';
part 'src/quran/presentation/widgets/download_fonts_page/rich_text_build.dart';
part 'src/quran/presentation/widgets/fonts_download_dialog.dart';
part 'src/quran/presentation/widgets/page_view_build.dart';
part 'src/quran/presentation/widgets/quran_library_search_screen.dart';
part 'src/quran/presentation/widgets/surah_header_widget.dart';
part 'src/quran/presentation/widgets/text_scale_page/text_scale_page.dart';
part 'src/quran/presentation/widgets/text_scale_page/text_scale_rich_text_build.dart';
part 'src/quran/presentation/widgets/top_bottom_widget/build_bottom_section.dart';
part 'src/quran/presentation/widgets/top_bottom_widget/build_top_section.dart';
part 'src/quran/presentation/widgets/top_bottom_widget/top_and_bottom_widget.dart';


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






/// مصنع محرّك Zipformer الشرطي — يعزل sherpa_onnx (dart:ffi) عن الويب.
///
/// Conditional sherpa engine factory — isolates sherpa_onnx (dart:ffi) from
/// web builds: native platforms get the real engine, web gets a stub.
library;

export 'sherpa_factory_stub.dart' if (dart.library.io) 'sherpa_factory_io.dart';

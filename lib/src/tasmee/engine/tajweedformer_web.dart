/// Optional V4 inference on the web. This API does not judge recitation.
library;

export 'tajweedformer_web_stub.dart'
    if (dart.library.html) 'tajweedformer_web_impl.dart';

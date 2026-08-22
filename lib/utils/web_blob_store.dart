import 'dart:typed_data';

import 'web_blob_store_stub.dart'
    if (dart.library.html) 'web_blob_store_web.dart' as impl;

Future<void> putPhotoBlob(String id, Uint8List bytes) =>
    impl.putPhotoBlob(id, bytes);

Future<Uint8List?> getPhotoBlob(String id) => impl.getPhotoBlob(id);

Future<void> deletePhotoBlob(String id) => impl.deletePhotoBlob(id);

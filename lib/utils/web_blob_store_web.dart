import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

const _dbName = 'getmeback_photos';
const _storeName = 'photos';
const _dbVersion = 1;

Future<T> _awaitRequest<T extends JSAny?>(IDBRequest request) {
  final completer = Completer<T>();
  request.onsuccess = ((Event _) {
    completer.complete(request.result as T);
  }).toJS;
  request.onerror = ((Event _) {
    completer.completeError(StateError('IndexedDB request failed'));
  }).toJS;
  return completer.future;
}

Future<IDBDatabase> _openDb() {
  final request = window.indexedDB.open(_dbName, _dbVersion);
  request.onupgradeneeded = ((IDBVersionChangeEvent event) {
    final db = (event.target as IDBOpenDBRequest).result as IDBDatabase;
    if (!db.objectStoreNames.contains(_storeName)) {
      db.createObjectStore(_storeName);
    }
  }).toJS;
  return _awaitRequest<IDBDatabase>(request);
}

JSArray<JSString> _storeList() => [_storeName.toJS].toJS;

Future<void> putPhotoBlob(String id, Uint8List bytes) async {
  final db = await _openDb();
  final tx = db.transaction(_storeList(), 'readwrite');
  final store = tx.objectStore(_storeName);
  final jsBytes = bytes.toJS;
  await _awaitRequest(store.put(jsBytes, id.toJS));
}

Future<Uint8List?> getPhotoBlob(String id) async {
  final db = await _openDb();
  final tx = db.transaction(_storeList(), 'readonly');
  final store = tx.objectStore(_storeName);
  final result = await _awaitRequest(store.get(id.toJS));
  if (result == null) return null;
  if (result.isA<JSUint8Array>()) {
    return (result as JSUint8Array).toDart;
  }
  if (result.isA<JSArrayBuffer>()) {
    return (result as JSArrayBuffer).toDart.asUint8List();
  }
  return null;
}

Future<void> deletePhotoBlob(String id) async {
  final db = await _openDb();
  final tx = db.transaction(_storeList(), 'readwrite');
  final store = tx.objectStore(_storeName);
  await _awaitRequest(store.delete(id.toJS));
}

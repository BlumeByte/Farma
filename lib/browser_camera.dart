import 'dart:js_interop';
import 'dart:typed_data';

@JS('farmaCapturePhoto')
external JSPromise<JSUint8Array?> _capture();

Future<Uint8List?> captureBrowserPhoto() async =>
    (await _capture().toDart)?.toDart;

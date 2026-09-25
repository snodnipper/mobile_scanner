@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/web_barcode_reader.dart';
import 'package:mobile_scanner/src/mobile_scanner_exception.dart';
import 'package:mobile_scanner/src/web/mobile_scanner_web.dart';
import 'package:web/web.dart' as web;

import 'utils/media_stream_test_utils.dart';

void main() {
  late GetUserMediaStub getUserMedia;
  FailingBarcodeDetectorStub? failingBarcodeDetector;

  setUp(() {
    web.window.localStorage.clear();
    getUserMedia = GetUserMediaStub();
  });

  tearDown(() {
    getUserMedia.restore();
    failingBarcodeDetector?.restore();
    failingBarcodeDetector = null;
  });

  group('MobileScannerWeb teardown during start', () {
    test('dispose() while acquiring the camera releases the stream', () async {
      final plugin =
          MobileScannerWeb()
            ..setWebBarcodeReader(WebBarcodeReader.barcodeDetector);

      final startFuture = plugin.start(testStartOptions);

      await getUserMedia.awaitCall();

      // The scanner is dismissed while getUserMedia is still pending.
      await plugin.dispose();

      final stream = getUserMedia.resolve();

      await expectLater(
        startFuture,
        throwsA(isA<MobileScannerException>()),
        reason: 'a start that was torn down must not report a running camera',
      );

      expect(
        allEnded(stream),
        isTrue,
        reason: 'the camera acquired by the aborted start must be released',
      );
    });

    test('stop() while acquiring the camera releases the stream', () async {
      final plugin =
          MobileScannerWeb()
            ..setWebBarcodeReader(WebBarcodeReader.barcodeDetector);

      final startFuture = plugin.start(testStartOptions);

      await getUserMedia.awaitCall();

      // The scanner is stopped while getUserMedia is still pending.
      await plugin.stop();

      final stream = getUserMedia.resolve();

      await expectLater(
        startFuture,
        throwsA(isA<MobileScannerException>()),
        reason: 'a start that was stopped must not report a running camera',
      );

      expect(
        allEnded(stream),
        isTrue,
        reason: 'the camera acquired by the stopped start must be released',
      );
    });
  });

  group('MobileScannerWeb start failure', () {
    test('a start that fails after acquiring the camera releases it', () async {
      failingBarcodeDetector = FailingBarcodeDetectorStub();

      final plugin =
          MobileScannerWeb()
            ..setWebBarcodeReader(WebBarcodeReader.barcodeDetector);

      final startFuture = plugin.start(testStartOptions);

      await getUserMedia.awaitCall();

      final stream = getUserMedia.resolve();

      await expectLater(
        startFuture,
        throwsA(isA<MobileScannerException>()),
        reason: 'the failing BarcodeDetector must fail the start',
      );

      expect(
        allEnded(stream),
        isTrue,
        reason: 'a failed start must not leave the camera running',
      );
    });
  });
}

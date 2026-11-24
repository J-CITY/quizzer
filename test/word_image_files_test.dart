import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizzer/data/services/word_image_files.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  const png =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/'
      'lP4l9AAAAABJRU5ErkJggg==';
  late Directory documents;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('quizzer-word-images-');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, (
      call,
    ) async {
      expect(call.method, 'getApplicationDocumentsDirectory');
      return documents.path;
    });
  });

  tearDown(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, null);
    await documents.delete(recursive: true);
  });

  test(
    'saves a portable gallery path and resolves a legacy absolute path',
    () async {
      final galleryPhoto = File('${documents.path}/photo.png');
      await galleryPhoto.writeAsBytes(base64Decode(png));

      final reference = await WordImageFiles.saveGalleryImage(galleryPhoto);
      final legacyPath =
          'C:\\older-install\\images\\${reference.split('/').last}';
      final relocated = await WordImageFiles.findLocal(legacyPath);

      expect(reference, startsWith('images/'));
      expect(relocated?.path, '${documents.path}/$reference');
      expect(await relocated?.readAsBytes(), base64Decode(png));
      expect(await WordImageFiles.findLocal('images/missing.png'), isNull);
    },
  );

  test(
    'exports only managed photos and restores a copy under a fresh name',
    () async {
      const reference = 'images/original.png';
      final file = File('${documents.path}/$reference');
      await file.create(recursive: true);
      await file.writeAsBytes(base64Decode(png));
      final sources = [
        reference,
        '/old/install/$reference',
        '/old/install/images/missing.png',
        'https://example.test/images/original.png',
        '../images/original.png',
      ];

      final archive = await WordImageFiles.exportImages(sources);
      expect(archive, {reference: png});

      final restored = await WordImageFiles.importImages(archive, sources);
      final imported = restored[reference]!;
      expect(restored, hasLength(1));
      expect(imported.reference, isNot(reference));
      expect(await imported.file.readAsBytes(), base64Decode(png));
      expect(await file.readAsBytes(), base64Decode(png));
    },
  );

  test(
    'discards staged files when a referenced attachment is malformed',
    () async {
      const first = 'images/first.png';
      const invalid = 'images/invalid.png';
      await expectLater(
        WordImageFiles.importImages(
          {first: png, invalid: '?'},
          [first, invalid],
        ),
        throwsA(isA<WordImageProfileException>()),
      );
      expect(
        await Directory('${documents.path}/images').list().toList(),
        isEmpty,
      );
    },
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

typedef ImportedWordImage = ({String reference, File file});

class WordImageProfileException implements Exception {
  const WordImageProfileException();
}

class WordImageFiles {
  static const maxProfileFileBytes = 128 * 1024 * 1024;
  static const _folder = 'images';
  static const _maxImageBytes = 12 * 1024 * 1024;
  static const _maxProfileImageBytes = 64 * 1024 * 1024;
  static final _fileNamePattern = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]*$');
  static final _extensionPattern = RegExp(r'\.[a-zA-Z0-9]{1,8}$');
  static final _drivePathPattern = RegExp(r'^[a-zA-Z]:[\\/]');

  static bool isRemote(String source) {
    final url = Uri.tryParse(source);
    return url != null &&
        (url.scheme == 'http' || url.scheme == 'https') &&
        url.host.isNotEmpty;
  }

  /// Older gallery photos used an absolute path to the same managed folder.
  static String? managedReference(String? source) {
    if (source == null || isRemote(source)) return null;
    final absolutePath = _localPath(source);
    final path = absolutePath ?? source;
    final segments = path.replaceAll('\\', '/').split('/');
    if (segments.length < 2 ||
        (absolutePath == null && segments.length != 2) ||
        segments[segments.length - 2] != _folder ||
        !_fileNamePattern.hasMatch(segments.last)) {
      return null;
    }
    return '$_folder/${segments.last}';
  }

  static Future<File?> findLocal(String source) async {
    final reference = managedReference(source);
    if (reference != null) {
      final managed = await _managedFile(reference);
      if (await managed.exists()) return managed;
    }
    final path = _localPath(source);
    if (path == null) return null;
    final file = File(path);
    return await file.exists() ? file : null;
  }

  static Future<String> saveGalleryImage(File source) async {
    final image = await _newImage(source.path);
    await source.copy(image.file.path);
    return image.reference;
  }

  static Future<Map<String, String>> exportImages(
    Iterable<String?> sources,
  ) async {
    final images = <String, String>{};
    var totalBytes = 0;
    final references = sources.map(managedReference).nonNulls.toSet();
    for (final reference in references) {
      final file = await _managedFile(reference);
      if (!await file.exists()) continue;
      final size = await file.length();
      totalBytes += size;
      if (size == 0) continue;
      if (size > _maxImageBytes || totalBytes > _maxProfileImageBytes) {
        throw const WordImageProfileException();
      }
      images[reference] = base64Encode(await file.readAsBytes());
    }
    return images;
  }

  static Future<Map<String, ImportedWordImage>> importImages(
    Object? encodedImages,
    Iterable<String?> sources,
  ) async {
    if (encodedImages == null) return {};
    if (encodedImages is! Map<String, dynamic>) {
      throw const WordImageProfileException();
    }
    final images = <String, ImportedWordImage>{};
    var totalBytes = 0;
    final references = sources.map(managedReference).nonNulls.toSet();
    try {
      for (final reference in references) {
        if (!encodedImages.containsKey(reference)) continue;
        final encoded = encodedImages[reference];
        if (encoded is! String ||
            encoded.length > (_maxImageBytes + 2) ~/ 3 * 4) {
          throw const WordImageProfileException();
        }
        final bytes = base64Decode(encoded);
        totalBytes += bytes.length;
        if (bytes.isEmpty ||
            bytes.length > _maxImageBytes ||
            totalBytes > _maxProfileImageBytes) {
          throw const WordImageProfileException();
        }
        final image = await _newImage(reference);
        images[reference] = image;
        await image.file.writeAsBytes(bytes, flush: true);
      }
      return images;
    } catch (error) {
      await removeImportedImages(images.values);
      if (error is FormatException) throw const WordImageProfileException();
      rethrow;
    }
  }

  static Future<void> removeImportedImages(
    Iterable<ImportedWordImage> images,
  ) async {
    for (final image in images) {
      try {
        if (await image.file.exists()) await image.file.delete();
      } on FileSystemException {
        // Keep the original import error when cleanup fails.
      }
    }
  }

  static String? _localPath(String source) {
    if ((source.startsWith('/') && !source.startsWith('//')) ||
        _drivePathPattern.hasMatch(source)) {
      return source;
    }
    final uri = Uri.tryParse(source);
    if (uri == null || uri.scheme != 'file' || uri.host.isNotEmpty) return null;
    try {
      return uri.toFilePath();
    } on UnsupportedError {
      return null;
    }
  }

  static Future<File> _managedFile(String reference) async {
    final documents = await getApplicationDocumentsDirectory();
    return File('${documents.path}/$reference');
  }

  static Future<ImportedWordImage> _newImage(String name) async {
    final extension = _extensionPattern.stringMatch(name) ?? '';
    final reference = '$_folder/${const Uuid().v4()}$extension';
    final file = await _managedFile(reference);
    await file.parent.create(recursive: true);
    return (reference: reference, file: file);
  }
}

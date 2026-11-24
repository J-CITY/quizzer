import 'dart:io';

import 'package:uuid/uuid.dart';

Future<void> writeFileAtomically(File target, String content) async {
  final temporary = File('${target.path}.${const Uuid().v4()}.tmp');
  try {
    await temporary.writeAsString(content, flush: true);
    await temporary.rename(target.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

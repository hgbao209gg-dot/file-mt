import 'dart:io';
import 'package:intl/intl.dart';

class FileItem {
  final String name;
  final String path;
  final bool isDir;
  final int size;
  final DateTime modified;
  final String extension;

  FileItem({
    required this.name,
    required this.path,
    required this.isDir,
    this.size = 0,
    DateTime? modified,
    this.extension = '',
  }) : modified = modified ?? DateTime.now();

  String get sizeFormatted {
    if (isDir) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get dateFormatted => DateFormat('dd/MM/yy HH:mm').format(modified);

  static List<FileItem> fromDirectory(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];
    try {
      final entities = dir.listSync();
      final items = <FileItem>[];
      for (final e in entities) {
        try {
          final stat = e.statSync();
          final name = e.path.split('/').last;
          if (name.startsWith('.')) continue; // skip hidden
          items.add(FileItem(
            name: name,
            path: e.path,
            isDir: stat.type == FileSystemEntityType.directory,
            size: stat.size,
            modified: stat.modified,
            extension: e.path.contains('.')
                ? e.path.split('.').last.toLowerCase()
                : '',
          ));
        } catch (_) {}
      }
      items.sort((a, b) {
        if (a.isDir && !b.isDir) return -1;
        if (!a.isDir && b.isDir) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return items;
    } catch (_) {
      return [];
    }
  }
}

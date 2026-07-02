import 'package:flutter/material.dart';
import '../models/file_item.dart';

Icon fileIcon(FileItem item) {
  if (item.isDir) {
    return const Icon(Icons.folder, color: Colors.amber);
  }
  const map = {
    'dart': Icons.code, 'kt': Icons.code, 'java': Icons.code, 'py': Icons.code,
    'js': Icons.javascript, 'ts': Icons.code, 'xml': Icons.code, 'html': Icons.html,
    'css': Icons.css, 'json': Icons.data_object, 'yaml': Icons.settings, 'yml': Icons.settings,
    'md': Icons.article, 'txt': Icons.text_snippet, 'pdf': Icons.picture_as_pdf,
    'zip': Icons.folder_zip, 'rar': Icons.folder_zip, 'tar': Icons.folder_zip,
    'gz': Icons.folder_zip, '7z': Icons.folder_zip, 'mp4': Icons.movie, 'mkv': Icons.movie,
    'avi': Icons.movie, 'mp3': Icons.audiotrack, 'wav': Icons.audiotrack, 'flac': Icons.audiotrack,
    'jpg': Icons.image, 'jpeg': Icons.image, 'png': Icons.image, 'gif': Icons.gif,
    'webp': Icons.image, 'apk': Icons.android, 'exe': Icons.settings_applications,
    'sh': Icons.terminal, 'bat': Icons.terminal,
  };
  return Icon(map[item.extension] ?? Icons.insert_drive_file, color: Colors.blueGrey);
}
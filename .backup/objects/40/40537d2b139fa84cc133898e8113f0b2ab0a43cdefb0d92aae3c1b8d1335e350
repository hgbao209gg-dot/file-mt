import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class FileService {
  static const _channel = MethodChannel('com.example.apptest/file');

  static Future<Map<String, String>> getExternalPaths() async {
    final map = await _channel.invokeMethod<Map<dynamic, dynamic>>('externalStorage');
    return map?.cast<String, String>() ?? {'emulated': '/storage/emulated/0'};
  }

  static Future<List<Map<String, dynamic>>> listDir(String path) async {
    final list = await _channel.invokeMethod<List<dynamic>>('listDir', {'path': path});
    return list?.cast<Map<String, dynamic>>() ?? [];
  }

  static Future<Map<String, dynamic>> fileInfo(String path) async {
    return await _channel.invokeMethod<Map<String, dynamic>>('fileInfo', {'path': path}) ?? {};
  }

  static Future<Map<String, dynamic>> copy(String src, String dst) async {
    return await _channel.invokeMethod<Map<String, dynamic>>('copy', {'src': src, 'dst': dst}) ?? {};
  }

  static Future<Map<String, dynamic>> move(String src, String dst) async {
    return await _channel.invokeMethod<Map<String, dynamic>>('move', {'src': src, 'dst': dst}) ?? {};
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    return await _channel.invokeMethod<Map<String, dynamic>>('delete', {'path': path}) ?? {};
  }

  static Future<Map<String, dynamic>> mkdir(String path) async {
    return await _channel.invokeMethod<Map<String, dynamic>>('mkdir', {'path': path}) ?? {};
  }

  static Future<Map<String, dynamic>> storageInfo(String path) async {
    return await _channel.invokeMethod<Map<String, dynamic>>('storageInfo', {'path': path}) ?? {};
  }
}
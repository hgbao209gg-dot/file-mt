package com.example.apptest

import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*

class FileChannelHandler(private val engine: FlutterEngine) {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.example.apptest/file")

    private val dateFormat = SimpleDateFormat("dd/MM/yy HH:mm", Locale.getDefault())

    fun register() {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "listDir" -> {
                    val path = call.argument<String>("path") ?: "/"
                    result.success(listDir(path))
                }
                "fileInfo" -> {
                    val path = call.argument<String>("path") ?: ""
                    result.success(fileInfo(path))
                }
                "copy" -> {
                    val src = call.argument<String>("src") ?: ""
                    val dst = call.argument<String>("dst") ?: ""
                    result.success(copyFile(src, dst))
                }
                "move" -> {
                    val src = call.argument<String>("src") ?: ""
                    val dst = call.argument<String>("dst") ?: ""
                    result.success(moveFile(src, dst))
                }
                "delete" -> {
                    val path = call.argument<String>("path") ?: ""
                    result.success(deleteFile(path))
                }
                "mkdir" -> {
                    val path = call.argument<String>("path") ?: ""
                    result.success(mkdir(path))
                }
                "externalStorage" -> {
                    val dirs = mapOf(
                        "root" to "/",
                        "storage" to "/storage",
                        "emulated" to "/storage/emulated/0",
                        "download" to Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).absolutePath,
                        "documents" to Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS).absolutePath,
                        "pictures" to Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES).absolutePath,
                        "music" to Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC).absolutePath,
                        "movies" to Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES).absolutePath
                    )
                    result.success(dirs)
                }
                "storageInfo" -> {
                    val path = call.argument<String>("path") ?: "/"
                    result.success(storageInfo(path))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun listDir(path: String): List<Map<String, Any?>> {
        val dir = File(path)
        if (!dir.exists() || !dir.isDirectory) return emptyList()
        val items = mutableListOf<Map<String, Any?>>()
        dir.listFiles()?.sortedWith(compareBy<File> { !it.isDirectory }.thenBy { it.name.lowercase() })?.forEach { f ->
            items.add(fileInfo(f.absolutePath))
        }
        return items
    }

    private fun fileInfo(path: String): Map<String, Any?> {
        val f = File(path)
        if (!f.exists()) return emptyMap()
        return mapOf(
            "name" to f.name,
            "path" to f.absolutePath,
            "isDir" to f.isDirectory,
            "size" to f.length(),
            "modified" to dateFormat.format(Date(f.lastModified())),
            "extension" to (if (f.name.contains(".")) f.name.substringAfterLast(".").lowercase() else "")
        )
    }

    private fun copyFile(src: String, dst: String): Map<String, Any?> {
        return try {
            val srcFile = File(src)
            val dstFile = File(dst)
            if (srcFile.isDirectory) {
                srcFile.copyRecursively(dstFile, overwrite = true)
            } else {
                srcFile.copyTo(dstFile, overwrite = true)
            }
            mapOf("success" to true, "message" to "Copied to $dst")
        } catch (e: Exception) {
            mapOf("success" to false, "message" to e.message ?: "Unknown error")
        }
    }

    private fun moveFile(src: String, dst: String): Map<String, Any?> {
        return try {
            val srcFile = File(src)
            val dstFile = File(dst)
            if (srcFile.isDirectory) {
                srcFile.copyRecursively(dstFile, overwrite = true)
                srcFile.deleteRecursively()
            } else {
                srcFile.copyTo(dstFile, overwrite = true)
                srcFile.delete()
            }
            mapOf("success" to true, "message" to "Moved to $dst")
        } catch (e: Exception) {
            mapOf("success" to false, "message" to e.message ?: "Unknown error")
        }
    }

    private fun deleteFile(path: String): Map<String, Any?> {
        return try {
            val f = File(path)
            if (f.isDirectory) f.deleteRecursively() else f.delete()
            mapOf("success" to true, "message" to "Deleted")
        } catch (e: Exception) {
            mapOf("success" to false, "message" to e.message ?: "Unknown error")
        }
    }

    private fun mkdir(path: String): Map<String, Any?> {
        return try {
            File(path).mkdirs()
            mapOf("success" to true, "message" to "Created")
        } catch (e: Exception) {
            mapOf("success" to false, "message" to e.message ?: "Unknown error")
        }
    }

    private fun storageInfo(path: String): Map<String, Any> {
        try {
            val stat = StatFs(path)
            val blockSize = stat.blockSizeLong
            val totalBlocks = stat.blockCountLong
            val availableBlocks = stat.availableBlocksLong
            val total = totalBlocks * blockSize
            val free = availableBlocks * blockSize
            val used = total - free
            return mapOf(
                "total" to total,
                "free" to free,
                "used" to used
            )
        } catch (_: Exception) {
            return mapOf(
                "total" to 0,
                "free" to 0,
                "used" to 0
            )
        }
    }
}
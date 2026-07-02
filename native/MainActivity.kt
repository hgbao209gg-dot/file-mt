package com.example.apptest

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.net.URL

class MainActivity : FlutterActivity() {
    private val CHANNEL = "apptest/server"
    private var serverProcess: Process? = null
    private var javaBin: File? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installJre" -> {
                    var msg = ""
                    try {
                        msg = installJre()
                        result.success(msg)
                    } catch (e: Exception) {
                        result.error("INSTALL_FAILED", e.message, null)
                    }
                }
                "startServer" -> {
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    try {
                        startServer(args)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_FAILED", e.message, null)
                    }
                }
                "stopServer" -> {
                    stopServer()
                    result.success(true)
                }
                "getLog" -> {
                    result.success(getLog())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun serverDir(): File = File(filesDir, "minecraft").also { it.mkdirs() }

    // ── 1. Download & extract JRE from Termux repo ──────────────────────
    private fun installJre(): String {
        val jreDir = File(filesDir, "jre")
        if (File(jreDir, "bin/java").exists()) {
            javaBin = File(jreDir, "bin/java")
            return "JRE already installed"
        }

        // Use Termux openjdk-17-jre-headless deb for aarch64
        val debUrl = "https://packages.termux.dev/apt/termux-main/pool/main/o/openjdk-17/openjdk-17-jre-headless_17.0.13_aarch64.deb"
        val debFile = File(filesDir, "openjdk.deb")
        Log.i("MainActivity", "Downloading JRE from Termux repo (~50MB)…")
        downloadFile(debUrl, debFile)

        // Step 1: extract data.tar.xz from .deb (ar archive)
        val dataTar = File(filesDir, "data.tar.xz")
        extractArFile(debFile, "data.tar.xz", dataTar)

        // Step 2: extract tarball into temp dir
        val tmp = File(filesDir, "termux-jre").also { deleteRecursively(it); it.mkdirs() }
        exec("tar", "-xJf", dataTar.absolutePath, "-C", tmp.absolutePath)

        // Step 3: find java binary anywhere under tmp
        val found = tmp.walkTopDown().filter { it.name == "java" && it.isFile }.firstOrNull()
            ?: throw RuntimeException("java binary not found in Termux package")

        // Step 4: copy jre dir to jreDir (everything from the parent of bin/)
        val jvmRoot = found.parentFile?.parentFile  // …/bin/java → …/bin/ → …/
            ?: throw RuntimeException("cannot resolve jre root")
        jvmRoot.copyRecursively(jreDir, overwrite = true)

        // Cleanup
        debFile.delete()
        dataTar.delete()
        deleteRecursively(tmp)

        // Make java executable
        javaBin = File(jreDir, "bin/java").also { it.setExecutable(true) }
        Log.i("MainActivity", "JRE installed at ${jreDir.absolutePath}")
        return "JRE installed (${jreDir.absolutePath})"
    }

    // ── 2. Minimal ar extractor (reads filename & data from .deb) ──────
    private fun extractArFile(arFile: File, wantedName: String, out: File) {
        val bytes = arFile.readBytes()
        var pos = 0

        // ar magic
        val magic = String(bytes, 0, 8)
        if (magic != "!<arch>\n") throw RuntimeException("Not a valid ar archive")
        pos = 8

        while (pos + 60 <= bytes.size) {
            val name = String(bytes, pos, 16).trimEnd(' ', '/')
            val sizeStr = String(bytes, pos + 48, 10).trim()
            val size = sizeStr.toIntOrNull() ?: break
            val headerEnd = pos + 60
            pos = headerEnd

            if (name == wantedName) {
                FileOutputStream(out).use { fos -> fos.write(bytes, pos, size) }
                return
            }

            pos += size
            if (pos % 2 != 0) pos++ // ar pads to even boundary
        }
        throw RuntimeException("File '$wantedName' not found in ar archive")
    }

    // ── 3. HTTP download ────────────────────────────────────────────────
    private fun downloadFile(urlStr: String, dest: File) {
        URL(urlStr).openConnection().let { conn ->
            conn.setRequestProperty("User-Agent", "Mozilla/5.0")
            conn.connect()
            val inputStream = conn.getInputStream()
            dest.outputStream().use { output ->
                inputStream.copyTo(output)
            }
        }
    }

    // ── 4. exec helper ──────────────────────────────────────────────────
    private fun exec(vararg cmd: String): String {
        val pb = ProcessBuilder(*cmd)
            .redirectErrorStream(true)
        val proc = pb.start()
        val output = proc.inputStream.bufferedReader().readText()
        val exit = proc.waitFor()
        if (exit != 0) throw RuntimeException("${cmd.joinToString(" ")} failed:\n$output")
        return output
    }

    private fun deleteRecursively(f: File) {
        if (f.isDirectory) f.listFiles()?.forEach { deleteRecursively(it) }
        f.delete()
    }

    // ── 5. Server control ───────────────────────────────────────────────
    private fun startServer(args: List<String>) {
        val java = javaBin ?: throw IllegalStateException("JRE not installed. Call installJre first.")
        val serverJar = File(serverDir(), "server.jar")
        if (!serverJar.exists()) throw RuntimeException("server.jar not found in minecraft/")

        val cmd = mutableListOf(
            java.absolutePath,
            "-Xms1G", "-Xmx2G",
            "-jar", serverJar.absolutePath,
            "nogui"
        )
        cmd.addAll(args)
        serverProcess = ProcessBuilder(cmd)
            .directory(serverDir())
            .redirectErrorStream(true)
            .start()
    }

    private fun stopServer() {
        serverProcess?.destroyForcibly()
        serverProcess = null
    }

    private fun getLog(): String {
        val proc = serverProcess ?: return ""
        return try {
            val r = BufferedReader(InputStreamReader(proc.inputStream))
            val lines = mutableListOf<String>()
            while (r.ready()) r.readLine()?.let { lines.add(it) }
            lines.takeLast(50).joinToString("\n")
        } catch (e: Exception) { "Error: ${e.message}" }
    }

    override fun onDestroy() { stopServer(); super.onDestroy() }
}
package com.fortress.studio.app

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel
    private val executor: ExecutorService = Executors.newFixedThreadPool(4)

    companion object {
        const val CHANNEL = "fortress.studio.app/bridge"
        const val VAULT_PATH = "/mnt/sdcard/opencode/build-vault"
        const val VAULT_PATH_ALT = "/sdcard/opencode/build-vault"
        const val TERMUX_PACKAGE = "com.termux"
        const val TERMUX_RUN_ACTION = "com.termux.RUN_COMMAND"
        const val TERMUX_SERVICE = "com.termux.app.RunCommandService"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkTermux" -> result.success(checkTermuxAvailable())
                "checkStoragePermission" -> result.success(mapOf("success" to checkStoragePermission()))
                "requestStoragePermission" -> result.success(mapOf("success" to requestStoragePermission()))
                "getVaultPath" -> result.success(mapOf("value" to getVaultPath()))
                "listVault" -> {
                    val path = call.argument<String>("path") ?: VAULT_PATH
                    runAsync(result) { listDirectory(path) }
                }
                "readFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    runAsync(result) { readFile(path) }
                }
                "writeFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    val content = call.argument<String>("content") ?: ""
                    runAsync(result) { writeFile(path, content) }
                }
                "atomicWrite" -> {
                    val path = call.argument<String>("path") ?: ""
                    val content = call.argument<String>("content") ?: ""
                    runAsync(result) { atomicWrite(path, content) }
                }
                "rollbackFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    runAsync(result) { rollbackFile(path) }
                }
                "diffFiles" -> {
                    val path1 = call.argument<String>("path1") ?: ""
                    val path2 = call.argument<String>("path2") ?: ""
                    runAsync(result) { diffFiles(path1, path2) }
                }
                "runTermuxCommand" -> {
                    val command = call.argument<String>("command") ?: ""
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 30
                    runAsync(result, "TERMUX_ERROR") { runTermuxCommand(command, args, timeoutSec) }
                }
                "runAlpineCommand" -> {
                    val command = call.argument<String>("command") ?: ""
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 30
                    runAsync(result, "ALPINE_ERROR") { runAlpineCommand(command, args, timeoutSec) }
                }
                "runOpenCode" -> {
                    val command = call.argument<String>("command") ?: ""
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 60
                    runAsync(result, "OPENCODE_ERROR") { runOpenCode(command, args, timeoutSec) }
                }
                "runKashkoolSavior" -> {
                    val role = call.argument<String>("role") ?: "Plan"
                    val model = call.argument<String>("model") ?: "nemotron"
                    val prompt = call.argument<String>("prompt") ?: ""
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 120
                    runAsync(result, "SAVIOR_ERROR") { runKashkoolSavior(role, model, prompt, timeoutSec) }
                }
                "runGitHubSync" -> {
                    val repo = call.argument<String>("repo") ?: ""
                    val action = call.argument<String>("action") ?: "status"
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 60
                    runAsync(result, "GITHUB_ERROR") { runGitHubSync(repo, action, timeoutSec) }
                }
                "runFortressGuard" -> {
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 60
                    runAsync(result, "GUARD_ERROR") { runFortressGuard(timeoutSec) }
                }
                "runTrinity" -> {
                    val command = call.argument<String>("command") ?: ""
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 60
                    runAsync(result, "TRINITY_ERROR") { runTrinity(command, args, timeoutSec) }
                }
                "checkFortressGuard" -> result.success(checkFortressGuard())
                "readWorkshopProfile" -> result.success(readWorkshopProfile())
                else -> result.notImplemented()
            }
        }
    }

    private fun runAsync(
        result: MethodChannel.Result,
        errorCode: String = "BRIDGE_ERROR",
        block: () -> Map<String, Any>
    ) {
        executor.submit {
            try {
                val output = block()
                runOnUiThread { result.success(output) }
            } catch (e: Exception) {
                runOnUiThread { result.error(errorCode, e.message ?: "Unknown error", null) }
            }
        }
    }

    private fun checkTermuxAvailable(): Map<String, Any> {
        val installed = isPackageInstalled(TERMUX_PACKAGE)
        val allowExternalApps = checkTermuxConfig()
        return mapOf(
            "installed" to installed,
            "allowExternalApps" to allowExternalApps,
            "package" to TERMUX_PACKAGE
        )
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun checkTermuxConfig(): Boolean {
        return try {
            val configFile = File("/data/data/com.termux/files/home/.termux/termux.properties")
            if (!configFile.exists()) return false
            configFile.readText().contains("allow-external-apps=true")
        } catch (_: Exception) {
            false
        }
    }

    private fun checkStoragePermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return Environment.isExternalStorageManager()
        }
        return ContextCompat.checkSelfPermission(
            this,
            android.Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestStoragePermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()) {
                return try {
                    val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                        .setData(Uri.parse("package:$packageName"))
                    startActivityForResult(intent, 1001)
                    true
                } catch (_: Exception) {
                    false
                }
            }
            return true
        }
        ActivityCompat.requestPermissions(
            this,
            arrayOf(android.Manifest.permission.WRITE_EXTERNAL_STORAGE),
            1002
        )
        return true
    }

    private fun getVaultPath(): String {
        return if (File(VAULT_PATH).exists()) VAULT_PATH else VAULT_PATH_ALT
    }

    private fun listDirectory(path: String): Map<String, Any> {
        return try {
            val file = File(path)
            if (!file.exists()) {
                return mapOf("exists" to false, "error" to "Path not found: $path")
            }
            if (!file.isDirectory) {
                return mapOf("exists" to false, "error" to "Not a directory: $path")
            }
            val files = file.listFiles() ?: emptyArray()
            val items = files.map { f ->
                mapOf<String, Any>(
                    "name" to f.name,
                    "path" to f.absolutePath,
                    "isDirectory" to f.isDirectory,
                    "size" to f.length(),
                    "lastModified" to f.lastModified()
                )
            }.sortedWith(
                compareByDescending<Map<String, Any>> { it["isDirectory"] as? Boolean ?: false }
                    .thenBy { (it["name"] as? String ?: "").lowercase() }
            )
            mapOf("exists" to true, "path" to path, "items" to items)
        } catch (e: Exception) {
            mapOf("exists" to false, "error" to (e.message ?: "Failed to list directory"))
        }
    }

    private fun readFile(path: String): Map<String, Any> {
        return try {
            val file = File(path)
            if (!file.exists()) {
                return mapOf("exists" to false, "error" to "File not found: $path")
            }
            if (!file.isFile) {
                return mapOf("exists" to false, "error" to "Not a file: $path")
            }
            val content = file.readText()
            mapOf("exists" to true, "path" to path, "content" to content, "size" to file.length())
        } catch (e: Exception) {
            mapOf("exists" to false, "error" to (e.message ?: "Failed to read file"))
        }
    }

    private fun writeFile(path: String, content: String): Map<String, Any> {
        return try {
            val file = File(path)
            file.parentFile?.mkdirs()
            file.writeText(content)
            mapOf("success" to true, "path" to path, "size" to content.length.toLong())
        } catch (e: Exception) {
            mapOf("success" to false, "path" to path, "error" to (e.message ?: "Unknown error"))
        }
    }

    private fun atomicWrite(path: String, content: String): Map<String, Any> {
        return try {
            val file = File(path)
            val parent = file.parentFile
            parent?.mkdirs()
            val bakFile = File("$path.bak")
            if (file.exists()) {
                file.copyTo(bakFile, overwrite = true)
            }
            val tmpFile = File(parent, "${file.name}.tmp.${System.currentTimeMillis()}")
            tmpFile.writeText(content)
            if (!tmpFile.renameTo(file)) {
                tmpFile.copyTo(file, overwrite = true)
                tmpFile.delete()
            }
            mapOf(
                "success" to true,
                "path" to path,
                "size" to content.length.toLong(),
                "bak" to bakFile.exists()
            )
        } catch (e: Exception) {
            mapOf("success" to false, "path" to path, "error" to (e.message ?: "Unknown error"))
        }
    }

    private fun rollbackFile(path: String): Map<String, Any> {
        return try {
            val file = File(path)
            val bakFile = File("$path.bak")
            if (!bakFile.exists()) {
                return mapOf("success" to false, "path" to path, "error" to "No .bak file found")
            }
            bakFile.copyTo(file, overwrite = true)
            mapOf("success" to true, "path" to path, "message" to "Rolled back from .bak")
        } catch (e: Exception) {
            mapOf("success" to false, "path" to path, "error" to (e.message ?: "Unknown error"))
        }
    }

    private fun diffFiles(path1: String, path2: String): Map<String, Any> {
        return try {
            val f1 = File(path1)
            val f2 = File(path2)
            if (!f1.exists()) return mapOf("success" to false, "error" to "File not found: $path1")
            if (!f2.exists()) return mapOf("success" to false, "error" to "File not found: $path2")
            val content1 = f1.readText().lines()
            val content2 = f2.readText().lines()
            val maxLen = maxOf(content1.size, content2.size)
            val diff = mutableListOf<String>()
            for (i in 0 until maxLen) {
                val line1 = if (i < content1.size) content1[i] else ""
                val line2 = if (i < content2.size) content2[i] else ""
                if (line1 != line2) {
                    diff.add("Line ${i + 1}:")
                    diff.add("  < $line1")
                    diff.add("  > $line2")
                }
            }
            mapOf(
                "success" to true,
                "output" to if (diff.isEmpty()) "No differences found" else diff.joinToString("\n")
            )
        } catch (e: Exception) {
            mapOf("success" to false, "error" to (e.message ?: "Unknown error"))
        }
    }

    private fun dispatchTermuxRunCommand(commandPath: String, args: List<String>, background: Boolean = true): Map<String, Any> {
        return try {
            val intent = Intent(TERMUX_RUN_ACTION).apply {
                setClassName(TERMUX_PACKAGE, TERMUX_SERVICE)
                putExtra("com.termux.RUN_COMMAND_PATH", commandPath)
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", args.toTypedArray())
                putExtra("com.termux.RUN_COMMAND_WORKDIR", getVaultPath())
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", background)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            mapOf(
                "success" to true,
                "exitCode" to 0,
                "output" to "Dispatched to Termux RUN_COMMAND: $commandPath ${args.joinToString(" ")}",
                "command" to commandPath
            )
        } catch (e: SecurityException) {
            mapOf(
                "success" to false,
                "exitCode" to -1,
                "error" to "SecurityException: Termux RUN_COMMAND blocked. Enable allow-external-apps=true in ~/.termux/termux.properties and run termux-reload-settings.",
                "command" to commandPath
            )
        } catch (e: Exception) {
            mapOf(
                "success" to false,
                "exitCode" to -1,
                "error" to (e.message ?: "Failed to dispatch Termux RUN_COMMAND"),
                "command" to commandPath
            )
        }
    }

    private fun runTermuxCommand(command: String, args: List<String>, timeoutSec: Int): Map<String, Any> {
        val localResult = runProcess(command, args, timeoutSec, TERMUX_PACKAGE)
        if (localResult["success"] == true) {
            return localResult
        }
        if (isPackageInstalled(TERMUX_PACKAGE)) {
            val resolvedPath = if (command.startsWith("/")) {
                command
            } else {
                "/data/data/com.termux/files/usr/bin/$command"
            }
            return dispatchTermuxRunCommand(resolvedPath, args, true)
        }
        return localResult
    }

    private fun runAlpineCommand(command: String, args: List<String>, timeoutSec: Int): Map<String, Any> {
        val fullCmd = if (args.isEmpty()) command else "$command ${args.joinToString(" ")}"
        return runProcess("sh", listOf("-c", fullCmd), timeoutSec, "alpine")
    }

    private fun runOpenCode(command: String, args: List<String>, timeoutSec: Int): Map<String, Any> {
        val fullArgs = mutableListOf("web", "--port", "8888", "--hostname", "0.0.0.0")
        fullArgs.addAll(args)
        return runTermuxCommand(if (command.isBlank()) "opencode" else command, fullArgs, timeoutSec)
    }

    private fun runKashkoolSavior(role: String, model: String, prompt: String, timeoutSec: Int): Map<String, Any> {
        return try {
            val vaultPath = getVaultPath()
            val saviorScript = "$vaultPath/tools/kashkool_studio.py"
            if (!File(saviorScript).exists()) {
                return mapOf("success" to false, "error" to "kashkool_studio.py not found at $saviorScript")
            }
            val args = listOf(saviorScript, "--role", role, "--model", model, "--prompt", prompt)
            runProcess("python3", args, timeoutSec, "kashkool-savior")
        } catch (e: Exception) {
            mapOf("success" to false, "error" to (e.message ?: "Unknown error"))
        }
    }

    private fun runGitHubSync(repo: String, action: String, timeoutSec: Int): Map<String, Any> {
        return try {
            val karkhanaPath = "/mnt/sdcard/opencode/karkhana"
            val karkhanaDir = File(karkhanaPath)
            if (!karkhanaDir.exists()) {
                return mapOf("success" to false, "error" to "Karkhana directory not found at $karkhanaPath")
            }
            val args = when (action) {
                "pull" -> listOf("-C", karkhanaPath, "pull")
                else -> listOf("-C", karkhanaPath, "status")
            }
            runProcess("git", args, timeoutSec, "github-sync:$repo")
        } catch (e: Exception) {
            mapOf("success" to false, "error" to (e.message ?: "Unknown error"))
        }
    }

    private fun runFortressGuard(timeoutSec: Int): Map<String, Any> {
        return try {
            val vaultPath = getVaultPath()
            val guardPath = "$vaultPath/tools/fortress_guard.py"
            if (!File(guardPath).exists()) {
                return mapOf("success" to false, "error" to "fortress_guard.py not found at $guardPath")
            }
            runProcess("python3", listOf(guardPath), timeoutSec, "fortress-guard")
        } catch (e: Exception) {
            mapOf("success" to false, "error" to (e.message ?: "Unknown error"))
        }
    }

    private fun runTrinity(command: String, args: List<String>, timeoutSec: Int): Map<String, Any> {
        return try {
            val vaultPath = getVaultPath()
            val trinityPath = "$vaultPath/tools/trinity.py"
            if (!File(trinityPath).exists()) {
                return mapOf("success" to false, "error" to "trinity.py not found at $trinityPath")
            }
            val fullArgs = mutableListOf(trinityPath, command)
            fullArgs.addAll(args)
            runProcess("python3", fullArgs, timeoutSec, "trinity")
        } catch (e: Exception) {
            mapOf("success" to false, "error" to (e.message ?: "Unknown error"))
        }
    }

    private fun runProcess(command: String, args: List<String>, timeoutSec: Int, context: String): Map<String, Any> {
        return try {
            val cmdLine = mutableListOf(command).apply { addAll(args) }
            val process = ProcessBuilder(cmdLine)
                .redirectErrorStream(true)
                .start()
            val output = readProcessOutput(process, timeoutSec)
            val finished = process.waitFor(timeoutSec.toLong(), TimeUnit.SECONDS)
            if (!finished) {
                process.destroyForcibly()
                return mapOf(
                    "success" to false,
                    "exitCode" to -1,
                    "output" to output,
                    "error" to "Command timed out after ${timeoutSec}s",
                    "command" to cmdLine.joinToString(" ")
                )
            }
            val exitCode = process.exitValue()
            mapOf(
                "success" to (exitCode == 0),
                "exitCode" to exitCode,
                "output" to output,
                "command" to cmdLine.joinToString(" ")
            )
        } catch (e: Exception) {
            mapOf(
                "success" to false,
                "context" to context,
                "error" to (e.message ?: "Unknown error"),
                "command" to command
            )
        }
    }

    private fun readProcessOutput(process: Process, timeoutSec: Int): String {
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val lines = mutableListOf<String>()
        val startTime = System.currentTimeMillis()
        val timeoutMs = timeoutSec.toLong() * 1000L
        var line: String?
        while (reader.readLine().also { line = it } != null) {
            lines.add(line ?: "")
            if (System.currentTimeMillis() - startTime > timeoutMs) {
                process.destroyForcibly()
                lines.add("Command timed out after ${timeoutSec}s")
                break
            }
        }
        reader.close()
        return lines.joinToString("\n")
    }

    private fun checkFortressGuard(): Map<String, Any> {
        val vaultPath = getVaultPath()
        val guardPath = "$vaultPath/tools/fortress_guard.py"
        val trinityPath = "$vaultPath/tools/trinity.py"
        val statePath = "$vaultPath/state/system_state.json"
        return mapOf(
            "vaultPath" to vaultPath,
            "fortressGuardExists" to File(guardPath).exists(),
            "trinityExists" to File(trinityPath).exists(),
            "stateExists" to File(statePath).exists(),
            "guardPath" to guardPath,
            "trinityPath" to trinityPath,
            "statePath" to statePath
        )
    }

    private fun readWorkshopProfile(): Map<String, Any> {
        val vaultPath = getVaultPath()
        val profilePath = "$vaultPath/workshop_profile.json"
        return try {
            val file = File(profilePath)
            if (!file.exists()) {
                mapOf("exists" to false, "path" to profilePath, "error" to "Workshop profile not found: $profilePath")
            } else {
                mapOf(
                    "exists" to true,
                    "path" to profilePath,
                    "content" to file.readText(),
                    "size" to file.length()
                )
            }
        } catch (e: Exception) {
            mapOf("exists" to false, "path" to profilePath, "error" to (e.message ?: "Failed to read workshop profile"))
        }
    }

    override fun onDestroy() {
        executor.shutdown()
        try {
            if (!executor.awaitTermination(5, TimeUnit.SECONDS)) {
                executor.shutdownNow()
            }
        } catch (_: InterruptedException) {
            executor.shutdownNow()
            Thread.currentThread().interrupt()
        }
        super.onDestroy()
    }
}

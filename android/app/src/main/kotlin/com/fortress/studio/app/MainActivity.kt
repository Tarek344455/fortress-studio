package com.fortress.studio.app

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
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
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkTermux" -> result.success(checkTermuxAvailable())
                "checkStoragePermission" -> result.success(checkStoragePermission())
                "requestStoragePermission" -> result.success(requestStoragePermission())
                "getVaultPath" -> result.success(getVaultPath())
                "listVault" -> result.success(listDirectory(call.argument<String>("path") ?: VAULT_PATH))
                "readFile" -> result.success(readFile(call.argument<String>("path") ?: ""))
                "writeFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    val content = call.argument<String>("content") ?: ""
                    result.success(writeFile(path, content))
                }
                "atomicWrite" -> {
                    val path = call.argument<String>("path") ?: ""
                    val content = call.argument<String>("content") ?: ""
                    result.success(atomicWrite(path, content))
                }
                "rollbackFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    result.success(rollbackFile(path))
                }
                "diffFiles" -> {
                    val path1 = call.argument<String>("path1") ?: ""
                    val path2 = call.argument<String>("path2") ?: ""
                    result.success(diffFiles(path1, path2))
                }
                "runTermuxCommand" -> {
                    val command = call.argument<String>("command") ?: ""
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 30
                    executor.submit {
                        try {
                            val output = runTermuxCommand(command, args, timeoutSec)
                            result.success(output)
                        } catch (e: Exception) {
                            result.error("TERMUX_ERROR", e.message, null)
                        }
                    }
                }
                "runAlpineCommand" -> {
                    val command = call.argument<String>("command") ?: ""
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 30
                    executor.submit {
                        try {
                            val output = runAlpineCommand(command, args, timeoutSec)
                            result.success(output)
                        } catch (e: Exception) {
                            result.error("ALPINE_ERROR", e.message, null)
                        }
                    }
                }
                "runOpenCode" -> {
                    val command = call.argument<String>("command") ?: ""
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 60
                    executor.submit {
                        try {
                            val output = runOpenCode(command, args, timeoutSec)
                            result.success(output)
                        } catch (e: Exception) {
                            result.error("OPENCODE_ERROR", e.message, null)
                        }
                    }
                }
                "runKashkoolSavior" -> {
                    val role = call.argument<String>("role") ?: "Plan"
                    val model = call.argument<String>("model") ?: "nemotron"
                    val prompt = call.argument<String>("prompt") ?: ""
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 120
                    executor.submit {
                        try {
                            val output = runKashkoolSavior(role, model, prompt, timeoutSec)
                            result.success(output)
                        } catch (e: Exception) {
                            result.error("SAVIOR_ERROR", e.message, null)
                        }
                    }
                }
                "runGitHubSync" -> {
                    val repo = call.argument<String>("repo") ?: ""
                    val action = call.argument<String>("action") ?: "status"
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 60
                    executor.submit {
                        try {
                            val output = runGitHubSync(repo, action, timeoutSec)
                            result.success(output)
                        } catch (e: Exception) {
                            result.error("GITHUB_ERROR", e.message, null)
                        }
                    }
                }
                "runFortressGuard" -> {
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 60
                    executor.submit {
                        try {
                            val output = runFortressGuard(timeoutSec)
                            result.success(output)
                        } catch (e: Exception) {
                            result.error("GUARD_ERROR", e.message, null)
                        }
                    }
                }
                "runTrinity" -> {
                    val command = call.argument<String>("command") ?: ""
                    val args = call.argument<List<String>>("args") ?: emptyList()
                    val timeoutSec = call.argument<Int>("timeoutSec") ?: 60
                    executor.submit {
                        try {
                            val output = runTrinity(command, args, timeoutSec)
                            result.success(output)
                        } catch (e: Exception) {
                            result.error("TRINITY_ERROR", e.message, null)
                        }
                    }
                }
                "checkFortressGuard" -> result.success(checkFortressGuard())
                else -> result.notImplemented()
            }
        }
    }

    private fun checkTermuxAvailable(): Map<String, Any> {
        val termuxPackage = "com.termux"
        val installed = isPackageInstalled(termuxPackage)
        val allowExternalApps = checkTermuxConfig()
        return mapOf(
            "installed" to installed,
            "allowExternalApps" to allowExternalApps,
            "package" to termuxPackage
        )
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun checkTermuxConfig(): Boolean {
        val configFile = File("/data/data/com.termux/files/home/.termux/termux.properties")
        if (!configFile.exists()) return false
        val content = configFile.readText()
        return content.contains("allow-external-apps=true")
    }

    private fun checkStoragePermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return Environment.isExternalStorageManager()
        }
        return ContextCompat.checkSelfPermission(this, android.Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestStoragePermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()) {
                try {
                    val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).setData(Uri.parse("package:${packageName}"))
                    startActivityForResult(intent, 1001)
                    return true
                } catch (e: Exception) {
                    return false
                }
            }
            return true
        }
        ActivityCompat.requestPermissions(this, arrayOf(android.Manifest.permission.WRITE_EXTERNAL_STORAGE), 1002)
        return true
    }

    private fun getVaultPath(): String {
        return if (File(VAULT_PATH).exists()) VAULT_PATH else VAULT_PATH_ALT
    }

    private fun listDirectory(path: String): Map<String, Any> {
        val file = File(path)
        if (!file.exists()) {
            return mapOf(
                "exists" to false,
                "error" to ("Path not found: $path")
            )
        }
        if (!file.isDirectory) {
            return mapOf(
                "exists" to false,
                "error" to ("Not a directory: $path")
            )
        }
        val files = file.listFiles() ?: emptyArray()
        val items = mutableListOf<Map<String, Any>>()
        for (f in files) {
            items.add(mapOf<String, Any>(
                "name" to f.name,
                "path" to f.absolutePath,
                "isDirectory" to f.isDirectory,
                "size" to f.length(),
                "lastModified" to f.lastModified()
            ))
        }
        items.sortByDescending { it["isDirectory"] as? Boolean ?: false }
        items.sortBy { it["name"] as? String ?: "" }
        return mapOf(
            "exists" to true,
            "path" to path,
            "items" to items
        )
    }

    private fun readFile(path: String): Map<String, Any> {
        val file = File(path)
        if (!file.exists()) {
            return mapOf(
                "exists" to false,
                "error" to ("File not found: $path")
            )
        }
        if (!file.isFile) {
            return mapOf(
                "exists" to false,
                "error" to ("Not a file: $path")
            )
        }
        val content = file.readText()
        return mapOf(
            "exists" to true,
            "path" to path,
            "content" to content,
            "size" to file.length()
        )
    }

    private fun writeFile(path: String, content: String): Map<String, Any> {
        try {
            val file = File(path)
            file.parentFile.mkdirs()
            file.writeText(content)
            return mapOf(
                "success" to true,
                "path" to path,
                "size" to content.length.toLong()
            )
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "path" to path,
                "error" to e.message ?: "Unknown error"
            )
        }
    }

    private fun atomicWrite(path: String, content: String): Map<String, Any> {
        try {
            val file = File(path)
            val bakFile = File("$path.bak")
            if (file.exists()) {
                file.copyTo(bakFile, overwrite = true)
            }
            file.parentFile.mkdirs()
            file.writeText(content)
            return mapOf(
                "success" to true,
                "path" to path,
                "size" to content.length.toLong(),
                "bak" to bakFile.exists()
            )
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "path" to path,
                "error" to e.message ?: "Unknown error"
            )
        }
    }

    private fun rollbackFile(path: String): Map<String, Any> {
        try {
            val file = File(path)
            val bakFile = File("$path.bak")
            if (!bakFile.exists()) {
                return mapOf(
                    "success" to false,
                    "path" to path,
                    "error" to "No .bak file found"
                )
            }
            bakFile.copyTo(file, overwrite = true)
            return mapOf(
                "success" to true,
                "path" to path,
                "message" to "Rolled back from .bak"
            )
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "path" to path,
                "error" to e.message ?: "Unknown error"
            )
        }
    }

    private fun diffFiles(path1: String, path2: String): Map<String, Any> {
        try {
            val f1 = File(path1)
            val f2 = File(path2)
            if (!f1.exists()) {
                return mapOf(
                    "success" to false,
                    "error" to ("File not found: $path1")
                )
            }
            if (!f2.exists()) {
                return mapOf(
                    "success" to false,
                    "error" to ("File not found: $path2")
                )
            }
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
            return mapOf(
                "success" to true,
                "output" to if (diff.isEmpty()) "No differences found" else diff.joinToString("\n")
            )
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "error" to e.message ?: "Unknown error"
            )
        }
    }

    private fun runTermuxCommand(command: String, args: List<String>, timeoutSec: Int): Map<String, Any> {
        return runCommandViaIntent(command, args, timeoutSec, "com.termux")
    }

    private fun runAlpineCommand(command: String, args: List<String>, timeoutSec: Int): Map<String, Any> {
        val alpineArgs = if (args.isEmpty()) listOf(command) else listOf("-c", "$command ${args.joinToString(" ")}")
        return runCommandViaIntent("sh", alpineArgs, timeoutSec, "alpine")
    }

    private fun runOpenCode(command: String, args: List<String>, timeoutSec: Int): Map<String, Any> {
        val vaultPath = getVaultPath()
        val fullArgs = mutableListOf<String>()
        fullArgs.add("web")
        fullArgs.add("--port")
        fullArgs.add("8888")
        fullArgs.add("--hostname")
        fullArgs.add("0.0.0.0")
        fullArgs.addAll(args)
        return runCommandViaIntent("opencode", fullArgs, timeoutSec, "opencode")
    }

    private fun runKashkoolSavior(role: String, model: String, prompt: String, timeoutSec: Int): Map<String, Any> {
        try {
            val vaultPath = getVaultPath()
            val saviorScript = "$vaultPath/tools/kashkool_studio.py"
            val scriptFile = File(saviorScript)
            if (!scriptFile.exists()) {
                return mapOf(
                    "success" to false,
                    "error" to ("kashkool_studio.py not found at $saviorScript")
                )
            }
            val args = listOf("python3", saviorScript, "--role", role, "--model", model, "--prompt", prompt)
            return runCommandViaIntent("python3", args, timeoutSec, "kashkool-savior")
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "error" to e.message ?: "Unknown error"
            )
        }
    }

    private fun runGitHubSync(repo: String, action: String, timeoutSec: Int): Map<String, Any> {
        try {
            val vaultPath = getVaultPath()
            val karkhanaPath = "/mnt/sdcard/opencode/karkhana"
            val karkhanaDir = File(karkhanaPath)
            if (!karkhanaDir.exists()) {
                return mapOf(
                    "success" to false,
                    "error" to ("Karkhana directory not found at $karkhanaPath")
                )
            }
            val args = if (action == "status") {
                listOf("status")
            } else if (action == "pull") {
                listOf("pull")
            } else {
                listOf("status")
            }
            return runCommandViaIntent("git", args, timeoutSec, "github-sync")
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "error" to e.message ?: "Unknown error"
            )
        }
    }

    private fun runFortressGuard(timeoutSec: Int): Map<String, Any> {
        try {
            val vaultPath = getVaultPath()
            val guardPath = "$vaultPath/tools/fortress_guard.py"
            val guardFile = File(guardPath)
            if (!guardFile.exists()) {
                return mapOf(
                    "success" to false,
                    "error" to ("fortress_guard.py not found at $guardPath")
                )
            }
            val args = listOf("python3", guardPath)
            return runCommandViaIntent("python3", args, timeoutSec, "fortress-guard")
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "error" to e.message ?: "Unknown error"
            )
        }
    }

    private fun runTrinity(command: String, args: List<String>, timeoutSec: Int): Map<String, Any> {
        try {
            val vaultPath = getVaultPath()
            val trinityPath = "$vaultPath/tools/trinity.py"
            val trinityFile = File(trinityPath)
            if (!trinityFile.exists()) {
                return mapOf(
                    "success" to false,
                    "error" to ("trinity.py not found at $trinityPath")
                )
            }
            val fullArgs = mutableListOf<String>()
            fullArgs.add("python3")
            fullArgs.add(trinityPath)
            fullArgs.add(command)
            fullArgs.addAll(args)
            return runCommandViaIntent("python3", fullArgs, timeoutSec, "trinity")
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "error" to e.message ?: "Unknown error"
            )
        }
    }

    private fun runCommandViaIntent(command: String, args: List<String>, timeoutSec: Int, context: String): Map<String, Any> {
        try {
            val cmdLine = buildCommandLine(command, args)
            val process = ProcessBuilder(cmdLine)
                .redirectErrorStream(true)
                .start()
            val output = readProcessOutput(process, timeoutSec)
            val exitCode = process.waitFor()
            return mapOf(
                "success" to (exitCode == 0),
                "exitCode" to exitCode,
                "output" to output,
                "command" to cmdLine.joinToString(" ")
            )
        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "context" to context,
                "error" to e.message ?: "Unknown error",
                "command" to command
            )
        }
    }

    private fun buildCommandLine(command: String, args: List<String>): List<String> {
        val cmdLine = mutableListOf<String>()
        cmdLine.add(command)
        cmdLine.addAll(args)
        return cmdLine
    }

    private fun readProcessOutput(process: Process, timeoutSec: Int): String {
        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val lines = mutableListOf<String>()
        var line: String?
        val startTime = System.currentTimeMillis()
        val timeoutMs = timeoutSec.toLong() * 1000
        while ((line = reader.readLine()) != null) {
            lines.add(line)
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

    override fun onDestroy() {
        executor.shutdown()
        try {
            if (!executor.awaitTermination(5, TimeUnit.SECONDS)) {
                executor.shutdownNow()
            }
        } catch (e: InterruptedException) {
            executor.shutdownNow()
            Thread.currentThread().interrupt()
        }
        super.onDestroy()
    }
}

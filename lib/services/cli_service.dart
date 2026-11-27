import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/cli_tool.dart';

class CliService {
  static const Duration commandTimeout = Duration(seconds: 30);

  final List<CliTool> registeredTools = [
    CliTool(name: 'trinity', command: 'trinity', description: 'Trinity Fortress orchestrator', isInstalled: false),
    CliTool(name: 'fortress-guard', command: 'fortress-guard', description: 'System verification guard', isInstalled: false),
    CliTool(name: 'start-savior', command: 'start-savior', description: 'Start Savior proxy on port 4000', isInstalled: false),
    CliTool(name: 'start-deck', command: 'start-deck', description: 'Start Fortress Deck on port 4050', isInstalled: false),
    CliTool(name: 'opencode', command: 'opencode', description: 'OpenCode CLI', isInstalled: false),
    CliTool(name: 'claude-free', command: 'claude-free', description: 'Claude-free via Savior proxy', isInstalled: false),
    CliTool(name: 'agy-cli', command: 'agy-cli', description: 'agy-cli AI tool', isInstalled: false),
    CliTool(name: 'kashkool-studio', command: 'kashkool-studio', description: 'Kashkool media studio', isInstalled: false),
  ];

  Future<CliToolResult> runCommand(String command, List<String> args) async {
    try {
      final process = await Process.start(command, args);
      final stdout = await process.stdout.transform(utf8.decoder).join().timeout(commandTimeout);
      final stderr = await process.stderr.transform(utf8.decoder).join().timeout(commandTimeout);
      final exitCode = await process.exitCode.timeout(commandTimeout);
      return CliToolResult(
        exitCode: exitCode,
        stdout: stdout,
        stderr: stderr,
        success: exitCode == 0,
      );
    } on TimeoutException {
      return CliToolResult(
        exitCode: -1,
        stdout: '',
        stderr: 'Command timed out after ${commandTimeout.inSeconds}s',
        success: false,
      );
    } catch (e) {
      return CliToolResult(
        exitCode: -1,
        stdout: '',
        stderr: e.toString(),
        success: false,
      );
    }
  }

  Future<bool> isToolInstalled(String command) async {
    try {
      final result = await runCommand('which', [command]);
      return result.success;
    } catch (_) {
      return false;
    }
  }

  Future<List<CliTool>> refreshTools() async {
    final updated = <CliTool>[];
    for (final tool in registeredTools) {
      final installed = await isToolInstalled(tool.command);
      updated.add(CliTool(
        name: tool.name,
        command: tool.command,
        description: tool.description,
        isInstalled: installed,
      ));
    }
    return updated;
  }
}

class CliToolResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final bool success;

  CliToolResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.success,
  });
}

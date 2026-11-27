import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/cli_tool.dart';
import 'native_bridge.dart';

class RoutingEngine {
  final NativeBridge bridge;
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration deepTimeout = Duration(seconds: 120);

  RoutingEngine(this.bridge);

  List<RoutingProfile> get profiles => [
        RoutingProfile(
          mode: 'fast',
          models: ['nemotron', 'deepseek'],
          agents: ['opencode', 'claude-cli'],
          timeout: const Duration(seconds: 15),
          maxRetries: 1,
          allowFallback: true,
          requiresGuardPass: false,
        ),
        RoutingProfile(
          mode: 'deep_reasoning',
          models: ['qwen', 'deepseek', 'nemotron'],
          agents: ['kashkool-savior', 'Antigravity'],
          timeout: const Duration(seconds: 120),
          maxRetries: 2,
          allowFallback: true,
          requiresGuardPass: true,
        ),
        RoutingProfile(
          mode: 'guard',
          models: ['nemotron'],
          agents: ['fortress-guard'],
          timeout: const Duration(seconds: 60),
          maxRetries: 1,
          allowFallback: false,
          requiresGuardPass: true,
        ),
        RoutingProfile(
          mode: 'builder',
          models: ['deepseek', 'qwen'],
          agents: ['opencode', 'claude-cli'],
          timeout: const Duration(seconds: 60),
          maxRetries: 2,
          allowFallback: true,
          requiresGuardPass: false,
        ),
      ];

  RoutingProfile profileForMode(String mode) {
    return profiles.firstWhere(
      (p) => p.mode == mode,
      orElse: () => profiles.first,
    );
  }

  Future<Map<String, dynamic>> routeTask({
    required String mode,
    required String prompt,
    String? preferredModel,
    String? preferredAgent,
  }) async {
    final profile = profileForMode(mode);
    final models = preferredModel != null ? [preferredModel] : profile.models;
    final agents = preferredAgent != null ? [preferredAgent] : profile.agents;

    for (final model in models) {
      for (final agent in agents) {
        try {
          final result = await bridge.runKashkoolSavior(
            mode,
            model,
            prompt,
            timeoutSec: profile.timeout.inSeconds,
          );
          if (result['success'] == true) {
            return {
              'success': true,
              'mode': mode,
              'model': model,
              'agent': agent,
              'output': result['output'] ?? '',
              'profile': profile.toJson(),
            };
          }
        } catch (_) {}
      }
    }

    if (profile.allowFallback) {
      final fallback = profiles.firstWhere(
        (p) => p.mode == 'fast',
        orElse: () => profiles.first,
      );
      try {
        final result = await bridge.runKashkoolSavior(
          'fast',
          fallback.models.first,
          prompt,
          timeoutSec: fallback.timeout.inSeconds,
        );
        return {
          'success': result['success'] == true,
          'mode': 'fast_fallback',
          'model': fallback.models.first,
          'agent': fallback.agents.first,
          'output': result['output'] ?? '',
          'profile': fallback.toJson(),
        };
      } catch (e) {
        return {
          'success': false,
          'mode': mode,
          'error': 'All routing attempts failed: $e',
          'profile': profile.toJson(),
        };
      }
    }

    return {
      'success': false,
      'mode': mode,
      'error': 'Routing failed for all models and agents',
      'profile': profile.toJson(),
    };
  }

  Future<Map<String, dynamic>> runGuardPass() async {
    try {
      final result = await bridge.runFortressGuard(timeoutSec: 60);
      return {
        'success': result['success'] == true,
        'output': result['output'] ?? '',
        'mode': 'guard',
      };
    } catch (e) {
      return {
        'success': false,
        'output': 'Guard pass failed: $e',
        'mode': 'guard',
      };
    }
  }

  Future<Map<String, dynamic>> runWithRetry({
    required String mode,
    required String prompt,
    required int maxRetries,
  }) async {
    Map<String, dynamic> lastResult = <String, dynamic>{};
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      lastResult = await routeTask(mode: mode, prompt: prompt);
      if (lastResult['success'] == true) {
        lastResult['attempt'] = attempt + 1;
        return lastResult;
      }
    }
    lastResult['attempt'] = maxRetries;
    return lastResult;
  }
}

class RoutingProfile {
  final String mode;
  final List<String> models;
  final List<String> agents;
  final Duration timeout;
  final int maxRetries;
  final bool allowFallback;
  final bool requiresGuardPass;

  RoutingProfile({
    required this.mode,
    required this.models,
    required this.agents,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 1,
    this.allowFallback = true,
    this.requiresGuardPass = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'models': models,
      'agents': agents,
      'timeout': timeout.inSeconds,
      'max_retries': maxRetries,
      'allow_fallback': allowFallback,
      'requires_guard_pass': requiresGuardPass,
    };
  }
}

class CliService {
  static const Duration commandTimeout = Duration(seconds: 30);

  final NativeBridge bridge;
  final RoutingEngine routingEngine;

  final List<CliTool> registeredTools = [
    CliTool(
      name: 'trinity',
      command: 'trinity',
      description: 'Trinity Fortress orchestrator',
      agentType: 'system',
      routingMode: 'fast',
      priority: 1,
    ),
    CliTool(
      name: 'fortress-guard',
      command: 'fortress-guard',
      description: 'System verification guard',
      agentType: 'guard',
      routingMode: 'guard',
      priority: 10,
    ),
    CliTool(
      name: 'start-savior',
      command: 'start-savior',
      description: 'Start Savior proxy on port 4000',
      agentType: 'system',
      routingMode: 'fast',
      priority: 2,
    ),
    CliTool(
      name: 'start-deck',
      command: 'start-deck',
      description: 'Start Fortress Deck on port 4050',
      agentType: 'system',
      routingMode: 'fast',
      priority: 2,
    ),
    CliTool(
      name: 'opencode',
      command: 'opencode',
      description: 'OpenCode CLI',
      agentType: 'ai',
      routingMode: 'builder',
      priority: 5,
    ),
    CliTool(
      name: 'claude-free',
      command: 'claude-free',
      description: 'Claude-free via Savior proxy',
      agentType: 'ai',
      routingMode: 'builder',
      priority: 5,
    ),
    CliTool(
      name: 'agy-cli',
      command: 'agy-cli',
      description: 'agy-cli AI tool',
      agentType: 'ai',
      routingMode: 'fast',
      priority: 3,
    ),
    CliTool(
      name: 'kashkool-studio',
      command: 'kashkool-studio',
      description: 'Kashkool media studio',
      agentType: 'kashkool',
      routingMode: 'builder',
      priority: 4,
    ),
  ];

  CliService({required this.bridge}) : routingEngine = RoutingEngine(bridge);

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
        agentType: tool.agentType,
        routingMode: tool.routingMode,
        priority: tool.priority,
      ));
    }
    return updated;
  }

  Future<Map<String, dynamic>> routeTask({
    required String mode,
    required String prompt,
    String? preferredModel,
    String? preferredAgent,
  }) async {
    return routingEngine.routeTask(
      mode: mode,
      prompt: prompt,
      preferredModel: preferredModel,
      preferredAgent: preferredAgent,
    );
  }

  Future<Map<String, dynamic>> runGuardPass() async {
    return routingEngine.runGuardPass();
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

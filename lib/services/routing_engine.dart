import 'dart:async';
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

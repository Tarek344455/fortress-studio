class SystemState {
  final String dns;
  final String port8888;
  final String port4000;
  final String port4050;
  final String updated;
  final String routingMode;
  final String activeAgent;

  SystemState({
    required this.dns,
    required this.port8888,
    required this.port4000,
    required this.port4050,
    required this.updated,
    this.routingMode = 'fast',
    this.activeAgent = 'nemotron',
  });

  factory SystemState.fromJson(Map<String, dynamic> json) {
    return SystemState(
      dns: (json['dns'] ?? 'unknown').toString(),
      port8888: (json['port_8888'] ?? '000').toString(),
      port4000: (json['port_4000'] ?? '000').toString(),
      port4050: (json['port_4050'] ?? '000').toString(),
      updated: (json['updated'] ?? '').toString(),
      routingMode: (json['routing_mode'] ?? 'fast').toString(),
      activeAgent: (json['active_agent'] ?? 'nemotron').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dns': dns,
      'port_8888': port8888,
      'port_4000': port4000,
      'port_4050': port4050,
      'updated': updated,
      'routing_mode': routingMode,
      'active_agent': activeAgent,
    };
  }

  bool get isHealthy {
    return dns == 'ok' &&
        (port8888 == '200' || port8888 == '401') &&
        port4000 == '200' &&
        port4050 == '200';
  }
}

class ComponentStatus {
  final String name;
  final String port;
  final String httpCode;
  final bool isOnline;

  ComponentStatus({
    required this.name,
    required this.port,
    required this.httpCode,
    required this.isOnline,
  });

  String get statusLabel {
    if (!isOnline) return 'FAIL';
    if (httpCode == '200') return 'PASS';
    if (httpCode == '401') return 'ACTIVE';
    return 'PARTIAL';
  }
}

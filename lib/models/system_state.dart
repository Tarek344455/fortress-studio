class SystemState {
  final String dns;
  final String port8888;
  final String port4000;
  final String updated;

  SystemState({
    required this.dns,
    required this.port8888,
    required this.port4000,
    required this.updated,
  });

  factory SystemState.fromJson(Map<String, dynamic> json) {
    return SystemState(
      dns: json['dns'] ?? 'unknown',
      port8888: json['port_8888'] ?? '000',
      port4000: json['port_4000'] ?? '000',
      updated: json['updated'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dns': dns,
      'port_8888': port8888,
      'port_4000': port4000,
      'updated': updated,
    };
  }

  bool get isHealthy {
    return dns == 'ok' &&
        (port8888 == '200' || port8888 == '401') &&
        port4000 == '200';
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

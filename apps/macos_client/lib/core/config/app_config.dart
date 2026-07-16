abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );

  static Uri get realtimeUri {
    final apiUri = Uri.parse(apiBaseUrl);
    return apiUri.replace(
      scheme: apiUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/api/v1/realtime',
      query: null,
      fragment: null,
    );
  }
}

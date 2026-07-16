class ApiFailure implements Exception {
  const ApiFailure({required this.code, required this.message});

  final String code;
  final String message;

  bool get isNetworkFailure => code == 'network_error';

  @override
  String toString() => 'ApiFailure($code)';
}

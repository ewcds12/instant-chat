class AuthFailure implements Exception {
  const AuthFailure({required this.code, required this.message});

  final String code;
  final String message;

  bool get isNetworkFailure => code == 'network_error';

  @override
  String toString() => message;
}

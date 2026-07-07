class DfcEnvironment {
  const DfcEnvironment._();

  static const String apiBaseUrl = String.fromEnvironment(
    'DFC_API_BASE',
    defaultValue: 'https://api.example.com',
  );

  static const bool isProduction = bool.fromEnvironment(
    'DFC_PROD',
    defaultValue: false,
  );
}

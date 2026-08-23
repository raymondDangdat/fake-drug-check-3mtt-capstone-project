/// API configuration for the FakeDrugChecker app.
///
/// Update [baseUrl] to point to your deployed FastAPI backend.
class ApiConfig {
  /// Deployed FastAPI production URL on Render.
  static const String baseUrl = 'https://fake-drug-checker-api.onrender.com';

  /// Prediction endpoint.
  static const String predictEndpoint = '/predict';

  /// Health check endpoint.
  static const String healthEndpoint = '/health';

  /// Connection timeout in seconds.
  static const int timeoutSeconds = 30;
}

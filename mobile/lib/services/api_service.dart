import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/drug_check_result.dart';

/// Service for communicating with the FakeDrugChecker FastAPI backend.
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Check if the API server is reachable and healthy.
  Future<bool> isHealthy() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConfig.baseUrl}${ApiConfig.healthEndpoint}'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      print('DEBUG: ApiService.isHealthy failed: $e');
      return false;
    }
  }

  /// Submit a drug check request to the API.
  ///
  /// Returns a [DrugCheckResult] on success.
  /// Throws [ApiException] on failure.
  Future<DrugCheckResult> checkDrug({
    required String drugName,
    required String manufacturer,
    required String nafdacNumber,
    required String barcode,
    required String batchNumber,
    required String dosageForm,
    required String strength,
    required String country,
  }) async {
    final inputData = {
      'drug_name': drugName,
      'manufacturer': manufacturer,
      'nafdac_number': nafdacNumber,
      'barcode': barcode,
      'batch_number': batchNumber,
      'dosage_form': dosageForm,
      'strength': strength,
      'country': country,
    };

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.predictEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(inputData),
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Build a human-readable input map for display/storage
        final displayInput = <String, String>{
          'Drug Name': drugName,
          'Manufacturer': manufacturer,
          'NAFDAC Number': nafdacNumber,
          'Barcode': barcode,
          'Batch Number': batchNumber,
          'Dosage Form': dosageForm,
          'Strength': strength,
          'Country': country,
        };

        return DrugCheckResult.fromJson(data, input: displayInput);
      } else if (response.statusCode == 503) {
        throw ApiException(
          'Model not available. Please ensure the server has been configured correctly.',
        );
      } else {
        final errorBody = jsonDecode(response.body);
        throw ApiException(
          errorBody['detail'] ?? 'Server error (${response.statusCode})',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(
          'Connection timed out. Please check your internet connection and try again.',
        );
      }
      throw ApiException(
        'Could not connect to the server. Please check your connection and ensure the API is running.',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

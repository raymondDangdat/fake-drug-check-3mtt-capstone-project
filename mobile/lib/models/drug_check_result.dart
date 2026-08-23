import 'dart:convert';

/// Data model representing a drug verification result from the API.
class DrugCheckResult {
  final String prediction;
  final double confidence;
  final String confidencePercent;
  final List<String> explanation;
  final String recommendation;
  final Map<String, String> inputData;
  final DateTime checkedAt;

  DrugCheckResult({
    required this.prediction,
    required this.confidence,
    required this.confidencePercent,
    required this.explanation,
    required this.recommendation,
    required this.inputData,
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.now();

  /// Whether the drug was classified as genuine.
  bool get isGenuine => prediction == 'Genuine';

  /// Whether the drug was classified as suspicious.
  bool get isSuspicious => prediction == 'Suspicious';

  /// Create from API JSON response.
  factory DrugCheckResult.fromJson(
    Map<String, dynamic> json, {
    Map<String, String>? input,
  }) {
    return DrugCheckResult(
      prediction: json['prediction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      confidencePercent: json['confidence_percent'] as String,
      explanation: List<String>.from(json['explanation'] as List),
      recommendation: json['recommendation'] as String,
      inputData: input ?? {},
    );
  }

  /// Convert to JSON for local storage.
  Map<String, dynamic> toJson() {
    return {
      'prediction': prediction,
      'confidence': confidence,
      'confidence_percent': confidencePercent,
      'explanation': explanation,
      'recommendation': recommendation,
      'input_data': inputData,
      'checked_at': checkedAt.toIso8601String(),
    };
  }

  /// Restore from local storage JSON.
  factory DrugCheckResult.fromStorageJson(Map<String, dynamic> json) {
    return DrugCheckResult(
      prediction: json['prediction'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      confidencePercent: json['confidence_percent'] as String,
      explanation: List<String>.from(json['explanation'] as List),
      recommendation: json['recommendation'] as String,
      inputData: Map<String, String>.from(json['input_data'] as Map),
      checkedAt: DateTime.parse(json['checked_at'] as String),
    );
  }

  /// Serialize to a JSON string (for SharedPreferences).
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from a JSON string.
  factory DrugCheckResult.fromJsonString(String jsonString) {
    return DrugCheckResult.fromStorageJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }
}

import 'package:equatable/equatable.dart';

class RecognitionRecord extends Equatable {
  final String id;
  final String predictedLabel;
  final double confidence;
  final String? correctedLabel;
  final bool isCorrect;
  final String? imagePath;
  final DateTime timestamp;
  final String? userFeedback;

  const RecognitionRecord({
    required this.id,
    required this.predictedLabel,
    required this.confidence,
    this.correctedLabel,
    this.isCorrect = true,
    this.imagePath,
    required this.timestamp,
    this.userFeedback,
  });

  factory RecognitionRecord.fromMap(Map<String, dynamic> map) {
    return RecognitionRecord(
      id: map['id'] as String,
      predictedLabel: map['predicted_label'] as String,
      confidence: map['confidence'] as double,
      correctedLabel: map['corrected_label'] as String?,
      isCorrect: (map['is_correct'] as int) == 1,
      imagePath: map['image_path'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      userFeedback: map['user_feedback'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'predicted_label': predictedLabel,
      'confidence': confidence,
      'corrected_label': correctedLabel,
      'is_correct': isCorrect ? 1 : 0,
      'image_path': imagePath,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'user_feedback': userFeedback,
    };
  }

  RecognitionRecord copyWith({
    String? id,
    String? predictedLabel,
    double? confidence,
    String? correctedLabel,
    bool? isCorrect,
    String? imagePath,
    DateTime? timestamp,
    String? userFeedback,
  }) {
    return RecognitionRecord(
      id: id ?? this.id,
      predictedLabel: predictedLabel ?? this.predictedLabel,
      confidence: confidence ?? this.confidence,
      correctedLabel: correctedLabel ?? this.correctedLabel,
      isCorrect: isCorrect ?? this.isCorrect,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
      userFeedback: userFeedback ?? this.userFeedback,
    );
  }

  @override
  List<Object?> get props => [
    id,
    predictedLabel,
    confidence,
    correctedLabel,
    isCorrect,
    imagePath,
    timestamp,
    userFeedback,
  ];
}
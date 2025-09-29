import 'package:equatable/equatable.dart';

class TrainingData extends Equatable {
  final String id;
  final String label;
  final String imagePath;
  final String source; // 'camera', 'correction', 'manual'
  final DateTime timestamp;
  final bool isValidated;

  const TrainingData({
    required this.id,
    required this.label,
    required this.imagePath,
    required this.source,
    required this.timestamp,
    this.isValidated = false,
  });

  factory TrainingData.fromMap(Map<String, dynamic> map) {
    return TrainingData(
      id: map['id'] as String,
      label: map['label'] as String,
      imagePath: map['image_path'] as String,
      source: map['source'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isValidated: (map['is_validated'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'image_path': imagePath,
      'source': source,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_validated': isValidated ? 1 : 0,
    };
  }

  @override
  List<Object> get props => [id, label, imagePath, source, timestamp, isValidated];
}
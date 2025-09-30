import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../data/repositories/data_repository.dart';

enum TrainingStatus {
  idle,
  preprocessing,
  training,
  evaluating,
  exporting,
  completed,
  error
}

class TrainingProgress {
  final TrainingStatus status;
  final double progress;
  final String message;
  final Map<String, dynamic>? data;

  TrainingProgress({
    required this.status,
    required this.progress,
    required this.message,
    this.data,
  });

  TrainingProgress copyWith({
    TrainingStatus? status,
    double? progress,
    String? message,
    Map<String, dynamic>? data,
  }) {
    return TrainingProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }
}

class TrainingService {
  final DataRepository _dataRepository = DataRepository();
  
  // Training configuration
  static const int _minSamplesPerClass = 10;
  static const int _maxSamplesPerClass = 200;
  static const int _imageSize = 224;
  
  Future<TrainingProgress> checkTrainingReadiness() async {
    try {
      final stats = await _dataRepository.getTrainingDataStats();
      final validClasses = stats.entries
          .where((entry) => entry.value >= _minSamplesPerClass)
          .length;
      
      if (validClasses < 2) {
        return TrainingProgress(
          status: TrainingStatus.error,
          progress: 0.0,
          message: 'Need at least 2 classes with $_minSamplesPerClass+ samples each',
          data: {'current_classes': validClasses, 'stats': stats},
        );
      }
      
      final totalSamples = stats.values.fold(0, (sum, count) => sum + count);
      
      return TrainingProgress(
        status: TrainingStatus.idle,
        progress: 0.0,
        message: 'Ready to train with $validClasses classes ($totalSamples samples)',
        data: {'classes': validClasses, 'samples': totalSamples, 'stats': stats},
      );
      
    } catch (e) {
      return TrainingProgress(
        status: TrainingStatus.error,
        progress: 0.0,
        message: 'Error checking training data: $e',
      );
    }
  }
  
  Future<String> exportTrainingData() async {
    final directory = await getTemporaryDirectory();
    final exportDir = Directory('${directory.path}/training_export');
    
    if (await exportDir.exists()) {
      await exportDir.delete(recursive: true);
    }
    await exportDir.create(recursive: true);
    
    // Export JSON data
    final jsonData = await _dataRepository.exportTrainingData();
    final jsonFile = File('${exportDir.path}/training_data.json');
    await jsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonData),
    );
    
    print('✅ Training data exported to: ${jsonFile.path}');
    return jsonFile.path;
  }
  
  Future<TrainingProgress> simulateTraining({
    required Function(TrainingProgress) onProgress,
  }) async {
    try {
      // Step 1: Check readiness
      onProgress(TrainingProgress(
        status: TrainingStatus.preprocessing,
        progress: 0.1,
        message: 'Checking training data...',
      ));
      
      await Future.delayed(const Duration(seconds: 2));
      final readiness = await checkTrainingReadiness();
      if (readiness.status == TrainingStatus.error) {
        return readiness;
      }
      
      // Step 2: Export data
      onProgress(TrainingProgress(
        status: TrainingStatus.preprocessing,
        progress: 0.2,
        message: 'Exporting training data...',
      ));
      
      await Future.delayed(const Duration(seconds: 1));
      await exportTrainingData();
      
      // Step 3: Simulate preprocessing
      onProgress(TrainingProgress(
        status: TrainingStatus.preprocessing,
        progress: 0.3,
        message: 'Preprocessing images and creating splits...',
      ));
      
      await Future.delayed(const Duration(seconds: 3));
      
      // Step 4: Simulate training
      for (int epoch = 1; epoch <= 10; epoch++) {
        await Future.delayed(const Duration(seconds: 2));
        
        final progress = 0.3 + (epoch / 10) * 0.5; // 0.3 to 0.8
        onProgress(TrainingProgress(
          status: TrainingStatus.training,
          progress: progress,
          message: 'Training model... Epoch $epoch/10',
          data: {'epoch': epoch, 'total_epochs': 10},
        ));
      }
      
      // Step 5: Simulate evaluation
      onProgress(TrainingProgress(
        status: TrainingStatus.evaluating,
        progress: 0.85,
        message: 'Evaluating model performance...',
      ));
      
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 6: Simulate export
      onProgress(TrainingProgress(
        status: TrainingStatus.exporting,
        progress: 0.95,
        message: 'Exporting TensorFlow Lite model...',
      ));
      
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 7: Create mock trained model
      await _createMockTrainedModel();
      
      // Complete
      final completedProgress = TrainingProgress(
        status: TrainingStatus.completed,
        progress: 1.0,
        message: 'Training completed successfully!',
        data: {
          'accuracy': 0.92,
          'classes': readiness.data!['stats'].keys.toList(),
          'model_size': '2.1 MB',
        },
      );
      
      onProgress(completedProgress);
      return completedProgress;
      
    } catch (e) {
      final errorProgress = TrainingProgress(
        status: TrainingStatus.error,
        progress: 0.0,
        message: 'Training failed: $e',
      );
      
      onProgress(errorProgress);
      return errorProgress;
    }
  }
  
  Future<void> _createMockTrainedModel() async {
    // Create a mock trained model file and labels
    final directory = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${directory.path}/trained_models');
    
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    
    // Create mock model file (in reality, this would be the actual trained TFLite model)
    final modelFile = File('${modelsDir.path}/custom_sign_classifier.tflite');
    await modelFile.writeAsBytes([0x00, 0x01, 0x02]); // Mock bytes
    
    // Create labels from actual training data
    final stats = await _dataRepository.getTrainingDataStats();
    final validLabels = stats.entries
        .where((entry) => entry.value >= _minSamplesPerClass)
        .map((entry) => entry.key)
        .toList();
    
    final labelsFile = File('${modelsDir.path}/custom_labels.txt');
    await labelsFile.writeAsString(validLabels.join('\n'));
    
    // Create model info
    final infoFile = File('${modelsDir.path}/model_info.json');
    await infoFile.writeAsString(jsonEncode({
      'name': 'Custom Sign Language Classifier',
      'version': '1.0.0',
      'created': DateTime.now().toIso8601String(),
      'accuracy': 0.92,
      'classes': validLabels,
      'training_samples': stats.values.fold(0, (sum, count) => sum + count),
      'model_type': 'MobileNetV2',
      'input_size': _imageSize,
    }));
    
    print('✅ Mock trained model created at: ${modelFile.path}');
  }
  
  Future<Map<String, dynamic>?> getTrainedModelInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final infoFile = File('${directory.path}/trained_models/model_info.json');
      
      if (await infoFile.exists()) {
        final content = await infoFile.readAsString();
        return jsonDecode(content);
      }
      
      return null;
    } catch (e) {
      print('⚠️ Error reading model info: $e');
      return null;
    }
  }
  
  Future<bool> hasTrainedModel() async {
    final info = await getTrainedModelInfo();
    return info != null;
  }
}

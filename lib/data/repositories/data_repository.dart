import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../database/database_helper.dart';
import '../models/recognition_record.dart';
import '../models/training_data.dart';

class DataRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  // Recognition History Methods
  Future<String> saveRecognition({
    required String predictedLabel,
    required double confidence,
    String? imagePath,
    String? userFeedback,
  }) async {
    final db = await _dbHelper.database;
    final id = _uuid.v4();
    
    final record = RecognitionRecord(
      id: id,
      predictedLabel: predictedLabel,
      confidence: confidence,
      imagePath: imagePath,
      timestamp: DateTime.now(),
      userFeedback: userFeedback,
    );
    
    await db.insert('recognitions', record.toMap());
    print('✅ Recognition saved: $predictedLabel (${confidence.toStringAsFixed(2)})');
    
    return id;
  }

  Future<void> updateRecognition(RecognitionRecord record) async {
    final db = await _dbHelper.database;
    await db.update(
      'recognitions',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    print('✅ Recognition updated: ${record.id}');
  }

  Future<List<RecognitionRecord>> getRecognitions({
    int? limit,
    String? labelFilter,
  }) async {
    final db = await _dbHelper.database;
    
    String query = 'SELECT * FROM recognitions';
    List<dynamic> args = [];
    
    if (labelFilter != null) {
      query += ' WHERE predicted_label = ? OR corrected_label = ?';
      args.addAll([labelFilter, labelFilter]);
    }
    
    query += ' ORDER BY timestamp DESC';
    
    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }
    
    final result = await db.rawQuery(query, args);
    return result.map((map) => RecognitionRecord.fromMap(map)).toList();
  }

  Future<void> correctRecognition({
    required String recognitionId,
    required String correctedLabel,
    String? feedback,
  }) async {
    final db = await _dbHelper.database;
    
    // Update the recognition record
    await db.update(
      'recognitions',
      {
        'corrected_label': correctedLabel,
        'is_correct': 0,
        'user_feedback': feedback,
      },
      where: 'id = ?',
      whereArgs: [recognitionId],
    );
    
    // Get the recognition to create training data
    final recognition = await getRecognitionById(recognitionId);
    if (recognition != null && recognition.imagePath != null) {
      await saveTrainingData(
        label: correctedLabel,
        imagePath: recognition.imagePath!,
        source: 'correction',
      );
    }
    
    print('✅ Recognition corrected: $recognitionId -> $correctedLabel');
  }

  Future<RecognitionRecord?> getRecognitionById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'recognitions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return RecognitionRecord.fromMap(result.first);
  }

  // Training Data Methods
  Future<String> saveTrainingData({
    required String label,
    required String imagePath,
    required String source,
  }) async {
    final db = await _dbHelper.database;
    final id = _uuid.v4();
    
    final trainingData = TrainingData(
      id: id,
      label: label.toLowerCase().trim(),
      imagePath: imagePath,
      source: source,
      timestamp: DateTime.now(),
    );
    
    await db.insert('training_data', trainingData.toMap());
    print('✅ Training data saved: $label from $source');
    
    return id;
  }

  Future<List<TrainingData>> getTrainingData({String? label}) async {
    final db = await _dbHelper.database;
    
    String query = 'SELECT * FROM training_data';
    List<dynamic> args = [];
    
    if (label != null) {
      query += ' WHERE label = ?';
      args.add(label.toLowerCase().trim());
    }
    
    query += ' ORDER BY timestamp DESC';
    
    final result = await db.rawQuery(query, args);
    return result.map((map) => TrainingData.fromMap(map)).toList();
  }

  Future<Map<String, int>> getTrainingDataStats() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT label, COUNT(*) as count 
      FROM training_data 
      GROUP BY label 
      ORDER BY count DESC
    ''');
    
    return Map.fromEntries(
      result.map((row) => MapEntry(row['label'] as String, row['count'] as int)),
    );
  }

  // Image Management
  Future<String> saveImageForTraining(List<int> imageBytes, String label) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/training_images');
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${label}_$timestamp.jpg';
    final filePath = path.join(imagesDir.path, fileName);
    
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    
    return filePath;
  }

  // Export Methods
  Future<Map<String, dynamic>> exportTrainingData() async {
    final trainingData = await getTrainingData();
    final stats = await getTrainingDataStats();
    
    return {
      'export_date': DateTime.now().toIso8601String(),
      'total_samples': trainingData.length,
      'labels': stats.keys.toList(),
      'stats': stats,
      'data': trainingData.map((data) => {
        'id': data.id,
        'label': data.label,
        'image_path': data.imagePath,
        'source': data.source,
        'timestamp': data.timestamp.toIso8601String(),
        'is_validated': data.isValidated,
      }).toList(),
    };
  }

  // Cleanup Methods
  Future<void> clearOldRecognitions({int keepDays = 30}) async {
    final db = await _dbHelper.database;
    final cutoffTime = DateTime.now().subtract(Duration(days: keepDays));
    
    await db.delete(
      'recognitions',
      where: 'timestamp < ?',
      whereArgs: [cutoffTime.millisecondsSinceEpoch],
    );
    
    print('✅ Cleared old recognitions (keeping $keepDays days)');
  }

  Future<void> deleteAllData() async {
    await _dbHelper.deleteDatabase();
    print('✅ All data deleted');
  }
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/repositories/data_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final DataRepository _dataRepository = DataRepository();

  HistoryBloc() : super(HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<RefreshHistory>(_onRefreshHistory);
    on<DeleteHistoryItem>(_onDeleteHistoryItem);
    on<ExportTrainingData>(_onExportTrainingData);
    on<LoadTrainingStats>(_onLoadTrainingStats);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      emit(HistoryLoading());
      
      final recognitions = await _dataRepository.getRecognitions(
        limit: event.limit ?? 100,
        labelFilter: event.labelFilter,
      );
      
      final trainingStats = await _dataRepository.getTrainingDataStats();
      final totalSamples = trainingStats.values.fold(0, (sum, count) => sum + count);
      
      emit(HistoryLoaded(
        recognitions: recognitions,
        trainingStats: trainingStats,
        totalSamples: totalSamples,
      ));
      
    } catch (e) {
      emit(HistoryError('Failed to load history: $e'));
    }
  }

  Future<void> _onRefreshHistory(
    RefreshHistory event,
    Emitter<HistoryState> emit,
  ) async {
    add(const LoadHistory());
  }

  Future<void> _onDeleteHistoryItem(
    DeleteHistoryItem event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      // TODO: Implement delete functionality
      add(RefreshHistory());
    } catch (e) {
      emit(HistoryError('Failed to delete item: $e'));
    }
  }

  Future<void> _onExportTrainingData(
    ExportTrainingData event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      emit(HistoryLoading());
      
      final exportData = await _dataRepository.exportTrainingData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/training_data_export.json');
      await file.writeAsString(jsonString);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sign Language Training Data Export',
      );
      
      emit(TrainingDataExported(file.path));
      
    } catch (e) {
      emit(HistoryError('Failed to export data: $e'));
    }
  }

  Future<void> _onLoadTrainingStats(
    LoadTrainingStats event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      final stats = await _dataRepository.getTrainingDataStats();
      final totalSamples = stats.values.fold(0, (sum, count) => sum + count);
      
      emit(HistoryLoaded(
        recognitions: [],
        trainingStats: stats,
        totalSamples: totalSamples,
      ));
      
    } catch (e) {
      emit(HistoryError('Failed to load training stats: $e'));
    }
  }
}

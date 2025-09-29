import 'package:equatable/equatable.dart';
import '../../../data/models/recognition_record.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<RecognitionRecord> recognitions;
  final Map<String, int> trainingStats;
  final int totalSamples;
  
  const HistoryLoaded({
    required this.recognitions,
    required this.trainingStats,
    required this.totalSamples,
  });
  
  @override
  List<Object> get props => [recognitions, trainingStats, totalSamples];
}

class HistoryError extends HistoryState {
  final String message;
  
  const HistoryError(this.message);
  
  @override
  List<Object> get props => [message];
}

class TrainingDataExported extends HistoryState {
  final String filePath;
  
  const TrainingDataExported(this.filePath);
  
  @override
  List<Object> get props => [filePath];
}

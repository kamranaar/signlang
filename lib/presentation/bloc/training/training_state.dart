import 'package:equatable/equatable.dart';
import '../../../services/training_service.dart';

abstract class TrainingState extends Equatable {
  const TrainingState();

  @override
  List<Object?> get props => [];
}

class TrainingInitial extends TrainingState {}

class TrainingReadinessChecked extends TrainingState {
  final TrainingProgress progress;
  
  const TrainingReadinessChecked(this.progress);
  
  @override
  List<Object> get props => [progress];
}

class TrainingInProgress extends TrainingState {
  final TrainingProgress progress;
  
  const TrainingInProgress(this.progress);
  
  @override
  List<Object> get props => [progress];
}

class TrainingCompleted extends TrainingState {
  final TrainingProgress progress;
  final Map<String, dynamic>? modelInfo;
  
  const TrainingCompleted(this.progress, {this.modelInfo});
  
  @override
  List<Object?> get props => [progress, modelInfo];
}

class TrainingError extends TrainingState {
  final String message;
  
  const TrainingError(this.message);
  
  @override
  List<Object> get props => [message];
}

class ModelInfoLoaded extends TrainingState {
  final Map<String, dynamic>? modelInfo;
  final bool hasTrainedModel;
  
  const ModelInfoLoaded({this.modelInfo, required this.hasTrainedModel});
  
  @override
  List<Object?> get props => [modelInfo, hasTrainedModel];
}
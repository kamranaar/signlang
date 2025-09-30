import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/training_service.dart';
import 'training_event.dart';
import 'training_state.dart';

class TrainingBloc extends Bloc<TrainingEvent, TrainingState> {
  final TrainingService _trainingService = TrainingService();
  StreamSubscription? _trainingSubscription;

  TrainingBloc() : super(TrainingInitial()) {
    on<CheckTrainingReadiness>(_onCheckTrainingReadiness);
    on<StartTraining>(_onStartTraining);
    on<StopTraining>(_onStopTraining);
    on<ResetTraining>(_onResetTraining);
    on<LoadTrainedModelInfo>(_onLoadTrainedModelInfo);
  }

  Future<void> _onCheckTrainingReadiness(
    CheckTrainingReadiness event,
    Emitter<TrainingState> emit,
  ) async {
    try {
      final progress = await _trainingService.checkTrainingReadiness();
      emit(TrainingReadinessChecked(progress));
    } catch (e) {
      emit(TrainingError('Failed to check training readiness: $e'));
    }
  }

  Future<void> _onStartTraining(
    StartTraining event,
    Emitter<TrainingState> emit,
  ) async {
    try {
      await _trainingService.simulateTraining(
        onProgress: (progress) {
          if (!isClosed) {
            if (progress.status == TrainingStatus.completed) {
              emit(TrainingCompleted(progress));
            } else if (progress.status == TrainingStatus.error) {
              emit(TrainingError(progress.message));
            } else {
              emit(TrainingInProgress(progress));
            }
          }
        },
      );
    } catch (e) {
      emit(TrainingError('Training failed: $e'));
    }
  }

  void _onStopTraining(StopTraining event, Emitter<TrainingState> emit) {
    _trainingSubscription?.cancel();
    emit(TrainingError('Training stopped by user'));
  }

  void _onResetTraining(ResetTraining event, Emitter<TrainingState> emit) {
    _trainingSubscription?.cancel();
    emit(TrainingInitial());
  }

  Future<void> _onLoadTrainedModelInfo(
    LoadTrainedModelInfo event,
    Emitter<TrainingState> emit,
  ) async {
    try {
      final hasModel = await _trainingService.hasTrainedModel();
      final modelInfo = await _trainingService.getTrainedModelInfo();
      
      emit(ModelInfoLoaded(
        modelInfo: modelInfo,
        hasTrainedModel: hasModel,
      ));
    } catch (e) {
      emit(TrainingError('Failed to load model info: $e'));
    }
  }

  @override
  Future<void> close() {
    _trainingSubscription?.cancel();
    return super.close();
  }
}
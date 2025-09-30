import 'package:equatable/equatable.dart';

abstract class TrainingEvent extends Equatable {
  const TrainingEvent();

  @override
  List<Object?> get props => [];
}

class CheckTrainingReadiness extends TrainingEvent {}

class StartTraining extends TrainingEvent {}

class StopTraining extends TrainingEvent {}

class ResetTraining extends TrainingEvent {}

class LoadTrainedModelInfo extends TrainingEvent {}
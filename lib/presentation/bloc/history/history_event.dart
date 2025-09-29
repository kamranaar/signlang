import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistory extends HistoryEvent {
  final String? labelFilter;
  final int? limit;
  
  const LoadHistory({this.labelFilter, this.limit});
  
  @override
  List<Object?> get props => [labelFilter, limit];
}

class RefreshHistory extends HistoryEvent {}

class DeleteHistoryItem extends HistoryEvent {
  final String recognitionId;
  
  const DeleteHistoryItem(this.recognitionId);
  
  @override
  List<Object> get props => [recognitionId];
}

class ExportTrainingData extends HistoryEvent {}

class LoadTrainingStats extends HistoryEvent {}
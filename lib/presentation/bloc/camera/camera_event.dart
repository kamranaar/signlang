import 'package:equatable/equatable.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCamera extends CameraEvent {}

class SwitchCamera extends CameraEvent {}

class StartPreview extends CameraEvent {}

class StopPreview extends CameraEvent {}

class CaptureFrame extends CameraEvent {}

class DisposeCamera extends CameraEvent {}

class HandleCameraError extends CameraEvent {
  final String error;
  
  const HandleCameraError(this.error);
  
  @override
  List<Object> get props => [error];
}
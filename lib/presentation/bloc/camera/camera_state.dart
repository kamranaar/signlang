import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';
import '../../../domain/entities/camera_info.dart';

abstract class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object?> get props => [];
}

class CameraInitial extends CameraState {}

class CameraLoading extends CameraState {
  final String message;
  
  const CameraLoading({this.message = 'Initializing camera...'});
  
  @override
  List<Object> get props => [message];
}

class CameraReady extends CameraState {
  final CameraController controller;
  final List<CameraInfo> availableCameras;
  final int currentCameraIndex;
  final bool isPreviewActive;
  
  const CameraReady({
    required this.controller,
    required this.availableCameras,
    required this.currentCameraIndex,
    this.isPreviewActive = true,
  });
  
  @override
  List<Object> get props => [
    controller,
    availableCameras,
    currentCameraIndex,
    isPreviewActive,
  ];
  
  CameraReady copyWith({
    CameraController? controller,
    List<CameraInfo>? availableCameras,
    int? currentCameraIndex,
    bool? isPreviewActive,
  }) {
    return CameraReady(
      controller: controller ?? this.controller,
      availableCameras: availableCameras ?? this.availableCameras,
      currentCameraIndex: currentCameraIndex ?? this.currentCameraIndex,
      isPreviewActive: isPreviewActive ?? this.isPreviewActive,
    );
  }
}

class CameraError extends CameraState {
  final String message;
  final String? details;
  
  const CameraError({
    required this.message,
    this.details,
  });
  
  @override
  List<Object?> get props => [message, details];
}

class CameraPermissionDenied extends CameraState {
  final String message;
  
  const CameraPermissionDenied({
    this.message = 'Camera permission is required to continue',
  });
  
  @override
  List<Object> get props => [message];
}
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../domain/entities/camera_info.dart';
import '../../../core/constants/app_constants.dart';
import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  
  CameraBloc() : super(CameraInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<SwitchCamera>(_onSwitchCamera);
    on<StartPreview>(_onStartPreview);
    on<StopPreview>(_onStopPreview);
    on<CaptureFrame>(_onCaptureFrame);
    on<DisposeCamera>(_onDisposeCamera);
    on<HandleCameraError>(_onHandleCameraError);
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<CameraState> emit,
  ) async {
    try {
      emit(const CameraLoading(message: AppStrings.initializingCamera));
      
      // Check camera permission
      final permission = await Permission.camera.request();
      if (permission != PermissionStatus.granted) {
        emit(const CameraPermissionDenied());
        return;
      }
      
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        emit(const CameraError(
          message: AppStrings.noCameraFound,
          details: 'No camera devices found on this device',
        ));
        return;
      }
      
      // Initialize first camera (usually back camera)
      await _initializeCameraController(0);
      
      if (_controller != null && _controller!.value.isInitialized) {
        final cameraInfos = _cameras
            .map((camera) => CameraInfo.fromCameraDescription(camera))
            .toList();
            
        emit(CameraReady(
          controller: _controller!,
          availableCameras: cameraInfos,
          currentCameraIndex: _currentCameraIndex,
          isPreviewActive: true,
        ));
      }
    } catch (e) {
      emit(CameraError(
        message: AppStrings.cameraError,
        details: e.toString(),
      ));
    }
  }

  Future<void> _initializeCameraController(int cameraIndex) async {
    if (cameraIndex >= _cameras.length) return;
    
    // Dispose previous controller
    await _controller?.dispose();
    
    _currentCameraIndex = cameraIndex;
    _controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    await _controller!.initialize();
  }

  Future<void> _onSwitchCamera(
    SwitchCamera event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    
    try {
      emit(const CameraLoading(message: 'Switching camera...'));
      
      // Switch to next camera
      final nextIndex = (_currentCameraIndex + 1) % _cameras.length;
      await _initializeCameraController(nextIndex);
      
      if (_controller != null && _controller!.value.isInitialized) {
        final currentState = state as CameraReady;
        emit(currentState.copyWith(
          controller: _controller!,
          currentCameraIndex: _currentCameraIndex,
        ));
      }
    } catch (e) {
      add(HandleCameraError('Failed to switch camera: $e'));
    }
  }

  void _onStartPreview(StartPreview event, Emitter<CameraState> emit) {
    if (state is CameraReady) {
      final currentState = state as CameraReady;
      emit(currentState.copyWith(isPreviewActive: true));
    }
  }

  void _onStopPreview(StopPreview event, Emitter<CameraState> emit) {
    if (state is CameraReady) {
      final currentState = state as CameraReady;
      emit(currentState.copyWith(isPreviewActive: false));
    }
  }

  void _onCaptureFrame(CaptureFrame event, Emitter<CameraState> emit) {
    // Placeholder for frame capture logic
    // Will be implemented in Day 3-4 for ML inference
    print('Frame captured at ${DateTime.now()}');
  }

  Future<void> _onDisposeCamera(
    DisposeCamera event,
    Emitter<CameraState> emit,
  ) async {
    await _controller?.dispose();
    _controller = null;
    emit(CameraInitial());
  }

  void _onHandleCameraError(
    HandleCameraError event,
    Emitter<CameraState> emit,
  ) {
    emit(CameraError(message: event.error));
  }

  @override
  Future<void> close() {
    _controller?.dispose();
    return super.close();
  }
}
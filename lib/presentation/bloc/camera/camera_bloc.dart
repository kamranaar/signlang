import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signlang/services/tflite_service.dart';
import '../../../domain/entities/camera_info.dart';
import '../../../core/constants/app_constants.dart';
import 'camera_event.dart';
import 'camera_state.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../../data/repositories/data_repository.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final TfliteService _tfliteService;
  final DataRepository _dataRepository = DataRepository();
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  Timer? _inferenceTimer;
  bool _isInferenceActive = false;
  
  CameraBloc(this._tfliteService) : super(CameraInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<SwitchCamera>(_onSwitchCamera);
    on<StartPreview>(_onStartPreview);
    on<StopPreview>(_onStopPreview);
    on<CaptureFrame>(_onCaptureFrame);
    on<DisposeCamera>(_onDisposeCamera);
    on<HandleCameraError>(_onHandleCameraError);
    on<StartInference>(_onStartInference);
    on<StopInference>(_onStopInference);
    on<ProcessCameraFrame>(_onProcessCameraFrame);
    on<SaveCurrentPrediction>(_onSaveCurrentPrediction);
    on<CorrectPrediction>(_onCorrectPrediction);
    on<ClearPredictionHistory>(_onClearPredictionHistory);

  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<CameraState> emit,
    
  ) async {
    print('🎥 Requesting camera permission...');
final permission = await Permission.camera.request();
print('🎥 Permission: $permission');

print('🎥 Querying cameras...');
_cameras = await availableCameras();
print('🎥 Found ${_cameras.length} cameras');

print('🎥 Initializing controller...');
await _initializeCameraController(0);
print('🎥 Controller initialized: ${_controller?.value.isInitialized}');

// Emit CameraReady immediately after preview success
if (_controller != null && _controller!.value.isInitialized) {
  final infos = _cameras.map(CameraInfo.fromCameraDescription).toList();
  emit(CameraReady(
    controller: _controller!,
    availableCameras: infos,
    currentCameraIndex: _currentCameraIndex,
    isPreviewActive: true,
    isInferenceActive: false,
  ));
  // ML init after preview; errors don’t block camera
  try {
    await _tfliteService.initialize();
    print('🤖 ML initialized (mock or real).');
  } catch (e) {
    print('⚠️ ML init failed: $e (camera continues)');
  }
}

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
      if (_controller != null && _controller!.value.isInitialized) {
        final cameraInfos = _cameras
            .map((camera) => CameraInfo.fromCameraDescription(camera))
            .toList();
            
        emit(CameraReady(
          controller: _controller!,
          availableCameras: cameraInfos,
          currentCameraIndex: _currentCameraIndex,
          isPreviewActive: true,
          isInferenceActive: false,
        ));

        
        // Initialize TensorFlow Lite after camera is ready
        try {
          await _tfliteService.initialize();
          print('✅ Camera and ML initialized successfully');
          
          // Start inference after both are ready
          //add(StartInference()); // Uncomment to auto-start inference
        } catch (e) {
          print('⚠️ ML initialization failed, continuing without: $e');
          // Continue without ML - camera still works
        }
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

  // Always stop a running stream before touching the controller
  try {
    await _controller?.stopImageStream();
  } catch (_) {}
  await _controller?.dispose();
  _controller = null;

  final presets = <ResolutionPreset>[
    ResolutionPreset.medium,
    ResolutionPreset.low,
    ResolutionPreset.high,
  ];

  CameraController? working;
  Object? lastError;

  for (final preset in presets) {
    try {
      final ctrl = CameraController(
        _cameras[cameraIndex],
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      // Guard against hanging initialize() with a timeout
      await ctrl.initialize().timeout(const Duration(seconds: 5));
      working = ctrl;
      break;
    } catch (e) {
      lastError = e;
      try {
        await working?.dispose();
      } catch (_) {}
      working = null;
    }
  }

  // If still not working, try the other camera (front/back)
  if (working == null && _cameras.length > 1) {
    final other = (cameraIndex + 1) % _cameras.length;
    for (final preset in presets) {
      try {
        final ctrl = CameraController(
          _cameras[other],
          preset,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await ctrl.initialize().timeout(const Duration(seconds: 5));
        _currentCameraIndex = other;
        working = ctrl;
        break;
      } catch (e) {
        lastError = e;
        try {
          await working?.dispose();
        } catch (_) {}
        working = null;
      }
    }
  }

  if (working == null) {
    throw StateError('Camera failed to initialize: $lastError');
  }

  _controller = working;
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

  Future<void> _onStartInference(
  StartInference event,
  Emitter<CameraState> emit,
) async {
  if (state is! CameraReady || _controller == null) return;

  // Only start stream if preview is initialized
  if (!_controller!.value.isInitialized) return;

  try {
    // Stop any previous stream defensively
    try { await _controller!.stopImageStream(); } catch (_) {}

    _isInferenceActive = true;
    // Throttle variable reused
    _inferenceTimer?.cancel();
    await _controller!.startImageStream(_onImageStream);

    final s = state as CameraReady;
    emit(s.copyWith(isInferenceActive: true));
  } catch (e) {
    add(HandleCameraError('Failed to start inference: $e'));
  }
}


  Future<void> _onStopInference(
    StopInference event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady || _controller == null) return;
    
    try {
      _isInferenceActive = false;
      _inferenceTimer?.cancel();
      
      await _controller!.stopImageStream();
      
      final currentState = state as CameraReady;
      emit(currentState.copyWith(
        isInferenceActive: false,
        lastPrediction: null,
        lastConfidence: null,
      ));
      
    } catch (e) {
      add(HandleCameraError('Failed to stop inference: $e'));
    }
  }

  void _onImageStream(CameraImage image) {
    // Throttle inference to avoid overwhelming the system
    if (_inferenceTimer?.isActive == true || !_isInferenceActive) return;
    
    _inferenceTimer = Timer(const Duration(milliseconds: 200), () {
      if (_isInferenceActive) {
        add(ProcessCameraFrame(image));
      }
    });
  }

  Future<void> _onProcessCameraFrame(
    ProcessCameraFrame event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady || !_tfliteService.isInitialized) return;
    
    try {
      final result = await _tfliteService.classifyImage(event.image);
      
      // Save image for training data (every 10th prediction to avoid spam)
      String? recognitionId;
      if (DateTime.now().millisecond % 10 == 0) {
        final imageBytes = await _convertCameraImageToBytes(event.image);
        if (imageBytes != null) {
          final imagePath = await _dataRepository.saveImageForTraining(
            imageBytes, 
            result.label,
          );
          
          recognitionId = await _dataRepository.saveRecognition(
            predictedLabel: result.label,
            confidence: result.confidence,
            imagePath: imagePath,
          );
          
          await _dataRepository.saveTrainingData(
            label: result.label,
            imagePath: imagePath,
            source: 'camera',
          );
        }
      }
      
      final currentState = state as CameraReady;
      emit(currentState.copyWith(
        lastPrediction: result.label,
        lastConfidence: result.confidence,
        lastRecognitionId: recognitionId,
      ));
      
    } catch (e) {
      print('❌ Inference error: $e');
    }
  }

  Future<List<int>?> _convertCameraImageToBytes(CameraImage cameraImage) async {
    try {
      // Convert YUV420 to RGB using same method as TfliteService
      final rgbImage = _convertYUV420ToRGB(cameraImage);
      
      // Encode as JPEG
      final jpegBytes = img.encodeJpg(rgbImage, quality: 85);
      return jpegBytes;
    } catch (e) {
      print('⚠️ Image conversion error: $e');
      return null;
    }
  }

  img.Image _convertYUV420ToRGB(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final img.Image rgbImage = img.Image(width: width, height: height);
    
    try {
      final yPlane = cameraImage.planes[0];
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yPlane.bytesPerRow + x;
          if (yIndex < yPlane.bytes.length) {
            final int gray = yPlane.bytes[yIndex];
            rgbImage.setPixelRgb(x, y, gray, gray, gray);
          }
        }
      }
    } catch (e) {
      print('⚠️ YUV conversion error: $e');
    }
    
    return rgbImage;
  }

  Future<void> _onSaveCurrentPrediction(
    SaveCurrentPrediction event,
    Emitter<CameraState> emit,
  ) async {
    if (state is! CameraReady) return;
    
    try {
      final currentState = state as CameraReady;
      emit(currentState.copyWith(isSavingData: true));
      
      await _dataRepository.saveRecognition(
        predictedLabel: event.label,
        confidence: event.confidence,
        userFeedback: 'manually_saved',
      );
      
      emit(currentState.copyWith(isSavingData: false));
      print('✅ Prediction saved manually: ${event.label}');
      
    } catch (e) {
      print('❌ Error saving prediction: $e');
      if (state is CameraReady) {
        final currentState = state as CameraReady;
        emit(currentState.copyWith(isSavingData: false));
      }
    }
  }

  Future<void> _onCorrectPrediction(
    CorrectPrediction event,
    Emitter<CameraState> emit,
  ) async {
    try {
      await _dataRepository.correctRecognition(
        recognitionId: event.recognitionId,
        correctedLabel: event.correctedLabel,
        feedback: event.feedback,
      );
      
      print('✅ Prediction corrected: ${event.originalLabel} -> ${event.correctedLabel}');
      
    } catch (e) {
      print('❌ Error correcting prediction: $e');
    }
  }

  Future<void> _onClearPredictionHistory(
    ClearPredictionHistory event,
    Emitter<CameraState> emit,
  ) async {
    try {
      await _dataRepository.clearOldRecognitions(keepDays: 0);
      print('✅ Prediction history cleared');
    } catch (e) {
      print('❌ Error clearing history: $e');
    }
  }

  

    @override
  Future<void> close() {
    _inferenceTimer?.cancel();
    _controller?.stopImageStream().catchError((_) {});
    _controller?.dispose();
    _tfliteService.dispose();
    return super.close();
  }
}
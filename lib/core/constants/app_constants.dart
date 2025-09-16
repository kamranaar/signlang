class AppConstants {
  // App Info
  static const String appName = 'SignLang';
  static const String appVersion = '0.1.0';
  
  // Camera Settings
  static const int cameraFPS = 30;
  static const int maxCameras = 2;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double buttonHeight = 48.0;
  static const double borderRadius = 8.0;
  
  // Animation Durations
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  
  // Colors (will be used in theme)
  static const int primaryColor = 0xFF2196F3;
  static const int errorColor = 0xFFD32F2F;
  static const int successColor = 0xFF388E3C;
}

class AppStrings {
  // Home Page
  static const String homeTitle = 'SignLang Recognition';
  static const String openCameraButton = 'Open Camera';
  
  // Camera Page
  static const String cameraTitle = 'Camera Preview';
  static const String switchCamera = 'Switch';
  static const String closeCamera = 'Close';
  static const String captureFrame = 'Capture';
  
  // Status Messages
  static const String initializingCamera = 'Initializing camera...';
  static const String cameraReady = 'Camera ready';
  static const String permissionDenied = 'Camera permission denied';
  static const String noCameraFound = 'No camera found';
  static const String cameraError = 'Camera error occurred';
}
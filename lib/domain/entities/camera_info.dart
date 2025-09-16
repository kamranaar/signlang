import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';

class CameraInfo extends Equatable {
  final String id;
  final String name;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;
  
  const CameraInfo({
    required this.id,
    required this.name,
    required this.lensDirection,
    required this.sensorOrientation,
  });
  
  factory CameraInfo.fromCameraDescription(CameraDescription description) {
    return CameraInfo(
      id: description.name,
      name: description.name,
      lensDirection: description.lensDirection,
      sensorOrientation: description.sensorOrientation,
    );
  }
  
  @override
  List<Object> get props => [id, name, lensDirection, sensorOrientation];
}
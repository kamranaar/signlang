import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/camera/camera_bloc.dart';
import '../bloc/camera/camera_event.dart';
import '../bloc/camera/camera_state.dart';
import '../../core/constants/app_constants.dart';

class CameraControlsWidget extends StatelessWidget {
  final VoidCallback? onClose;
  
  const CameraControlsWidget({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
             children: [
              // Switch Camera Button
              if (state is CameraReady && state.availableCameras.length > 1)
                _buildControlButton(
                  icon: Icons.cameraswitch,
                  label: AppStrings.switchCamera,
                  onPressed: () => context.read<CameraBloc>().add(SwitchCamera()),
                ),
              
              // Inference Toggle Button
              if (state is CameraReady)
                _buildControlButton(
                  icon: state.isInferenceActive ? Icons.stop : Icons.play_arrow,
                  label: state.isInferenceActive ? 'Stop AI' : 'Start AI',
                  onPressed: () => context.read<CameraBloc>().add(
                    state.isInferenceActive ? StopInference() : StartInference(),
                  ),
                ),
              
              // Close Button
              _buildControlButton(
                icon: Icons.close,
                label: AppStrings.closeCamera,
                onPressed: onClose,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.9),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
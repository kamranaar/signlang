import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/constants/app_constants.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final bool showOverlay;
  
  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          
          // Overlay for hand detection area (Day 3-4)
          if (showOverlay) _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.8),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Corner indicators
          const Positioned(
            top: 8,
            left: 8,
            child: Icon(Icons.crop_free, color: Colors.greenAccent, size: 24),
          ),
          const Positioned(
            top: 8,
            right: 8,
            child: Icon(Icons.crop_free, color: Colors.greenAccent, size: 24),
          ),
          const Positioned(
            bottom: 8,
            left: 8,
            child: Icon(Icons.crop_free, color: Colors.greenAccent, size: 24),
          ),
          const Positioned(
            bottom: 8,
            right: 8,
            child: Icon(Icons.crop_free, color: Colors.greenAccent, size: 24),
          ),
          
          // Center instruction
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pan_tool,
                  color: Colors.white70,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Position your hand here',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
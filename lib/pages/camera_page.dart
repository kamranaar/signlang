import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../presentation/bloc/camera/camera_bloc.dart';
import '../presentation/bloc/camera/camera_event.dart';
import '../presentation/bloc/camera/camera_state.dart';
import '../presentation/widgets/camera_preview_widget.dart';
import '../presentation/widgets/camera_controls_widget.dart';
import '../presentation/widgets/status_overlay_widget.dart';
import '../core/constants/app_constants.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  @override
  void initState() {
    super.initState();
    // Initialize camera when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraBloc>().add(InitializeCamera());
    });
  }

  @override
  void dispose() {
    // Dispose camera when page closes
    context.read<CameraBloc>().add(DisposeCamera());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(AppStrings.cameraTitle),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<CameraBloc, CameraState>(
        listener: (context, state) {
          // Handle state changes that need user feedback
          if (state is CameraError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Color(AppConstants.errorColor),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Main camera content
              _buildCameraContent(context, state),
              
              // Status overlay
              if (state is CameraLoading)
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: StatusOverlayWidget(
                      message: state.message,
                      icon: Icons.camera_alt,
                    ),
                  ),
                ),
              
              // Controls overlay
              if (state is CameraReady)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: CameraControlsWidget(
                    onClose: () => context.pop(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraContent(BuildContext context, CameraState state) {
    if (state is CameraInitial || state is CameraLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              AppStrings.initializingCamera,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (state is CameraPermissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: 24),
              Text(
                state.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.read<CameraBloc>().add(InitializeCamera()),
                icon: const Icon(Icons.refresh),
                label: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is CameraError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              Text(
                state.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (state.details != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.details!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.read<CameraBloc>().add(InitializeCamera()),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is CameraReady) {
      return Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // Camera info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    state.availableCameras[state.currentCameraIndex].lensDirection == 
                        CameraLensDirection.back
                        ? Icons.camera_rear
                        : Icons.camera_front,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Camera ${state.currentCameraIndex + 1} of ${state.availableCameras.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (state.isPreviewActive)
                    const Row(
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          color: Colors.redAccent,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Camera preview
            Expanded(
              child: CameraPreviewWidget(
                controller: state.controller,
                showOverlay: state.isPreviewActive,
              ),
            ),
            
            const SizedBox(height: 100), // Space for controls
          ],
        ),
      );
    }

    return const Center(
      child: Text(
        'Unknown camera state',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
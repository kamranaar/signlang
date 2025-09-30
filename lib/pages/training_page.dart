import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_constants.dart';
import '../presentation/bloc/training/training_bloc.dart';
import '../presentation/bloc/training/training_event.dart';
import '../presentation/bloc/training/training_state.dart';
import '../services/training_service.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  @override
  void initState() {
    super.initState();
    context.read<TrainingBloc>().add(CheckTrainingReadiness());
    context.read<TrainingBloc>().add(LoadTrainedModelInfo());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Training'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<TrainingBloc, TrainingState>(
        listener: (context, state) {
          if (state is TrainingCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Model training completed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is TrainingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              _buildTrainingStatus(),
              const SizedBox(height: 24),
              _buildModelInfo(),
              const SizedBox(height: 24),
              _buildTrainingControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.model_training, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Model Training',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        'Train a personalized sign language recognition model using your collected data',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingStatus() {
    return BlocBuilder<TrainingBloc, TrainingState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Training Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildStatusContent(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusContent(TrainingState state) {
    if (state is TrainingReadinessChecked) {
      return _buildReadinessStatus(state.progress);
    } else if (state is TrainingInProgress) {
      return _buildProgressStatus(state.progress);
    } else if (state is TrainingCompleted) {
      return _buildCompletedStatus(state.progress);
    } else if (state is TrainingError) {
      return _buildErrorStatus(state.message);
    } else {
      return const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Checking training readiness...'),
        ],
      );
    }
  }

  Widget _buildReadinessStatus(TrainingProgress progress) {
    final isReady = progress.status != TrainingStatus.error;
    final data = progress.data ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isReady ? Icons.check_circle : Icons.error,
              color: isReady ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                progress.message,
                style: TextStyle(
                  color: isReady ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        if (data.isNotEmpty) ...[
          const SizedBox(height: 16),
          if (data['stats'] != null) ...[
            Text(
              'Data Statistics:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...((data['stats'] as Map<String, dynamic>).entries.map((entry) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key.toUpperCase()),
                    Text('${entry.value} samples'),
                  ],
                ),
              ),
            )).toList(),
          ],
        ],
      ],
    );
  }

  Widget _buildProgressStatus(TrainingProgress progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                progress.message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: progress.progress,
          backgroundColor: Colors.grey,
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress.progress * 100).toStringAsFixed(1)}% complete',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        
        if (progress.data != null && progress.data!['epoch'] != null) ...[
          const SizedBox(height: 8),
          Text(
            'Epoch ${progress.data!['epoch']}/${progress.data!['total_epochs']}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedStatus(TrainingProgress progress) {
    final data = progress.data ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.celebration, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                progress.message,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        
        if (data.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['accuracy'] != null)
                  Text('Accuracy: ${(data['accuracy'] * 100).toStringAsFixed(1)}%'),
                if (data['model_size'] != null)
                  Text('Model Size: ${data['model_size']}'),
                if (data['classes'] != null)
                  Text('Classes: ${(data['classes'] as List).length}'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorStatus(String message) {
    return Row(
      children: [
        const Icon(Icons.error, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildModelInfo() {
    return BlocBuilder<TrainingBloc, TrainingState>(
      builder: (context, state) {
        if (state is ModelInfoLoaded && state.hasTrainedModel) {
          return _buildModelInfoCard(state.modelInfo!);
        } else {
          return _buildNoModelCard();
        }
      },
    );
  }

  Widget _buildModelInfoCard(Map<String, dynamic> modelInfo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Trained Model Available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Name: ${modelInfo['name']}'),
            Text('Version: ${modelInfo['version']}'),
            Text('Accuracy: ${(modelInfo['accuracy'] * 100).toStringAsFixed(1)}%'),
            Text('Classes: ${(modelInfo['classes'] as List).length}'),
            Text('Training Samples: ${modelInfo['training_samples']}'),
            Text('Created: ${DateTime.parse(modelInfo['created']).toLocal().toString().split('.')}'),
          ],
        ),
      ),
    );
  }

  Widget _buildNoModelCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.model_training_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No Trained Model',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Train a custom model to improve recognition accuracy',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingControls() {
    return BlocBuilder<TrainingBloc, TrainingState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Training Controls',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTrainingButton(state),
                    ),
                    if (state is TrainingInProgress) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => context.read<TrainingBloc>().add(StopTraining()),
                        child: const Text('Stop'),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.read<TrainingBloc>().add(CheckTrainingReadiness()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Status'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.read<TrainingBloc>().add(ResetTraining()),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrainingButton(TrainingState state) {
    if (state is TrainingInProgress) {
      return ElevatedButton(
        onPressed: null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(_getTrainingButtonText(state)),
          ],
        ),
      );
    }
    
    final canTrain = state is TrainingReadinessChecked && 
                    state.progress.status != TrainingStatus.error;
    
    return ElevatedButton.icon(
      onPressed: canTrain 
          ? () => context.read<TrainingBloc>().add(StartTraining())
          : null,
      icon: const Icon(Icons.play_arrow),
      label: Text(_getTrainingButtonText(state)),
    );
  }

  String _getTrainingButtonText(TrainingState state) {
    if (state is TrainingInProgress) {
      switch (state.progress.status) {
        case TrainingStatus.preprocessing:
          return 'Preprocessing...';
        case TrainingStatus.training:
          return 'Training...';
        case TrainingStatus.evaluating:
          return 'Evaluating...';
        case TrainingStatus.exporting:
          return 'Exporting...';
        default:
          return 'Processing...';
      }
    }
    
    return 'Start Training';
  }
}
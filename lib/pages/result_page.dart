import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../presentation/bloc/history/history_bloc.dart';
import '../presentation/bloc/history/history_event.dart';
import '../presentation/bloc/history/history_state.dart';
import '../data/models/recognition_record.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const LoadHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recognition History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HistoryBloc>().add(RefreshHistory()),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Training Stats'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'export':
                  context.read<HistoryBloc>().add(ExportTrainingData());
                  break;
                case 'stats':
                  _showTrainingStatsDialog();
                  break;
              }
            },
          ),
        ],
      ),
      body: BlocListener<HistoryBloc, HistoryState>(
        listener: (context, state) {
          if (state is TrainingDataExported) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Training data exported successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is HistoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            if (state is HistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is HistoryError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<HistoryBloc>().add(RefreshHistory()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is HistoryLoaded) {
              return _buildHistoryContent(state);
            }
            
            return const Center(child: Text('Loading history...'));
          },
        ),
      ),
    );
  }

  Widget _buildHistoryContent(HistoryLoaded state) {
    if (state.recognitions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recognition history yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start using the camera to build your history',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Training Stats Summary
        if (state.totalSamples > 0)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.data_usage, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Training Data Collected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${state.totalSamples} samples across ${state.trainingStats.length} labels',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showTrainingStatsDialog,
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        
        // Recognition History List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.recognitions.length,
            itemBuilder: (context, index) {
              final record = state.recognitions[index];
              return _buildHistoryItem(record);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(RecognitionRecord record) {
    final isCorrect = record.correctedLabel == null;
    final displayLabel = record.correctedLabel ?? record.predictedLabel;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCorrect ? Colors.green : Colors.orange,
          child: Icon(
            isCorrect ? Icons.check : Icons.edit,
            color: Colors.white,
          ),
        ),
        title: Text(
          displayLabel.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence: ${(record.confidence * 100).toStringAsFixed(1)}%',
            ),
            if (!isCorrect)
              Text(
                'Originally: ${record.predictedLabel}',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            Text(
              DateFormat('MMM dd, yyyy HH:mm').format(record.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: record.imagePath != null
            ? const Icon(Icons.image, color: Colors.blue)
            : null,
        onTap: record.userFeedback != null
            ? () => _showFeedbackDialog(record)
            : null,
      ),
    );
  }

  void _showTrainingStatsDialog() {
    context.read<HistoryBloc>().add(LoadTrainingStats());
    
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is! HistoryLoaded) {
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading training stats...'),
                ],
              ),
            );
          }
          
          return AlertDialog(
            title: const Text('Training Data Statistics'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total Samples: ${state.totalSamples}'),
                  const SizedBox(height: 16),
                  const Text('Samples per Label:', 
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...state.trainingStats.entries.map((entry) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key.toUpperCase()),
                          Text('${entry.value} samples'),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFeedbackDialog(RecognitionRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recognition: ${record.predictedLabel.toUpperCase()}'),
            if (record.correctedLabel != null)
              Text('Corrected to: ${record.correctedLabel!.toUpperCase()}'),
            const SizedBox(height: 16),
            const Text('Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(record.userFeedback ?? 'No feedback provided'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
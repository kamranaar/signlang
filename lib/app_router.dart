import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection_container.dart';
import 'presentation/bloc/camera/camera_bloc.dart';
import 'pages/home_page.dart';
import 'pages/camera_page.dart';
import 'pages/result_page.dart';
import 'presentation/bloc/history/history_bloc.dart';
import 'pages/training_page.dart';
import '../presentation/bloc/training/training_bloc.dart';



final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/camera',
      name: 'camera',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<CameraBloc>(),
        child: const CameraPage(),
      ),
    ),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<HistoryBloc>(),
        child: const HistoryPage(),
      ),
    ),
    GoRoute(
      path: '/training',
      name: 'training',
      builder: (context, state) => BlocProvider(
        create: (context) => sl<TrainingBloc>(),
        child: const TrainingPage(),
      ),
    ),
  ],
);
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'bloc_observer.dart'; // i commented this out for now as this is giving error
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup BLoC observer for debugging
  Bloc.observer = SimpleBlocObserver(); // Uncomment if BlocObserver is defined
  
  // Setup dependency injection
  await setupDependencyInjection();
  
  runApp(const SignLangApp());
}

class SignLangApp extends StatelessWidget {
  const SignLangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SignLang',
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}
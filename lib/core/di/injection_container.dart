import 'package:get_it/get_it.dart';
import '../../presentation/bloc/camera/camera_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // BLoCs
  sl.registerFactory(() => CameraBloc());
  
  // Future: Add ML services, repositories, etc.
}
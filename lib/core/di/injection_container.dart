import 'package:get_it/get_it.dart';
import '../../presentation/bloc/camera/camera_bloc.dart';
import '../../services/tflite_service.dart';

final sl = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Services
  sl.registerLazySingleton<TfliteService>(() => TfliteService());
  
  // BLoCs
  sl.registerFactory(() => CameraBloc(sl<TfliteService>()));
}
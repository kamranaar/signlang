import 'package:get_it/get_it.dart';
import '../../presentation/bloc/camera/camera_bloc.dart';
import '../../services/tflite_service.dart';
import '../../data/repositories/data_repository.dart';
import '../../presentation/bloc/history/history_bloc.dart';
import '../../services/training_service.dart';
import '../../presentation/bloc/training/training_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Services
  sl.registerLazySingleton<TfliteService>(() => TfliteService());
  sl.registerLazySingleton<DataRepository>(() => DataRepository()); 
  sl.registerLazySingleton<TrainingService>(() => TrainingService()); 
  
  // BLoCs
  sl.registerFactory(() => CameraBloc(sl<TfliteService>()));
  sl.registerFactory(() => HistoryBloc()); 
  sl.registerFactory(() => TrainingBloc());   
}
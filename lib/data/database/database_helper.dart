import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'sign_language.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Recognition History table
    await db.execute('''
      CREATE TABLE recognitions(
        id TEXT PRIMARY KEY,
        predicted_label TEXT NOT NULL,
        confidence REAL NOT NULL,
        corrected_label TEXT,
        is_correct INTEGER DEFAULT 1,
        image_path TEXT,
        timestamp INTEGER NOT NULL,
        user_feedback TEXT
      )
    ''');

    // Training Data table
    await db.execute('''
      CREATE TABLE training_data(
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        image_path TEXT NOT NULL,
        source TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_validated INTEGER DEFAULT 0
      )
    ''');

    // User Settings table
    await db.execute('''
      CREATE TABLE user_settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    print('✅ Database tables created successfully');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'sign_language.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
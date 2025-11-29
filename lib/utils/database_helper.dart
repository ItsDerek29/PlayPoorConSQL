import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/audio_item.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'playoor.db');
    debugPrint("Database path: $path");
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE audioitem(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assetPath TEXT,
        title TEXT,
        artist TEXT,
        imagePath TEXT
      )
    ''');
  }

  Future<void> insertAudioItem(AudioItem item) async {
    final db = await database;
    await db.insert(
      'audioitem',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AudioItem>> getAudioItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('audioitem');
    return List.generate(maps.length, (i) {
      return AudioItem.fromMap(maps[i]);
    });
  }

  Future<int> getAudioItemsCount() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM audioitem')) ?? 0;
  }

  Future<void> updateAudioItem(AudioItem item) async {
    final db = await database;
    await db.update(
      'audioitem',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteAudioItem(int id) async {
    final db = await database;
    await db.delete(
      'audioitem',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<void> deleteLastAudioItem() async {
    final db = await database;
    // Get the max ID
    final result = await db.rawQuery('SELECT MAX(id) as id FROM audioitem');
    final id = result.first['id'] as int?;
    if (id != null) {
      await deleteAudioItem(id);
    }
  }
}

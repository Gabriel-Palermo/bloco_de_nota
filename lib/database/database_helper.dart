import 'package:bloco_de_nota/models/note.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Future<Database>? _databaseFuture;

  DatabaseHelper._init();

  Future<Database> get database async {
    _databaseFuture ??= _initDB('notes.db');

    try {
      return await _databaseFuture!;
    } catch (e) {
      _databaseFuture = null;
      rethrow;
    }
  }

  Future<Database> _initDB(String fileName) async {
    if (kIsWeb) {
      return openDatabase(
        fileName,
        version: 5,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL,
        cloudId TEXT,
        category TEXT NOT NULL DEFAULT 'Pessoal',
        isArchived INTEGER NOT NULL DEFAULT 0,
        pendingSync INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_deletions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        cloudId TEXT NOT NULL,
        UNIQUE(uid, cloudId)
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE notes ADD COLUMN cloudId TEXT');
    }

    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE notes ADD COLUMN category TEXT NOT NULL DEFAULT 'Pessoal'",
      );
    }

    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN isArchived INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN pendingSync INTEGER NOT NULL DEFAULT 0',
      );

      await db.execute('''
        CREATE TABLE pending_deletions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT NOT NULL,
          cloudId TEXT NOT NULL,
          UNIQUE(uid, cloudId)
        )
      ''');
    }
  }

  // Inserir nota local
  Future<int> insertNote(Note note) async {
    final db = await database;

    final data = note.toMap();
    data.remove('id');

    return db.insert('notes', data);
  }

  // Buscar notas de um usuário
  Future<List<Note>> getNotes(String uid) async {
    final db = await database;

    final result = await db.query(
      'notes',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'id DESC',
    );

    return result.map((map) => Note.fromMap(map)).toList();
  }

  // Buscar notas pendentes de sincronização
  Future<List<Note>> getPendingNotes(String uid) async {
    final db = await database;

    final result = await db.query(
      'notes',
      where: 'uid = ? AND pendingSync = 1',
      whereArgs: [uid],
      orderBy: 'id ASC',
    );

    return result.map((map) => Note.fromMap(map)).toList();
  }

  // Atualizar nota local e marcar sincronização pendente
  Future<int> updateNote(Note note) async {
    final db = await database;

    final data = note.toMap();
    data['pendingSync'] = 1;

    return db.update('notes', data, where: 'id = ?', whereArgs: [note.id]);
  }

  // Atualizar identificador do Firestore
  Future<int> updateCloudId(int id, String cloudId) async {
    final db = await database;

    return db.update(
      'notes',
      {'cloudId': cloudId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Marcar nota como sincronizada
  Future<int> markNoteSynced(int id, String cloudId) async {
    final db = await database;

    return db.update(
      'notes',
      {'cloudId': cloudId, 'pendingSync': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Salvar ou atualizar nota recebida do Firestore
  Future<int> saveCloudNote(Note note) async {
    final db = await database;

    final existing = await db.query(
      'notes',
      where: 'uid = ? AND cloudId = ?',
      whereArgs: [note.uid, note.cloudId],
      limit: 1,
    );

    final data = note.toMap();
    data.remove('id');
    data['pendingSync'] = 0;

    if (existing.isNotEmpty) {
      // Não sobrescrever alterações locais ainda não sincronizadas.
      if ((existing.first['pendingSync'] as int? ?? 0) == 1) {
        return 0;
      }

      return db.update(
        'notes',
        data,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }

    return db.insert('notes', data);
  }

  // Registrar exclusão pendente
  Future<void> addPendingDeletion(String uid, String cloudId) async {
    final db = await database;

    await db.insert('pending_deletions', {
      'uid': uid,
      'cloudId': cloudId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // Consultar exclusões pendentes
  Future<List<Map<String, dynamic>>> getPendingDeletions(String uid) async {
    final db = await database;

    return db.query('pending_deletions', where: 'uid = ?', whereArgs: [uid]);
  }

  // Remover exclusão da fila após sincronização
  Future<int> removePendingDeletion(int id) async {
    final db = await database;

    return db.delete('pending_deletions', where: 'id = ?', whereArgs: [id]);
  }

  // Excluir nota local
  Future<int> deleteNote(int id) async {
    final db = await database;

    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // Excluir nota pelo identificador do Firestore
  Future<int> deleteNoteByCloudId(String cloudId) async {
    final db = await database;

    return db.delete('notes', where: 'cloudId = ?', whereArgs: [cloudId]);
  }
}

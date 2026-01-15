import 'package:roof_claim_progress_tracker_sqlite/models/claim.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('claims.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE claims (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        homeownerName TEXT NOT NULL,
        address TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        insuranceCompany TEXT NOT NULL,
        claimNumber TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertClaim(Claim claim) async {
    final db = await database;
    return await db.insert('claims', claim.toMap());
  }

  Future<List<Claim>> getAllClaims() async {
    final db = await database;
    final result = await db.query('claims', orderBy: 'updatedAt DESC');
    return result.map((map) => Claim.fromMap(map)).toList();
  }

  Future<Claim?> getClaim(int id) async {
    final db = await database;
    final result = await db.query('claims', where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return Claim.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateClaim(Claim claim) async {
    final db = await database;
    return await db.update(
      'claims',
      claim.toMap(),
      where: 'id = ?',
      whereArgs: [claim.id],
    );
  }

  Future<int> deleteClaim(int id) async {
    final db = await database;
    return await db.delete('claims', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Claim>> getClaimsByStatus(String status) async {
    final db = await database;
    final result = await db.query(
      'claims',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => Claim.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

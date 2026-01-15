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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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
        updatedAt TEXT NOT NULL,
        supabaseId TEXT,
        isSynced INTEGER DEFAULT 0,
        needsSync INTEGER DEFAULT 1,
        deleted INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE claims ADD COLUMN supabaseId TEXT
      ''');
      await db.execute('''
        ALTER TABLE claims ADD COLUMN isSynced INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE claims ADD COLUMN needsSync INTEGER DEFAULT 1
      ''');
      await db.execute('''
        ALTER TABLE claims ADD COLUMN deleted INTEGER DEFAULT 0
      ''');
    }
  }

  Future<int> insertClaim(Claim claim) async {
    final db = await database;
    final map = claim.toMap();
    // Add sync tracking fields
    map['isSynced'] = 0;
    map['needsSync'] = 1;
    map['deleted'] = 0;
    map['supabaseId'] = null;
    return await db.insert('claims', map);
  }

  Future<List<Claim>> getAllClaims() async {
    final db = await database;
    final result = await db.query(
      'claims',
      where: 'deleted = 0',
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => Claim.fromMap(map)).toList();
  }

  Future<Claim?> getClaim(int id) async {
    final db = await database;
    final result = await db.query(
      'claims',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Claim.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateClaim(Claim claim) async {
    final db = await database;
    final map = claim.toMap();
    // Preserve sync fields and mark as needing sync
    final existing = await db.query(
      'claims',
      columns: ['supabaseId', 'isSynced'],
      where: 'id = ?',
      whereArgs: [claim.id],
    );
    if (existing.isNotEmpty) {
      map['supabaseId'] = existing.first['supabaseId'];
      // If it was synced before, mark as needing sync again
      if (existing.first['isSynced'] == 1) {
        map['needsSync'] = 1;
      }
    }
    return await db.update(
      'claims',
      map,
      where: 'id = ?',
      whereArgs: [claim.id],
    );
  }

  Future<int> deleteClaim(int id) async {
    final db = await database;
    // Soft delete - mark as deleted and needs sync
    return await db.update(
      'claims',
      {'deleted': 1, 'needsSync': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Claim>> getClaimsByStatus(String status) async {
    final db = await database;
    final result = await db.query(
      'claims',
      where: 'status = ? AND deleted = 0',
      whereArgs: [status],
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => Claim.fromMap(map)).toList();
  }

  // Get claims that need to be synced
  Future<List<Claim>> getClaimsNeedingSync() async {
    final db = await database;
    final result = await db.query(
      'claims',
      where: 'needsSync = 1 AND deleted = 0',
      orderBy: 'updatedAt ASC',
    );
    return result.map((map) => Claim.fromMap(map)).toList();
  }

  // Get deleted claims that need to be synced
  Future<List<Claim>> getDeletedClaimsNeedingSync() async {
    final db = await database;
    final result = await db.query(
      'claims',
      where: 'deleted = 1 AND needsSync = 1',
      orderBy: 'updatedAt ASC',
    );
    return result.map((map) => Claim.fromMap(map)).toList();
  }

  // Mark claim as synced
  Future<void> markClaimAsSynced(int id, String? supabaseId) async {
    final db = await database;
    await db.update(
      'claims',
      {
        'isSynced': 1,
        'needsSync': 0,
        'supabaseId': supabaseId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update claim's sync status
  Future<void> updateClaimSyncStatus(int id, bool needsSync) async {
    final db = await database;
    await db.update(
      'claims',
      {'needsSync': needsSync ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark claim as deleted (soft delete)
  Future<void> markClaimAsDeleted(int id) async {
    final db = await database;
    await db.update(
      'claims',
      {'deleted': 1, 'needsSync': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get claim by Supabase ID
  Future<Claim?> getClaimBySupabaseId(String supabaseId) async {
    final db = await database;
    final result = await db.query(
      'claims',
      where: 'supabaseId = ?',
      whereArgs: [supabaseId],
    );

    if (result.isNotEmpty) {
      return Claim.fromMap(result.first);
    }
    return null;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

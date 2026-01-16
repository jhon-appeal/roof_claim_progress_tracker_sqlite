import 'package:roof_claim_progress_tracker_sqlite/shared/models/project_model.dart';
import 'package:roof_claim_progress_tracker_sqlite/shared/models/milestone_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('projects.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Projects table
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        address TEXT NOT NULL,
        homeownerId TEXT,
        roofingCompanyId TEXT,
        assessDirectId TEXT,
        status TEXT NOT NULL,
        createdAt TEXT,
        updatedAt TEXT,
        supabaseId TEXT,
        isSynced INTEGER DEFAULT 0,
        needsSync INTEGER DEFAULT 1,
        deleted INTEGER DEFAULT 0
      )
    ''');

    // Milestones table
    await db.execute('''
      CREATE TABLE milestones (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        dueDate TEXT,
        completedAt TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        supabaseId TEXT,
        isSynced INTEGER DEFAULT 0,
        needsSync INTEGER DEFAULT 1,
        deleted INTEGER DEFAULT 0,
        FOREIGN KEY (projectId) REFERENCES projects(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Drop old claims table if exists
      try {
        await db.execute('DROP TABLE IF EXISTS claims');
      } catch (e) {
        // Table might not exist
      }

      // Create projects table if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS projects (
          id TEXT PRIMARY KEY,
          address TEXT NOT NULL,
          homeownerId TEXT,
          roofingCompanyId TEXT,
          assessDirectId TEXT,
          status TEXT NOT NULL,
          createdAt TEXT,
          updatedAt TEXT,
          supabaseId TEXT,
          isSynced INTEGER DEFAULT 0,
          needsSync INTEGER DEFAULT 1,
          deleted INTEGER DEFAULT 0
        )
      ''');

      // Create milestones table if not exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS milestones (
          id TEXT PRIMARY KEY,
          projectId TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          status TEXT NOT NULL,
          dueDate TEXT,
          completedAt TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          supabaseId TEXT,
          isSynced INTEGER DEFAULT 0,
          needsSync INTEGER DEFAULT 1,
          deleted INTEGER DEFAULT 0,
          FOREIGN KEY (projectId) REFERENCES projects(id)
        )
      ''');
    }
  }

  // Projects CRUD operations
  Future<int> insertProject(ProjectModel project, {bool needsSync = true}) async {
    final db = await database;
    final map = project.toJson();
    map['supabaseId'] = project.id; // Use project id as supabase id initially
    map['isSynced'] = 0;
    map['needsSync'] = needsSync ? 1 : 0;
    map['deleted'] = 0;
    return await db.insert('projects', map);
  }

  Future<List<ProjectModel>> getAllProjects() async {
    final db = await database;
    final result = await db.query(
      'projects',
      where: 'deleted = 0',
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => ProjectModel.fromJson(_convertProjectMap(map))).toList();
  }

  Future<ProjectModel?> getProject(String id) async {
    final db = await database;
    final result = await db.query(
      'projects',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return ProjectModel.fromJson(_convertProjectMap(result.first));
    }
    return null;
  }

  Future<ProjectModel?> getProjectBySupabaseId(String supabaseId) async {
    final db = await database;
    final result = await db.query(
      'projects',
      where: 'supabaseId = ?',
      whereArgs: [supabaseId],
    );

    if (result.isNotEmpty) {
      return ProjectModel.fromJson(_convertProjectMap(result.first));
    }
    return null;
  }

  Future<int> updateProject(ProjectModel project) async {
    final db = await database;
    final map = project.toJson();
    // Preserve sync fields
    final existing = await db.query(
      'projects',
      columns: ['supabaseId', 'isSynced'],
      where: 'id = ?',
      whereArgs: [project.id],
    );
    if (existing.isNotEmpty) {
      map['supabaseId'] = existing.first['supabaseId'] ?? project.id;
      map['isSynced'] = existing.first['isSynced'] ?? 0;
      // Always mark as needing sync when updated (unless it's a local-only project)
      map['needsSync'] = 1;
    } else {
      map['supabaseId'] = project.id;
      map['isSynced'] = 0;
      map['needsSync'] = 1;
    }
    map['deleted'] = 0;
    return await db.update(
      'projects',
      map,
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(String id) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'projects',
      {'deleted': 1, 'needsSync': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ProjectModel>> getProjectsNeedingSync() async {
    final db = await database;
    final result = await db.query(
      'projects',
      where: 'needsSync = 1 AND deleted = 0',
      orderBy: 'updatedAt ASC',
    );
    return result.map((map) => ProjectModel.fromJson(_convertProjectMap(map))).toList();
  }

  Future<List<ProjectModel>> getDeletedProjectsNeedingSync() async {
    final db = await database;
    final result = await db.query(
      'projects',
      where: 'deleted = 1 AND needsSync = 1',
      orderBy: 'updatedAt ASC',
    );
    return result.map((map) => ProjectModel.fromJson(_convertProjectMap(map))).toList();
  }

  Future<void> markProjectAsSynced(String id, String? supabaseId) async {
    final db = await database;
    await db.update(
      'projects',
      {
        'isSynced': 1,
        'needsSync': 0,
        'supabaseId': supabaseId ?? id,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Milestones CRUD operations
  Future<int> insertMilestone(MilestoneModel milestone, {bool needsSync = true}) async {
    final db = await database;
    final map = milestone.toJson();
    map['supabaseId'] = milestone.id;
    map['isSynced'] = 0;
    map['needsSync'] = needsSync ? 1 : 0;
    map['deleted'] = 0;
    return await db.insert('milestones', map);
  }

  Future<List<MilestoneModel>> getAllMilestones() async {
    final db = await database;
    final result = await db.query(
      'milestones',
      where: 'deleted = 0',
      orderBy: 'createdAt ASC',
    );
    return result.map((map) => MilestoneModel.fromJson(_convertMilestoneMap(map))).toList();
  }

  Future<List<MilestoneModel>> getMilestonesByProject(String projectId) async {
    final db = await database;
    final result = await db.query(
      'milestones',
      where: 'projectId = ? AND deleted = 0',
      whereArgs: [projectId],
      orderBy: 'createdAt ASC',
    );
    return result.map((map) => MilestoneModel.fromJson(_convertMilestoneMap(map))).toList();
  }

  Future<MilestoneModel?> getMilestone(String id) async {
    final db = await database;
    final result = await db.query(
      'milestones',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return MilestoneModel.fromJson(_convertMilestoneMap(result.first));
    }
    return null;
  }

  Future<MilestoneModel?> getMilestoneBySupabaseId(String supabaseId) async {
    final db = await database;
    final result = await db.query(
      'milestones',
      where: 'supabaseId = ?',
      whereArgs: [supabaseId],
    );

    if (result.isNotEmpty) {
      return MilestoneModel.fromJson(_convertMilestoneMap(result.first));
    }
    return null;
  }

  Future<int> updateMilestone(MilestoneModel milestone) async {
    final db = await database;
    final map = milestone.toJson();
    // Preserve sync fields
    final existing = await db.query(
      'milestones',
      columns: ['supabaseId', 'isSynced'],
      where: 'id = ?',
      whereArgs: [milestone.id],
    );
    if (existing.isNotEmpty) {
      map['supabaseId'] = existing.first['supabaseId'] ?? milestone.id;
      if (existing.first['isSynced'] == 1) {
        map['needsSync'] = 1;
      }
    } else {
      map['supabaseId'] = milestone.id;
      map['needsSync'] = 1;
    }
    map['isSynced'] = existing.isNotEmpty ? existing.first['isSynced'] : 0;
    map['deleted'] = 0;
    return await db.update(
      'milestones',
      map,
      where: 'id = ?',
      whereArgs: [milestone.id],
    );
  }

  Future<int> deleteMilestone(String id) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'milestones',
      {'deleted': 1, 'needsSync': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MilestoneModel>> getMilestonesNeedingSync() async {
    final db = await database;
    final result = await db.query(
      'milestones',
      where: 'needsSync = 1 AND deleted = 0',
      orderBy: 'updatedAt ASC',
    );
    return result.map((map) => MilestoneModel.fromJson(_convertMilestoneMap(map))).toList();
  }

  Future<List<MilestoneModel>> getDeletedMilestonesNeedingSync() async {
    final db = await database;
    final result = await db.query(
      'milestones',
      where: 'deleted = 1 AND needsSync = 1',
      orderBy: 'updatedAt ASC',
    );
    return result.map((map) => MilestoneModel.fromJson(_convertMilestoneMap(map))).toList();
  }

  Future<void> markMilestoneAsSynced(String id, String? supabaseId) async {
    final db = await database;
    await db.update(
      'milestones',
      {
        'isSynced': 1,
        'needsSync': 0,
        'supabaseId': supabaseId ?? id,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Helper methods to convert database maps to JSON format
  Map<String, dynamic> _convertProjectMap(Map<String, dynamic> map) {
    return {
      'id': map['id'] as String,
      'address': map['address'] as String,
      'homeowner_id': map['homeownerId'] as String?,
      'roofing_company_id': map['roofingCompanyId'] as String?,
      'assess_direct_id': map['assessDirectId'] as String?,
      'status': map['status'] as String? ?? 'pending',
      'created_at': map['createdAt'] as String?,
      'updated_at': map['updatedAt'] as String?,
    };
  }

  Map<String, dynamic> _convertMilestoneMap(Map<String, dynamic> map) {
    return {
      'id': map['id'] as String,
      'project_id': map['projectId'] as String,
      'name': map['name'] as String,
      'description': map['description'] as String?,
      'status': map['status'] as String? ?? 'pending',
      'due_date': map['dueDate'] as String?,
      'completed_at': map['completedAt'] as String?,
      'created_at': map['createdAt'] as String?,
      'updated_at': map['updatedAt'] as String?,
    };
  }

  // Check if database is empty (fresh install)
  Future<bool> isEmpty() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM projects WHERE deleted = 0',
    );
    final count = result.first['count'] as int? ?? 0;
    return count == 0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

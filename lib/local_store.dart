import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalStore {
  static Database? _database;
  static bool _factoryConfigured = false;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isLinux) {
      _configureDatabaseFactory();
    }
    await _db;
  }

  static Future<Database> get _db async {
    _configureDatabaseFactory();
    if (_database != null) return _database!;
    final directory = await getDatabasesPath();
    _database = await openDatabase(
      '$directory/litha.db',
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE records (
            kind TEXT NOT NULL,
            id INTEGER NOT NULL,
            data TEXT NOT NULL,
            PRIMARY KEY (kind, id)
          )
        ''');
      },
    );
    return _database!;
  }

  static void _configureDatabaseFactory() {
    if (_factoryConfigured ||
        (!Platform.isWindows && !Platform.isLinux)) {
      return;
    }
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _factoryConfigured = true;
  }

  static Future<List<Map<String, dynamic>>> getAll(String route) async {
    if (kIsWeb) return _webGetAll(route);
    final parts = route.split('?');
    final rows = await (await _db).query(
      'records',
      where: 'kind = ?',
      whereArgs: [parts.first],
      orderBy: 'id ASC',
    );
    var records = rows
        .map((row) =>
            Map<String, dynamic>.from(jsonDecode(row['data'] as String))
              ..['id'] = row['id'])
        .toList();

    if (parts.length > 1) {
      final parameters = Uri.splitQueryString(parts.last);
      final stoneId = parameters['stoneId'];
      if (stoneId != null) {
        records = records
            .where((record) => record['stoneId']?.toString() == stoneId)
            .toList();
      }
    }
    return records;
  }

  static Future<Map<String, dynamic>> save(
      String kind, Map<String, dynamic> value,
      {int? id}) async {
    if (kIsWeb) return _webSave(kind, value, id: id);
    final database = await _db;
    return database.transaction((transaction) async {
      final recordId = id ?? await _nextId(transaction, kind);
      final existing = await transaction.query(
        'records',
        columns: ['data'],
        where: 'kind = ? AND id = ?',
        whereArgs: [kind, recordId],
      );
      final record = existing.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(
              jsonDecode(existing.first['data'] as String));
      record.addAll(value);
      record.remove('id');
      _addRelationIds(record);

      await transaction.insert(
        'records',
        {'kind': kind, 'id': recordId, 'data': jsonEncode(record)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return Map<String, dynamic>.from(record)..['id'] = recordId;
    });
  }

  static Future<void> remove(String kind, dynamic id) async {
    if (kIsWeb) {
      await _webRemove(kind, id);
      return;
    }
    final recordId = _asInt(id);
    if (recordId == null) return;
    final database = await _db;
    await database.transaction((transaction) async {
      await transaction.delete('records',
          where: 'kind = ? AND id = ?', whereArgs: [kind, recordId]);
      if (kind == 'stones') {
        await _deleteForStone(transaction, 'memories', recordId);
        await _deleteForStone(transaction, 'stone-photos', recordId);
      }
    });
  }

  static Future<String> copyPhoto(XFile file) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final extension = _extension(file.name).replaceFirst('.', '');
      return 'data:image/$extension;base64,${base64Encode(bytes)}';
    }
    final documents = await getApplicationDocumentsDirectory();
    final photos =
        Directory('${documents.path}${Platform.pathSeparator}photos');
    await photos.create(recursive: true);
    final extension = _extension(file.name);
    final destination = File(
        '${photos.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}$extension');
    await File(file.path).copy(destination.path);
    return destination.path;
  }

  static Future<int> _nextId(Transaction transaction, String kind) async {
    final result = await transaction.rawQuery(
        'SELECT COALESCE(MAX(id), 0) + 1 AS nextId FROM records WHERE kind = ?',
        [kind]);
    return (result.first['nextId'] as num).toInt();
  }

  static Future<void> _deleteForStone(
      Transaction transaction, String kind, int stoneId) async {
    final rows = await transaction.query('records',
        columns: ['id', 'data'], where: 'kind = ?', whereArgs: [kind]);
    for (final row in rows) {
      final record = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      if (_asInt(record['stoneId']) == stoneId) {
        await transaction.delete('records',
            where: 'kind = ? AND id = ?', whereArgs: [kind, row['id']]);
      }
    }
  }

  static Future<List<Map<String, dynamic>>> _webGetAll(String route) async {
    final parts = route.split('?');
    var records = await _webLoad(parts.first);
    if (parts.length > 1) {
      final stoneId = Uri.splitQueryString(parts.last)['stoneId'];
      if (stoneId != null) {
        records = records
            .where((record) => record['stoneId']?.toString() == stoneId)
            .toList();
      }
    }
    return records;
  }

  static Future<Map<String, dynamic>> _webSave(String kind,
      Map<String, dynamic> value, {int? id}) async {
    final records = await _webLoad(kind);
    final recordId = id ??
        records.fold<int>(0, (maximum, record) {
          final current = _asInt(record['id']) ?? 0;
          return current > maximum ? current : maximum;
        }) +
            1;
    final index = records.indexWhere((record) => record['id'] == recordId);
    final record = index == -1
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(records[index]);
    record.addAll(value);
    record['id'] = recordId;
    _addRelationIds(record);
    if (index == -1) {
      records.add(record);
    } else {
      records[index] = record;
    }
    await _webSaveRecords(kind, records);
    return record;
  }

  static Future<void> _webRemove(String kind, dynamic id) async {
    final recordId = _asInt(id);
    if (recordId == null) return;
    final records = await _webLoad(kind);
    records.removeWhere((record) => record['id'] == recordId);
    await _webSaveRecords(kind, records);
    if (kind == 'stones') {
      await _webRemoveForStone('memories', recordId);
      await _webRemoveForStone('stone-photos', recordId);
    }
  }

  static Future<void> _webRemoveForStone(String kind, int stoneId) async {
    final records = await _webLoad(kind);
    records.removeWhere((record) => _asInt(record['stoneId']) == stoneId);
    await _webSaveRecords(kind, records);
  }

  static Future<List<Map<String, dynamic>>> _webLoad(String kind) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('litha_$kind');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((record) => Map<String, dynamic>.from(record as Map))
        .toList();
  }

  static Future<void> _webSaveRecords(
      String kind, List<Map<String, dynamic>> records) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('litha_$kind', jsonEncode(records));
  }

  static void _addRelationIds(Map<String, dynamic> record) {
    final stone = record['stone'];
    if (stone is Map) record['stoneId'] = stone['id'];
  }

  static int? _asInt(dynamic value) => value is int
      ? value
      : value is num
          ? value.toInt()
          : int.tryParse('$value');

  static String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '.jpg' : name.substring(dot);
  }
}

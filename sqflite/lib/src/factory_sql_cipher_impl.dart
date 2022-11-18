import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common/src/exception.dart'; // ignore: implementation_imports
import 'package:sqflite_sqlcipher/src/database_sql_cipher_impl.dart';

import 'sqflite_import.dart';
import 'sqflite_sql_cipher_impl.dart';

/// Platform error constant
const String sqliteErrorCode = "sqlite_error";

DatabaseFactory? _databaseFactory;

/// Default factory
DatabaseFactory get databaseFactory => sqlfliteSqlCipherDatabaseFactory;

/// Change the default factory.
///
/// Be aware of the potential side effect. Any library using sqflite_sqlcipher
/// will have this factory as the default for all operations.
///
/// This setter must be call only once, before any other calls to
/// sqflite_sqlcipher.
set databaseFactory(DatabaseFactory? databaseFactory) {
  // Warn when changing. might throw in the future
  if (databaseFactory != null) {
    if (_databaseFactory != null) {
      stderr.writeln('''
*** sqflite warning ***
You are changing sqflite default factory.
Be aware of the potential side effects. Any library using sqflite
will have this factory as the default for all operations.
*** sqflite warning ***
''');
    }
    _databaseFactory = databaseFactory;
  } else {
    /// Will use the default factory
    _databaseFactory = null;
  }
}

/// Default factory
DatabaseFactory get sqlfliteSqlCipherDatabaseFactory =>
    _databaseFactory ??= SqfliteSqlCipherDatabaseFactoryImpl(invokeMethod);

/// Factory implementation.
class SqfliteSqlCipherDatabaseFactoryImpl
    with SqfliteDatabaseFactoryMixin
    implements SqfliteInvokeHandler {
  /// Factory ctor.
  SqfliteSqlCipherDatabaseFactoryImpl(this._invokeMethod);

  final Future<dynamic> Function(String method, [dynamic arguments])
      _invokeMethod;

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) async =>
      (await _invokeMethod(method, arguments)) as T;

  @override
  Future<T> wrapDatabaseException<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      return result;
    } on PlatformException catch (e) {
      if (e.code == sqliteErrorCode) {
        throw SqfliteDatabaseException(e.message, e.details);
        //rethrow;
      } else {
        rethrow;
      }
    }
  }

  @override
  SqfliteDatabase newDatabase(
      SqfliteDatabaseOpenHelper openHelper, String path) {
    return SqfileSqlCipherDatabaseImpl(openHelper, path);
  }

  /// Optimized but could be removed
  @override
  Future<bool> databaseExists(String path) async {
    path = await fixPath(path);
    try {
      // avoid slow async method
      return File(path).existsSync();
    } catch (_) {}
    return false;
  }
}

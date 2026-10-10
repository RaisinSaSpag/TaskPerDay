import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final DatabaseService _databaseService = DatabaseService.instance;

  // ═══════════════════════════════════════════════════════════
  // REGISTER
  // ═══════════════════════════════════════════════════════════
  Future<AppUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final db = await _databaseService.database;
    final salt = _newSalt();
    try {
      final id = await db.insert('users', {
        'email': normalizedEmail,
        'password_hash': '$salt:${_hash(password, salt)}',
        'full_name': fullName.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      final user = await _getUserById(id);
      await _saveSession(user.id);
      return user;
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const AuthException('An account with this email already exists.');
      }
      debugPrint('Registration database error: $error');
      rethrow;
    } catch (error) {
      debugPrint('Registration error: $error');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LOGIN (with debug logging)
  // ═══════════════════════════════════════════════════════════
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final db = await _databaseService.database;
    try {
      debugPrint('═══════════════════════════════════');
      debugPrint('🔵 LOGIN ATTEMPT');
      debugPrint('   Email input:    "$email"');
      debugPrint('   Password input: "$password"');
      debugPrint('   Trimmed email:  "${email.trim()}"');

      // Step 1: Find user by email
      final rows = await db.query(
        'users',
        where: 'email = ? COLLATE NOCASE',
        whereArgs: [email.trim()],
        limit: 1,
      );

      debugPrint('🔍 QUERY RESULT: ${rows.length} row(s)');

      if (rows.isEmpty) {
        debugPrint('❌ FAIL at Step 1: No user found with email');
        debugPrint('   Showing ALL users in DB:');
        final allUsers = await db.query('users');
        for (final u in allUsers) {
          debugPrint('     → id=${u['id']}, email=${u['email']}');
        }
        throw const AuthException('Incorrect email or password.');
      }

      final row = rows.first;
      debugPrint('✅ Step 1 OK: User found');
      debugPrint('   DB email: ${row['email']}');
      debugPrint('   DB id:    ${row['id']}');

      // Step 2: Parse stored hash
      final storedHash = row['password_hash'] as String;
      debugPrint('🔐 Stored hash raw: "$storedHash"');

      final credentials = storedHash.split(':');
      debugPrint('🔐 Split by ":" → ${credentials.length} parts');
      if (credentials.isNotEmpty) {
        debugPrint('   Part 0 (salt): "${credentials[0]}"');
      }
      if (credentials.length >= 2) {
        debugPrint('   Part 1 (hash): "${credentials[1]}"');
      }

      if (credentials.length != 2) {
        debugPrint(
            '❌ FAIL at Step 2: Split produced ${credentials.length} parts (expected 2)');
        throw const AuthException('Incorrect email or password.');
      }

      // Step 3: Compute expected hash
      final computedHash = _hash(password, credentials.first);
      debugPrint('🔐 Computed hash: "$computedHash"');
      debugPrint('🔐 Stored hash:   "${credentials.last}"');
      debugPrint('🔐 Match: ${computedHash == credentials.last}');

      if (computedHash != credentials.last) {
        debugPrint('❌ FAIL at Step 3: Hash mismatch');
        throw const AuthException('Incorrect email or password.');
      }

      // Step 4: Success
      final user = AppUser.fromMap(row);
      await _saveSession(user.id);
      debugPrint('✅ LOGIN SUCCESS for user: ${user.email}');
      debugPrint('═══════════════════════════════════');
      return user;
    } on AuthException {
      debugPrint('❌ AuthException thrown');
      debugPrint('═══════════════════════════════════');
      rethrow;
    } catch (error) {
      debugPrint('❌ Unexpected error: $error');
      debugPrint('═══════════════════════════════════');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CURRENT USER (used by splash screen for session restore)
  // ═══════════════════════════════════════════════════════════
  Future<AppUser?> currentUser() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final userId = preferences.getInt(AppStrings.sessionUserIdKey);
      if (userId == null) return null;
      return await _getUserById(userId);
    } catch (error) {
      debugPrint('Session lookup error: $error');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════════
  Future<void> logout() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(AppStrings.sessionUserIdKey);
    } catch (error) {
      debugPrint('Logout error: $error');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════
  Future<AppUser> _getUserById(int id) async {
    final db = await _databaseService.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) {
      throw const AuthException('This account could not be found.');
    }
    return AppUser.fromMap(rows.first);
  }

  Future<void> _saveSession(int userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(AppStrings.sessionUserIdKey, userId);
  }

  String _newSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(24, (_) => random.nextInt(256)));
  }

  String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}
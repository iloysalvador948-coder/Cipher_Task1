import 'package:flutter/foundation.dart';

import '../models/todo_model.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class TodoViewModel extends ChangeNotifier {
  final DatabaseService _db;
  final EncryptionService _crypto;

  bool _busy = false;
  String? _error;

  List<TodoModel> _todos = [];
  List<TodoModel> get todos => _todos;

  bool get isBusy => _busy;
  String? get error => _error;

  static const List<String> priorities = ['Low', 'Medium', 'High'];

  TodoViewModel(this._db, this._crypto);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void loadTodos(String ownerEmail) {
    _todos = _db.getTodosForOwner(ownerEmail);
    notifyListeners();
  }

  String decryptNoteForUi(TodoModel todo) {
    return _crypto.decryptSensitiveNote(todo.encryptedNote);
  }

  int get totalCount => _todos.length;

  int get completedCount => _todos.where((t) => t.completed).length;

  int get pendingCount => _todos.where((t) => !t.completed).length;

  int get overdueCount {
    final now = DateTime.now();
    return _todos.where((t) {
      return !t.completed &&
          t.dueDate != null &&
          t.dueDate!.isBefore(now);
    }).length;
  }

  bool isOverdue(TodoModel todo) {
    if (todo.completed || todo.dueDate == null) return false;
    return todo.dueDate!.isBefore(DateTime.now());
  }

  Future<bool> addTodo({
    required String ownerEmail,
    required String title,
    required String notePlaintext,
    DateTime? dueDate,
    required String priority,
  }) async {
    _setBusy(true);
    try {
      if (title.trim().isEmpty) {
        _error = 'Title is required.';
        return false;
      }

      if (!priorities.contains(priority)) {
        _error = 'Invalid priority.';
        return false;
      }

      final now = DateTime.now();
      final encrypted = _crypto.encryptSensitiveNote(notePlaintext);

      final todo = TodoModel(
        id: _db.newId(),
        ownerEmail: ownerEmail.toLowerCase().trim(),
        title: title.trim(),
        encryptedNote: encrypted,
        completed: false,
        createdAt: now,
        updatedAt: now,
        dueDate: dueDate,
        priority: priority,
      );

      await _db.upsertTodo(todo);
      loadTodos(ownerEmail);
      _error = null;
      return true;
    } catch (_) {
      _error = 'Failed to add todo.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> updateTodo({
    required String ownerEmail,
    required TodoModel existing,
    required String newTitle,
    required String newNotePlaintext,
    DateTime? dueDate,
    required String priority,
  }) async {
    _setBusy(true);
    try {
      if (newTitle.trim().isEmpty) {
        _error = 'Title is required.';
        return false;
      }

      if (!priorities.contains(priority)) {
        _error = 'Invalid priority.';
        return false;
      }

      final encrypted = _crypto.encryptSensitiveNote(newNotePlaintext);

      final updated = TodoModel(
        id: existing.id,
        ownerEmail: existing.ownerEmail,
        title: newTitle.trim(),
        encryptedNote: encrypted,
        completed: existing.completed,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
        dueDate: dueDate,
        priority: priority,
      );

      await _db.upsertTodo(updated);
      loadTodos(ownerEmail);
      _error = null;
      return true;
    } catch (_) {
      _error = 'Failed to update todo.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> toggleCompleted({
    required String ownerEmail,
    required TodoModel todo,
  }) async {
    _setBusy(true);
    try {
      final updated = todo.copyWith(
        completed: !todo.completed,
        updatedAt: DateTime.now(),
      );
      await _db.upsertTodo(updated);
      loadTodos(ownerEmail);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> deleteTodo({
    required String ownerEmail,
    required String todoId,
  }) async {
    _setBusy(true);
    try {
      await _db.deleteTodo(todoId);
      loadTodos(ownerEmail);
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }
}
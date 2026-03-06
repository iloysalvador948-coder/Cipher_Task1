import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class TodoModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String ownerEmail;

  @HiveField(2)
  final String title;

  /// Encrypted payload string: v1:<iv_b64>:<cipher_b64>
  @HiveField(3)
  final String encryptedNote;

  @HiveField(4)
  final bool completed;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final DateTime? dueDate;

  @HiveField(8)
  final String priority; // Low, Medium, High

  TodoModel({
    required this.id,
    required this.ownerEmail,
    required this.title,
    required this.encryptedNote,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.priority = 'Medium',
  });

  TodoModel copyWith({
    String? title,
    String? encryptedNote,
    bool? completed,
    DateTime? updatedAt,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? priority,
  }) {
    return TodoModel(
      id: id,
      ownerEmail: ownerEmail,
      title: title ?? this.title,
      encryptedNote: encryptedNote ?? this.encryptedNote,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
    );
  }
}

/// Manual Hive adapter
class TodoModelAdapter extends TypeAdapter<TodoModel> {
  @override
  final int typeId = 2;

  @override
  TodoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }

    return TodoModel(
      id: fields[0] as String,
      ownerEmail: fields[1] as String,
      title: fields[2] as String,
      encryptedNote: fields[3] as String,
      completed: fields[4] as bool,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
      dueDate: fields[7] as DateTime?,
      priority: (fields[8] as String?) ?? 'Medium',
    );
  }

  @override
  void write(BinaryWriter writer, TodoModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ownerEmail)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.encryptedNote)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.dueDate)
      ..writeByte(8)
      ..write(obj.priority);
  }
}
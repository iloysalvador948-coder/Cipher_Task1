import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)  final String    email;
  @HiveField(1)  final List<int> passwordHash;
  @HiveField(2)  final List<int> salt;
  @HiveField(3)  bool      biometricsEnabled;
  @HiveField(4)  bool      hasLoggedInOnce;
  @HiveField(5)  String?   displayName;
  @HiveField(6)  String?   photoUrl;       // URL from Google
  @HiveField(7)  bool      isGoogleUser;
  @HiveField(8)  String?   phone;
  @HiveField(9)  String?   bio;
  @HiveField(10) String?   location;
  @HiveField(11) String?   jobTitle;
  @HiveField(12) String?   birthday;
  @HiveField(13) DateTime? memberSince;
  @HiveField(14) String?   localPhotoPath; // local file from camera/gallery

  UserModel({
    required this.email,
    required this.passwordHash,
    required this.salt,
    this.biometricsEnabled = false,
    this.hasLoggedInOnce   = false,
    this.displayName,
    this.photoUrl,
    this.isGoogleUser    = false,
    this.phone,
    this.bio,
    this.location,
    this.jobTitle,
    this.birthday,
    this.memberSince,
    this.localPhotoPath,
  });
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    final n      = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < n; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return UserModel(
      email:             fields[0]  as String,
      passwordHash:      (fields[1] as List).cast<int>(),
      salt:              (fields[2] as List).cast<int>(),
      biometricsEnabled: (fields[3]  as bool?)  ?? false,
      hasLoggedInOnce:   (fields[4]  as bool?)  ?? false,
      displayName:        fields[5]  as String?,
      photoUrl:           fields[6]  as String?,
      isGoogleUser:      (fields[7]  as bool?)  ?? false,
      phone:              fields[8]  as String?,
      bio:                fields[9]  as String?,
      location:           fields[10] as String?,
      jobTitle:           fields[11] as String?,
      birthday:           fields[12] as String?,
      memberSince:        fields[13] as DateTime?,
      localPhotoPath:     fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)  ..write(obj.email)
      ..writeByte(1)  ..write(obj.passwordHash)
      ..writeByte(2)  ..write(obj.salt)
      ..writeByte(3)  ..write(obj.biometricsEnabled)
      ..writeByte(4)  ..write(obj.hasLoggedInOnce)
      ..writeByte(5)  ..write(obj.displayName)
      ..writeByte(6)  ..write(obj.photoUrl)
      ..writeByte(7)  ..write(obj.isGoogleUser)
      ..writeByte(8)  ..write(obj.phone)
      ..writeByte(9)  ..write(obj.bio)
      ..writeByte(10) ..write(obj.location)
      ..writeByte(11) ..write(obj.jobTitle)
      ..writeByte(12) ..write(obj.birthday)
      ..writeByte(13) ..write(obj.memberSince)
      ..writeByte(14) ..write(obj.localPhotoPath);
  }
}
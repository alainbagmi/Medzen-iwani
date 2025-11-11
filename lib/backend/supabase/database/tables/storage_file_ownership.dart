import '../database.dart';

class StorageFileOwnershipTable extends SupabaseTable<StorageFileOwnershipRow> {
  @override
  String get tableName => 'storage_file_ownership';

  @override
  StorageFileOwnershipRow createRow(Map<String, dynamic> data) =>
      StorageFileOwnershipRow(data);
}

class StorageFileOwnershipRow extends SupabaseDataRow {
  StorageFileOwnershipRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => StorageFileOwnershipTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get storagePath => getField<String>('storage_path')!;
  set storagePath(String value) => setField<String>('storage_path', value);

  String get bucketId => getField<String>('bucket_id')!;
  set bucketId(String value) => setField<String>('bucket_id', value);

  String get ownerFirebaseUid => getField<String>('owner_firebase_uid')!;
  set ownerFirebaseUid(String value) =>
      setField<String>('owner_firebase_uid', value);

  String? get fileType => getField<String>('file_type');
  set fileType(String? value) => setField<String>('file_type', value);

  String? get facilityId => getField<String>('facility_id');
  set facilityId(String? value) => setField<String>('facility_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}

import '../database.dart';

class PasswordResetTokensTable extends SupabaseTable<PasswordResetTokensRow> {
  @override
  String get tableName => 'password_reset_tokens';

  @override
  PasswordResetTokensRow createRow(Map<String, dynamic> data) =>
      PasswordResetTokensRow(data);
}

class PasswordResetTokensRow extends SupabaseDataRow {
  PasswordResetTokensRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PasswordResetTokensTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  String get phoneNumber => getField<String>('phone_number')!;
  set phoneNumber(String value) => setField<String>('phone_number', value);

  String get resetToken => getField<String>('reset_token')!;
  set resetToken(String value) => setField<String>('reset_token', value);

  DateTime get expiresAt => getField<DateTime>('expires_at')!;
  set expiresAt(DateTime value) => setField<DateTime>('expires_at', value);

  bool? get used => getField<bool>('used');
  set used(bool? value) => setField<bool>('used', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get usedAt => getField<DateTime>('used_at');
  set usedAt(DateTime? value) => setField<DateTime>('used_at', value);
}

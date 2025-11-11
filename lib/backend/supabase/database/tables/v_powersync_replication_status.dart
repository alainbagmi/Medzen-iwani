import '../database.dart';

class VPowersyncReplicationStatusTable
    extends SupabaseTable<VPowersyncReplicationStatusRow> {
  @override
  String get tableName => 'v_powersync_replication_status';

  @override
  VPowersyncReplicationStatusRow createRow(Map<String, dynamic> data) =>
      VPowersyncReplicationStatusRow(data);
}

class VPowersyncReplicationStatusRow extends SupabaseDataRow {
  VPowersyncReplicationStatusRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VPowersyncReplicationStatusTable();

  String? get slotName => getField<String>('slot_name');
  set slotName(String? value) => setField<String>('slot_name', value);

  String? get plugin => getField<String>('plugin');
  set plugin(String? value) => setField<String>('plugin', value);

  String? get slotType => getField<String>('slot_type');
  set slotType(String? value) => setField<String>('slot_type', value);

  bool? get active => getField<bool>('active');
  set active(bool? value) => setField<bool>('active', value);

  int? get activePid => getField<int>('active_pid');
  set activePid(int? value) => setField<int>('active_pid', value);

  String? get restartLsn => getField<String>('restart_lsn');
  set restartLsn(String? value) => setField<String>('restart_lsn', value);

  String? get confirmedFlushLsn => getField<String>('confirmed_flush_lsn');
  set confirmedFlushLsn(String? value) =>
      setField<String>('confirmed_flush_lsn', value);
}

import '../database.dart';

class LanguagePreferencesTable extends SupabaseTable<LanguagePreferencesRow> {
  @override
  String get tableName => 'language_preferences';

  @override
  LanguagePreferencesRow createRow(Map<String, dynamic> data) =>
      LanguagePreferencesRow(data);
}

class LanguagePreferencesRow extends SupabaseDataRow {
  LanguagePreferencesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => LanguagePreferencesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  String? get uiLanguage => getField<String>('ui_language');
  set uiLanguage(String? value) => setField<String>('ui_language', value);

  String? get audioLanguage => getField<String>('audio_language');
  set audioLanguage(String? value) => setField<String>('audio_language', value);

  String? get subtitleLanguage => getField<String>('subtitle_language');
  set subtitleLanguage(String? value) =>
      setField<String>('subtitle_language', value);

  String? get ttsVoiceId => getField<String>('tts_voice_id');
  set ttsVoiceId(String? value) => setField<String>('tts_voice_id', value);

  String? get ttsEngine => getField<String>('tts_engine');
  set ttsEngine(String? value) => setField<String>('tts_engine', value);

  bool? get autoDetectLanguage => getField<bool>('auto_detect_language');
  set autoDetectLanguage(bool? value) =>
      setField<bool>('auto_detect_language', value);

  bool? get detectCodeSwitching => getField<bool>('detect_code_switching');
  set detectCodeSwitching(bool? value) =>
      setField<bool>('detect_code_switching', value);

  dynamic? get preferredLanguages => getField<dynamic>('preferred_languages');
  set preferredLanguages(dynamic? value) =>
      setField<dynamic>('preferred_languages', value);

  String? get regionCode => getField<String>('region_code');
  set regionCode(String? value) => setField<String>('region_code', value);

  String? get timezone => getField<String>('timezone');
  set timezone(String? value) => setField<String>('timezone', value);

  bool? get showSubtitles => getField<bool>('show_subtitles');
  set showSubtitles(bool? value) => setField<bool>('show_subtitles', value);

  int? get subtitleFontSize => getField<int>('subtitle_font_size');
  set subtitleFontSize(int? value) =>
      setField<int>('subtitle_font_size', value);

  bool? get highContrastSubtitles => getField<bool>('high_contrast_subtitles');
  set highContrastSubtitles(bool? value) =>
      setField<bool>('high_contrast_subtitles', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}

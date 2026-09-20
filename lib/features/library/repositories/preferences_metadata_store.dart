import 'package:shared_preferences/shared_preferences.dart';

import 'package:yank/features/library/repositories/metadata_store.dart';

class PreferencesMetadataStore implements MetadataStore {
  PreferencesMetadataStore() : _preferences = SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  @override
  Future<String?> read(String key) => _preferences.getString(key);
  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

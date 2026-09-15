abstract interface class MetadataStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

// Tests and previews use the same repository through this storage seam.
class MemoryMetadataStore implements MetadataStore {
  final Map<String, String> values = {};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

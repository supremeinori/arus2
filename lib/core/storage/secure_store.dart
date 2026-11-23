import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore();
});

class SecureStore {
  // [FLOW AUTH-STORE 1] Alat penyimpan permanen di memori HP yang terenkripsi hardware (AES-256).
  // Dipakai buat nyimpen token login biar nggak hilang walau app ditutup atau HP di-restart.
  final FlutterSecureStorage _storage;

  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
            );

  static const _keyAccessToken = 'arus_access_token';
  static const _keyRefreshToken = 'arus_refresh_token';
  static const _keyUserJson = 'arus_user_json';
  static const _keyLoginTimestamp = 'arus_login_timestamp';

  // [FLOW AUTH-STORE 2] Bungkus read/write/delete pakai try-catch biar kalau chip storage HP
  // lagi error, app nggak langsung crash layar merah (tinggal balikin null secara aman).
  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('[SecureStore] Warning: failed to read $key: $e');
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[SecureStore] Warning: failed to write $key: $e');
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('[SecureStore] Warning: failed to delete $key: $e');
    }
  }

  Future<String?> getAccessToken() async => await _safeRead(_keyAccessToken);
  Future<void> setAccessToken(String token) async => await _safeWrite(_keyAccessToken, token);
  Future<void> deleteAccessToken() async => await _safeDelete(_keyAccessToken);

  Future<String?> getRefreshToken() async => await _safeRead(_keyRefreshToken);
  Future<void> setRefreshToken(String token) async => await _safeWrite(_keyRefreshToken, token);
  Future<void> deleteRefreshToken() async => await _safeDelete(_keyRefreshToken);

  Future<String?> getUserJson() async => await _safeRead(_keyUserJson);
  Future<void> setUserJson(String json) async => await _safeWrite(_keyUserJson, json);

  // [FLOW AUTH-STORE 3] Dipanggil pas user berhasil login: simpan token + profil + jam login ke HP.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userJson,
  }) async {
    await setAccessToken(accessToken);
    await setRefreshToken(refreshToken);
    await setUserJson(userJson);
    await _safeWrite(_keyLoginTimestamp, DateTime.now().toIso8601String());
  }

  Future<bool> hasValidStoredSession() async {
    try {
      final refresh = await getRefreshToken();
      final userJson = await getUserJson();
      return refresh != null && refresh.isNotEmpty && userJson != null && userJson.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa apakah token/sesi telah kedaluwarsa (> 7 hari)
  Future<bool> isSessionExpired() async {
    try {
      final tsStr = await _safeRead(_keyLoginTimestamp);
      if (tsStr == null) return false;
      final loginDate = DateTime.parse(tsStr);
      final diff = DateTime.now().difference(loginDate);
      return diff.inDays >= 7;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateLoginTimestamp() async {
    await _safeWrite(_keyLoginTimestamp, DateTime.now().toIso8601String());
  }

  // [FLOW AUTH-STORE 4] Dipanggil pas logout atau kena error 401 dari api_client.dart: hapus bersih semua token.
  Future<void> clearTokens() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await _safeDelete(_keyUserJson);
    await _safeDelete(_keyLoginTimestamp);
  }

  Future<void> clearAllSession() async {
    await clearTokens();
  }
}

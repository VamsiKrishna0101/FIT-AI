import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/cache/user_data_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_cache.dart';
import '../../../core/storage/secure_session_store.dart';

class ProgressPhoto {
  final String id, date, url, thumbnailUrl;
  ProgressPhoto(Map<String, dynamic> json)
      : id = json['id'] as String,
        date = json['recordedDate'] as String,
        url = json['url'] as String,
        thumbnailUrl = json['thumbnailUrl'] as String;
}

class ProgressPhotoPage {
  final List<ProgressPhoto> photos;
  final String? nextCursor;
  ProgressPhotoPage(Map<String, dynamic> json)
      : photos = (json['photos'] as List)
            .map((p) => ProgressPhoto(Map<String, dynamic>.from(p as Map)))
            .toList(),
        nextCursor = json['nextCursor'] as String?;
}

class ProgressPhotoRepository {
  static final shared = ProgressPhotoRepository();
  final changes = StreamController<void>.broadcast();
  static const path = '/api/progress-photos';

  static String uploadId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<Options> _options() async => Options(extra: {
        'sessionOwnerToken': await SecureSessionStore.shared.accessToken,
      });

  Future<ProgressPhotoPage> load({String? cursor, bool refresh = false}) async {
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') {
      return ProgressPhotoPage({'photos': <dynamic>[], 'nextCursor': null});
    }
    final data = await UserDataCache.shared
        .load('progress_photos', cursor ?? 'latest', () async {
      final response = await ApiClient.shared.client.get<Map<String, dynamic>>(
          path,
          queryParameters: {if (cursor != null) 'cursor': cursor},
          options: await _options());
      return response.data!;
    }, refresh: refresh);
    if (owner != await CacheScope.userId()) throw StateError('Account changed');
    return ProgressPhotoPage(data);
  }

  Future<void> save(Uint8List bytes,
      {required String id,
      required String date,
      String? workoutDate,
      String? expectedOwner}) async {
    if (expectedOwner != null && expectedOwner != await CacheScope.userId()) {
      throw StateError('Account changed. Open the photo journal again.');
    }
    await ApiClient.shared.client.post(path,
        data: {
          'id': id,
          'recordedDate': date,
          if (workoutDate != null) 'workoutDate': workoutDate,
          'base64': base64Encode(bytes),
        },
        options: await _options());
    await UserDataCache.shared.invalidate('progress_photos');
    changes.add(null);
  }

  Future<void> delete(String id) async {
    await ApiClient.shared.client
        .delete('$path/$id', options: await _options());
    await UserDataCache.shared.invalidate('progress_photos');
    changes.add(null);
  }

  Future<bool> claimPrompt(String date) async {
    if (await CacheScope.userId() == 'anonymous') return false;
    final key = await CacheScope.userKey('progress_photo_prompt_$date');
    if (await LocalCache.shared.getString(key) != null) return false;
    await LocalCache.shared.saveString(key, 'shown');
    return true;
  }
}

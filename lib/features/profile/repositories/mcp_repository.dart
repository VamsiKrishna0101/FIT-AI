import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/network/api_client.dart';

const mcpPermissions = <String, (String, String)>{
  'training:read': (
    'Training profile',
    'Goals, experience, equipment and training days.'
  ),
  'plans:read': (
    'Weekly workouts',
    'Saved exercises, sets, reps and prescribed loads.'
  ),
  'workouts:read': (
    'Workout history',
    'Recorded training and calculated progress.'
  ),
  'nutrition:read': ('Nutrition', 'Logged intake and saved nutrition targets.'),
  'measurements:read': (
    'Body measurements',
    'Measurements you entered. Photos are excluded.'
  ),
};

class McpAccessToken {
  final String id, name, lastFour;
  final List<String> scopes;
  final DateTime createdAt, expiresAt;
  final DateTime? lastUsedAt, revokedAt;
  const McpAccessToken(
      {required this.id,
      required this.name,
      required this.lastFour,
      required this.scopes,
      required this.createdAt,
      required this.expiresAt,
      this.lastUsedAt,
      this.revokedAt});
  factory McpAccessToken.fromJson(Map<String, dynamic> json) => McpAccessToken(
      id: json['id'] as String,
      name: json['name'] as String,
      lastFour: json['lastFour'] as String,
      scopes: (json['scopes'] as List).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? ''),
      revokedAt: DateTime.tryParse(json['revokedAt'] as String? ?? ''));
  bool get expired => !expiresAt.isAfter(DateTime.now());
  bool get active => revokedAt == null && !expired;
}

class McpTokenList {
  final bool configured;
  final String? serverUrl;
  final List<McpAccessToken> tokens;
  const McpTokenList(
      {required this.configured, required this.tokens, this.serverUrl});
}

class McpIssuedToken {
  final McpAccessToken token;
  final String secret, serverUrl, owner;
  const McpIssuedToken(
      {required this.token,
      required this.secret,
      required this.serverUrl,
      required this.owner});
}

class McpRepository {
  static const _path = '/api/integrations/mcp/tokens';
  Future<String> currentOwner() async {
    final owner = await CacheScope.userId();
    if (owner == 'anonymous') {
      throw StateError('Sign in to manage your AI connections.');
    }
    return owner;
  }

  Future<void> requireOwner(String owner) async {
    if (await currentOwner() != owner) {
      throw StateError('Your account changed. Reopen AI connections.');
    }
  }

  Future<McpTokenList> load() async {
    final owner = await currentOwner();
    final response = await ApiClient.shared.get<Map<String, dynamic>>(_path);
    await requireOwner(owner);
    final data = response.data!['data'] as Map;
    return McpTokenList(
        configured: data['configured'] == true,
        serverUrl: data['serverUrl'] as String?,
        tokens: (data['tokens'] as List)
            .map((v) => McpAccessToken.fromJson(Map<String, dynamic>.from(v)))
            .toList());
  }

  Future<McpIssuedToken> create(
      {required String expectedOwner,
      required String name,
      required List<String> scopes,
      required int days,
      String? replaceId}) async {
    await requireOwner(expectedOwner);
    final response = await ApiClient.shared.post<Map<String, dynamic>>(
        replaceId == null ? _path : '$_path/$replaceId/replace',
        data: {'name': name.trim(), 'scopes': scopes, 'expiresInDays': days});
    await requireOwner(expectedOwner);
    final data = response.data!['data'] as Map;
    return McpIssuedToken(
        token:
            McpAccessToken.fromJson(Map<String, dynamic>.from(data['token'])),
        secret: data['secret'] as String,
        serverUrl: data['serverUrl'] as String,
        owner: expectedOwner);
  }

  Future<void> revoke(String id, {required String expectedOwner}) async {
    await requireOwner(expectedOwner);
    await ApiClient.shared.delete('$_path/$id');
    await requireOwner(expectedOwner);
  }

  static String message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      return 'Could not reach your AI connections. Please try again.';
    }
    if (error is StateError) return error.message.toString();
    return 'Could not complete this request. Please try again.';
  }
}

class McpClipboard {
  static const channel = MethodChannel('setcraft/credentials');
  static Future<void> copySecret(String value) async {
    if (!kIsWeb &&
        [TargetPlatform.android, TargetPlatform.iOS]
            .contains(defaultTargetPlatform)) {
      await channel.invokeMethod<void>('copyToken', {'value': value});
    } else {
      await Clipboard.setData(ClipboardData(text: value));
    }
  }

  static Future<void> protectScreen(bool protected) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await channel
            .invokeMethod<void>('protectScreen', {'enabled': protected});
      } catch (_) {/* Older host builds can still keep the token masked. */}
    }
  }
}

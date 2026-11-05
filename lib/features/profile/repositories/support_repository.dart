import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'settings_account_repository.dart';

const supportCategoryLabels = {
  'ACCOUNT': 'Account',
  'BILLING': 'Subscription & billing',
  'WORKOUTS': 'Training',
  'NUTRITION': 'Nutrition',
  'PRIVACY': 'Privacy & data',
  'BUG': 'Something isn’t working',
  'OTHER': 'Something else'
};
const supportStatusLabels = {
  'OPEN': 'Open',
  'IN_PROGRESS': 'In progress',
  'WAITING_FOR_USER': 'Waiting for you',
  'RESOLVED': 'Resolved'
};

String supportRequestId() {
  final random = Random.secure(),
      bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class SupportScreenshot {
  final Uint8List bytes;
  const SupportScreenshot(this.bytes);
  Map<String, dynamic> toJson() {
    if (bytes.isEmpty || bytes.length > 1024 * 1024) {
      throw StateError('Choose a screenshot smaller than 1 MB.');
    }
    final png = bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    final jpeg = bytes.length >= 2 && bytes[0] == 255 && bytes[1] == 216;
    if (!png && !jpeg) throw StateError('Choose a PNG or JPEG screenshot.');
    return {
      'mimeType': png ? 'image/png' : 'image/jpeg',
      'base64': base64Encode(bytes)
    };
  }
}

class SupportRepository extends SettingsAccountRepository {
  Future<Map<String, dynamic>> configuration() async =>
      Map<String, dynamic>.from(
          await request('GET', '/api/support/config') as Map);
  Future<Map<String, dynamic>> tickets({String? cursor}) async =>
      Map<String, dynamic>.from(await request('GET', '/api/support/tickets',
          query: {if (cursor != null) 'cursor': cursor}) as Map);
  Future<Map<String, dynamic>> ticket(String id) async =>
      Map<String, dynamic>.from(
          await request('GET', '/api/support/tickets/$id') as Map);
  Future<Map<String, dynamic>> create(Map<String, dynamic> input) async =>
      Map<String, dynamic>.from(
          await request('POST', '/api/support/tickets', data: input) as Map);
  Future<void> reply(String id, Map<String, dynamic> input) async {
    await request('POST', '/api/support/tickets/$id/messages', data: input);
  }

  Future<Uint8List> attachment(String id) async =>
      Uint8List.fromList(List<int>.from(
          await request('GET', '/api/support/attachments/$id', bytes: true)
              as List));
}

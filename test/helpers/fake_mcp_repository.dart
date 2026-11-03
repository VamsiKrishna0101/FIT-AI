import 'dart:async';
import 'package:setcraft/features/profile/repositories/mcp_repository.dart';

class FakeMcpRepository extends McpRepository {
  String owner = 'settings-user';
  bool configured = true;
  int creates = 0, revocations = 0;
  int _issuedCount = 0;
  String? replaced;
  int? days;
  List<String>? granted;
  final tokens = <McpAccessToken>[];
  Completer<McpIssuedToken>? pending;
  @override
  Future<String> currentOwner() async => owner;
  @override
  Future<McpTokenList> load() async => McpTokenList(
      configured: configured,
      tokens: List.of(tokens),
      serverUrl: 'https://example.invalid/mcp');
  McpIssuedToken issue(
      {String name = 'My Claude',
      List<String> scopes = const ['plans:read'],
      int days = 30}) {
    final token = McpAccessToken(
        id: 'fixture-${++_issuedCount}',
        name: name,
        lastFour: 'TEST',
        scopes: scopes,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: days)));
    return McpIssuedToken(
        token: token,
        secret: 'sc_mcp_fixture-only-not-a-real-token',
        serverUrl: 'https://example.invalid/mcp',
        owner: owner);
  }

  @override
  Future<McpIssuedToken> create(
      {required String expectedOwner,
      required String name,
      required List<String> scopes,
      required int days,
      String? replaceId}) async {
    await requireOwner(expectedOwner);
    creates++;
    replaced = replaceId;
    this.days = days;
    granted = scopes;
    if (pending != null) return pending!.future;
    final result = issue(name: name, scopes: scopes, days: days);
    tokens.removeWhere((t) => t.id == replaceId);
    tokens.insert(0, result.token);
    return result;
  }

  @override
  Future<void> revoke(String id, {required String expectedOwner}) async {
    await requireOwner(expectedOwner);
    revocations++;
    tokens.removeWhere((t) => t.id == id);
  }
}

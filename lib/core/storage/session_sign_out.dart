/// Optional device cleanup must not turn a completed local logout into failure.
Future<void> completeSessionSignOut({
  required Future<void> Function() detachNotifications,
  required Future<void> Function() clearSession,
  required List<Future<void> Function()> cleanup,
}) async {
  try {
    // Remove the current account's push registration before dropping its token.
    await detachNotifications();
  } catch (_) {
    // Offline or unavailable notification plugins cannot prevent local logout.
  }
  // Credential removal is mandatory. Propagate failure so we never claim logout
  // succeeded while an authenticated session remains on the device.
  await clearSession();
  for (final action in cleanup) {
    try {
      await action();
    } catch (_) {
      // User caches are account-scoped; failed cleanup cannot expose them to
      // another account and must not keep the signed-out UI authenticated.
    }
  }
}

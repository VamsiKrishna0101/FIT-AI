/// Presentation of older plan notes; never derive effort from a readiness score.
class SessionGuidance {
  final double? effort;
  final String summary;
  const SessionGuidance(this.effort, this.summary);
  factory SessionGuidance.fromNote(String? note, {required String fallback}) {
    var text = note?.trim() ?? '';
    final match = RegExp(
            r'^[^:\n]{1,40}:\s*(\d+(?:[.,]\d+)?)\s*/\s*10(?:\s*\([^)]+\))?\s*(?:[—–-]\s*)?',
            caseSensitive: false)
        .firstMatch(text);
    final parsed = match == null
        ? null
        : double.tryParse(match.group(1)!.replaceAll(',', '.'));
    final effort =
        parsed != null && parsed >= 0 && parsed <= 10 ? parsed : null;
    if (match != null) text = text.substring(match.end).trim();
    // Existing starter plans used certainty claims unsupported by their data.
    if (RegExp(
            r'full recovery detected|CNS primed|prime window for hypertrophy',
            caseSensitive: false)
        .hasMatch(text)) {
      text = fallback;
    }
    final firstSentence = text.split(RegExp(r'(?<=[.!?])\s+')).first;
    return SessionGuidance(effort, firstSentence);
  }
  String get effortLabel => effort == null
      ? ''
      : effort == effort?.roundToDouble()
          ? '${effort!.toInt()} / 10'
          : '${effort!.toStringAsFixed(1)} / 10';
}

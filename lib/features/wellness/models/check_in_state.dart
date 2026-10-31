bool _validAnswer(Object? value) =>
    value is num &&
    value.isFinite &&
    value == value.round() &&
    value >= 1 &&
    value <= 5;

bool hasCheckInAnswers(Map<String, dynamic>? entry) => [
      'rested',
      'energy',
      'soreness'
    ].every((field) => _validAnswer(entry?[field]));

bool hasAnyCheckInAnswer(Map<String, dynamic>? entry) => [
      'rested',
      'energy',
      'soreness'
    ].any((field) => _validAnswer(entry?[field]));

String savedCheckInLabel(Map<String, dynamic> entry) => hasCheckInAnswers(entry)
    ? 'Check-in saved'
    : hasAnyCheckInAnswer(entry)
        ? 'Progress saved'
        : 'Sleep saved';

String checkInSaveAction(Map<String, dynamic> entry) => hasCheckInAnswers(entry)
    ? 'Save check-in'
    : hasAnyCheckInAnswer(entry)
        ? 'Save progress'
        : 'Save sleep';

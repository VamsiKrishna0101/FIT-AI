DateTime sleepWeekStart(DateTime date) =>
    DateTime(date.year, date.month, date.day - date.weekday + 1);

bool canEditSleepDate(DateTime date, DateTime now) {
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  return !day.isBefore(sleepWeekStart(today)) && !day.isAfter(today);
}

const pastSleepReadOnly = 'Sleep entries from previous weeks are read-only.';
const futureSleepReadOnly =
    'Sleep can only be edited for today or earlier this week.';

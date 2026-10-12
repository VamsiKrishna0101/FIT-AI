// MARK: - Prisma WorkingToward Enum Alignment for Onboarding Screen 01
enum WorkingTowardGoal {
  buildMuscle('BUILD_MUSCLE', '💪'),
  loseBodyFat('LOSE_BODY_FAT', '🔥'),
  loseWeight('LOSE_WEIGHT', '⚖️'),
  getFitter('GET_FITTER', '🏃'),
  buildConsistency('BUILD_CONSISTENCY', '🎯');

  final String backendValue;
  final String emoji;

  const WorkingTowardGoal(this.backendValue, this.emoji);

  static WorkingTowardGoal fromBackend(String? value) {
    if (value == null) return WorkingTowardGoal.buildMuscle;
    return WorkingTowardGoal.values.firstWhere(
      (g) => g.backendValue == value,
      orElse: () => WorkingTowardGoal.buildMuscle,
    );
  }
}

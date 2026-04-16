/// Aggregated team statistics for the Member Hub dashboard.
class TeamStats {
  const TeamStats({
    required this.totalSize,
    required this.activeCount,
    required this.commonCount,
    required this.lowActiveCount,
    required this.gpvThisMonth,
    required this.newJoinsThisMonth,
  });

  final int totalSize;
  final int activeCount;
  final int commonCount;
  final int lowActiveCount;
  final int gpvThisMonth;
  final int newJoinsThisMonth;

  /// Percentage of team members who are active, as a value between 0 and 100.
  double get activePercent =>
      totalSize > 0 ? (activeCount / totalSize) * 100 : 0.0;

  /// Formatted active percentage string.
  String get activePercentFormatted => '${activePercent.toStringAsFixed(0)}%';
}

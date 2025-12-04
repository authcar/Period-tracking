class PeriodEntry {
  final DateTime startDate;
  final DateTime? endDate;

  PeriodEntry({
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory PeriodEntry.fromMap(Map map) {
    return PeriodEntry(
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
    );
  }
}

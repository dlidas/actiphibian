class FocusSession {
  final int? id;
  final String methodId;
  final DateTime startedAt;
  final int focusedMinutes;
  final int xpAwarded;

  const FocusSession({
    this.id,
    required this.methodId,
    required this.startedAt,
    required this.focusedMinutes,
    this.xpAwarded = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'methodId': methodId,
    'startedAt': startedAt.toIso8601String(),
    'focusedMinutes': focusedMinutes,
    'xpAwarded': xpAwarded,
  };

  factory FocusSession.fromMap(Map<String, dynamic> map) => FocusSession(
    id: map['id'] as int?,
    methodId: map['methodId'] as String,
    startedAt: DateTime.parse(map['startedAt'] as String),
    focusedMinutes: map['focusedMinutes'] as int,
    xpAwarded: map['xpAwarded'] as int? ?? 0,
  );
}

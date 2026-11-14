/// How far back a practice start still counts as present.
enum AdminPresenceWindow {
  hour(Duration(hours: 1)),
  threeHours(Duration(hours: 3)),
  day(Duration(hours: 24)),
  week(Duration(days: 7));

  const AdminPresenceWindow(this.duration);

  final Duration duration;
}

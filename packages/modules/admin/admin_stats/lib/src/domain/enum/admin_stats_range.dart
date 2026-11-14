/// How many days of history the dashboard shows, ending today (UTC).
enum AdminStatsRange {
  week(7),
  month(30),
  quarter(90);

  const AdminStatsRange(this.days);

  final int days;
}

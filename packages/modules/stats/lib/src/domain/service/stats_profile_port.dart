/// Profile data the stats domain needs from the profile module.
abstract interface class StatsProfilePort {

  /// Returns the profile's current consecutive practice days count.
  Future<int> getConsecutiveDaysCount(String profileId);

}

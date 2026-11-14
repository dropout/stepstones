# admin_stats

Global practice statistics for the Stepstones admin app: all-time totals and a per-day history.

The numbers are read-only aggregates written by the `db-profiles-sessions-onsessioncreate` Cloud Function whenever a session document is created. Each counter is spread over shard documents to avoid write contention:

- `global_stats/all_time/shards/{n}`
- `global_stats/daily_<YYYY-MM-DD>/shards/{n}` (UTC day of the session's end time)

Every shard holds `totalSessions`, `totalDurationInSeconds` and one `type_<sessionType>` counter per session type; the module sums the shards. Only sessions created while the function is deployed are counted.

All-time totals are a live listener. Days are fetched on demand, one small query per day, and today is re-fetched whenever the all-time totals change.

# Health connection

## Implemented flow

After authentication, Android and iOS accounts see an optional connection screen once per account on that installation. Set up later opens Today without requesting OS permissions. Profile → Health connection and the Today health card provide later access.

Android uses Health Connect; iOS uses Apple Health. Requests are read-only: steps, active energy, external workouts, sleep, resting heart rate, and platform-specific HRV. Weight and body fat are requested only when the user enables Body measurements and applies sharing choices. Android categories can be granted individually. Apple does not disclose individual read denials; completion of the permission sheet is not displayed as proof that all reads were granted.

Readings are uploaded to the signed-in account. Account-scoped preferences control consent and first import. Opening/resuming the dashboard syncs when the last check is older than five minutes; Sync now allows a retry. The first successful connection also reads the preceding six days. A failed history import remains eligible for retry. This release uses foreground sync and requests no background/history extension permissions.

## Data handling

- Movement uses local midnight boundaries and native platform aggregate queries. Missing results remain null on both platforms; a returned, recorded zero can be shown as zero. The plugin's default zero for an absent Android aggregate is bypassed.
- Sleep is assigned to its wake-up day. Stages belonging to one night are grouped before date filtering. Interval unions avoid double counting asleep summaries and stages, subtract recorded awake intervals, and select one origin to avoid mirrored records. Health Connect stages can share UUIDs, so deduplication also includes timestamps. Apple in-bed time alone is not treated as asleep.
- Weight and body fat use the latest available dated measurement. Android RMSSD and Apple SDNN are identified separately; trends do not join the two methods.
- PostgreSQL stores per-metric source, measurement time, HRV method and UTC offset. Movement remains visible without a readiness score. Readiness needs sleep and a heart reading and is labeled a FitAI fitness estimate. It is the existing heuristic, not a personalized baseline or a clinical measure.
- External workout IDs are scoped to the account. Repeated imports update the existing record; compatible older timestamp IDs are upgraded in place. Imported sessions do not create FitAI sets, repetitions or strength volume. Missing workout calories remain empty.
- Stopping sync disables future reads/uploads on this installation. Android additionally revokes OS access; Apple access is managed in Apple Health. Previously saved account records remain available.

## Device verification

Install a newly built app; native permission changes require a rebuild, not hot reload. Start the updated backend. The additive migration `20261010120000_health_read_provenance` is applied to the configured development PostgreSQL database.

1. On Android, ensure Health Connect is supported and receives readings from a source app/watch. On older supported versions, install/update Health Connect when prompted. Grant steps alone: Today should show movement with no invented readiness.
2. Grant sleep and heart data; verify recorded dates, sleep across midnight, movement totals and source labels against the health app. Select prior dates in Weekly rhythm to inspect their imported readings.
3. Enable optional body measurements and review sharing choices. Saved scale readings should appear in Body → Physique → Synced measurements.
4. Sync twice: external workouts should remain single records. FitAI sets/volume should change only through FitAI workout logging.
5. Deny categories, revoke access, stop syncing, retry after losing network access, and change accounts during a sync. Existing saved readings should remain; no reading should upload to a different account.
6. On iPhone, repeat with Apple Health, including declining every read category. This must show no readable records rather than fabricated zeros or claimed read grants. Review and revoke access from Apple Health.

## Release setup outside this Windows workspace

Android native integration has been built in a debug APK. iOS native compilation and device permission behavior require macOS/Xcode and an iPhone. Enable HealthKit for the signing App ID/provisioning profile; the project entitlement and capability are configured. Before distribution, complete the platform health-data declarations and provide the public privacy-policy URL matching the in-app explanation. Health Connect must have actual upstream records; connecting alone does not create steps or sleep.

Official references: [Health Connect permissions](https://developer.android.com/health-and-fitness/health-connect/get-started), [aggregated data](https://developer.android.com/health-and-fitness/health-connect/aggregate-data), [Apple HealthKit authorization](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data).

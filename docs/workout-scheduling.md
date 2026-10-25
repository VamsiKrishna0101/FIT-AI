Weekly plans can start today, tomorrow or a chosen date. The generation sheet asks
for the number of sessions and exact calendar dates through Sunday. This override
does not change onboarding preferences. One- and two-session first weeks use full
body coverage unless the user has an explicit custom day split. The regular
generation cooldown ends at the next local Monday for these selected-date plans.

Rest today is available for an unstarted dated workout in Train and the active
weekly plan. The preview lists original and new dates. Available dates can be
adjusted. Moving keeps order and at least the original gap between pending
sessions. Workouts that cannot fit before Sunday are explicitly listed as skips;
the confirmation button names that consequence. Skip today only leaves other
workouts in place. Started, completed and logged workouts cannot move.

The backend rechecks the preview fingerprint under the same advisory date locks
used by session edits. Repeated identical submissions return the saved result.
The original AI payload stays immutable; a separate audit record provides its
effective schedule. Moving changes only dates and weekday mappings; exercise IDs,
targets, warm-ups, logs and nutrition remain intact. No AI request is needed.
Schedule changes require a connection and refuse to run over unsynced local logs.

Checks: planner fixture matrix including partial weeks, DST and year changes;
isolated database ownership/concurrency/skip/session tests; Flutter date-selection,
preview/confirmation/retry tests; existing weekly-plan and training regressions.

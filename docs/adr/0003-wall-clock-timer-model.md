---
status: accepted
---

# Wall-clock timer model with foreground service (Android) and local notifications (iOS)

Mobile OSes do not let apps run arbitrary code in the background. A naive `Timer.periodic` ticking a counter in memory dies the moment the app is suspended (iOS, within seconds) or memory-pressured (Android, within minutes). We model elapsed time as **derived state**: every render computes `elapsed = now - startTime - totalBreakSeconds` from timestamps persisted in the local DB. The timer itself never "runs" — it is reconstructed on every UI tick and on every app launch.

For the persistent "Studying: …" notification users expect, Android uses a foreground service (`flutter_foreground_task`) tied to the **Active Session** lifecycle, updating notification text every 10 seconds with the derived elapsed value. iOS schedules a static "Session in progress" local notification on session start and cancels it on end; live-updating text in an iOS notification is not feasible without abuse-prone background modes.

## Consequences

- Local **Study Session** rows store only `startTime`, `endTime`, `status`, and a child collection of **Break** rows with their own start/end. No `total_duration` counter is persisted; the existing backend columns `total_duration` and `effective_study_time` (`backend` `study_sessions:449-450`) are derived at session-end, not maintained live.
- Surviving an app kill or phone reboot is automatic: the **Active Session** row is still in local SQLite on next launch, and elapsed re-derives correctly.
- The **Sync Queue** carries events (`SessionStarted`, `BreakStarted`, `BreakEnded`, `SessionEnded`) with their original timestamps, not aggregate durations. The backend reconstructs the session from the event stream on sync.

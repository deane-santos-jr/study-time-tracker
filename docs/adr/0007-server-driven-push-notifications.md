# Server-driven push notifications via FCM + APNs alongside local notifications

The mobile app uses local notifications (`flutter_local_notifications`) for the persistent "Studying: …" banner during an **Active Session** (ADR-0003) and for break / end-of-session reminders. In addition, the backend gains FCM (Android) + APNs (iOS) integration for server-driven push — re-engagement, weekly summaries, and the social features planned post-mobile-launch (shared sessions / friends-studying / leaderboards). Local-only was rejected because the social roadmap will need server push within months of mobile launch; building the infrastructure once is cheaper than retrofitting.

## Consequences

- Backend adds:
  - A `device_push_tokens` table keyed by `(user_id, device_id)`, storing the FCM or APNs token, platform, and last-seen timestamp.
  - `POST /devices/register-push-token` and `DELETE /devices/push-token` endpoints (gated by `authenticate`).
  - FCM service account JSON + APNs key in env / secrets management.
  - A job runner (likely BullMQ or `node-cron`; deferred to implementation) to schedule weekly-summary and re-engagement pushes.
- Existing per-user single **Authoritative Device** assumption (ADR-0002) is reinforced — push tokens piggyback on `device_id`, so a non-authoritative device's token is invalidated at sync handshake time.
- Push opt-in / opt-out lives in a future "Notifications" settings screen; default is opt-in for transactional pushes (e.g. social interactions) and opt-out for re-engagement nudges, to be reviewed before launch.
- The frozen web app does not get web push; this is a mobile-only capability.

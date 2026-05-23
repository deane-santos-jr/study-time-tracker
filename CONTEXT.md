# Study Time Tracker

Student-focused time tracking with subjects, semesters, study sessions, breaks, and analytics. Backend is a single REST API (Express + TypeORM + MySQL); clients are a frozen React 19 web app and a planned Flutter mobile app for iOS and Android.

## Language

**Study Session**:
A bounded period during which a student is studying one **Subject** within one **Semester**. Has a `startTime`, optional `endTime`, status (`ACTIVE` / `PAUSED` / `COMPLETED`), and zero or more child **Breaks**.
_Avoid_: Timer, study block, study event.

**Active Session**:
The single **Study Session** with `status IN ('ACTIVE', 'PAUSED')` and `endTime IS NULL`. A user has at most one at a time, owned by the **Authoritative Device**.
_Avoid_: Current timer, running session.

**Break**:
A paused interval within a **Study Session**. Has its own `startTime` and `endTime`. Effective study time = session duration minus the sum of all break durations.

**Subject**:
A course or topic a student studies (e.g. "Calculus II", "Filipino"). Belongs to one user. Has a color and optional icon for UI grouping.

**Semester**:
A user-defined academic period with `startDate` and `endDate`. Every **Study Session** belongs to one **Semester**. One semester per user can be `active`.

**Authoritative Device**:
The single device currently logged into an account. For the mobile app, the local SQLite store on this device is the source of truth for the **Active Session** until sync confirms it server-side.
_Avoid_: Primary device, owning device.

**Wall-clock Timer**:
The model where elapsed time is *derived* on every render as `now - startTime - totalBreakSeconds`, never maintained as a live counter in memory. Survives app suspension, kills, and reboots without losing time.
_Avoid_: Persisted counter, ticking timer.

**Sync Queue**:
The local FIFO of mutations (session start / pause / resume / end / break events) waiting to be replayed against the backend after the device is offline. Each entry carries a client-generated UUID for idempotency.
_Avoid_: Outbox, action log, pending writes.

**Note**:
A free-text reflection a student attaches to a completed **Study Session** — what they covered (`topics`), how hard it felt (`difficultyLevel` 1–5), how focused they were (`focusLevel` 1–5), and free `content`. At most one **Note** per **Study Session**.
_Avoid_: Comment, journal entry.

## Relationships

- A **User** owns many **Subjects**, **Semesters**, and **Study Sessions**.
- A **Study Session** belongs to one **Subject** and one **Semester**.
- A **Study Session** has many **Breaks**.
- A **Study Session** has at most one **Note** (attached after the session ends).
- A **User** has at most one **Active Session** at a time, owned by their **Authoritative Device**.
- The **Sync Queue** belongs to one device; on graceful re-login to a new device, any unsynced entries on the old device are abandoned.

## Example dialogue

> **Dev:** "If the student starts a **Study Session** on the bus with no signal, then pauses, the server hasn't seen any of it. What does `/sessions/active` return when they open the web app at home?"
> **Domain expert:** "Nothing — the **Active Session** lives on the **Authoritative Device**. The web app is read-only for sessions; the phone is the source of truth until its **Sync Queue** drains."

## Flagged ambiguities

- "Session" was used to mean both **Study Session** (a study record) and "auth session" (JWT lifetime). Reserved unqualified "session" for **Study Session**; auth lifetimes are "JWT" / "refresh token".

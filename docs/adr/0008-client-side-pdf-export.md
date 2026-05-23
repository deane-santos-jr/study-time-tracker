# PDF export rendered on the mobile client, not the server

PDF reports (sessions, analytics, per-subject, per-semester) are rendered on the Flutter client using the `pdf` + `printing` packages and shared via the native iOS / Android share sheet. The backend exposes no `/export/*` endpoints, contrary to the original plan in `ARCHITECTURE.md`. Offline-first (ADR-0002) requires that a student in a basement classroom can still generate a report from the data already on their device; a server-rendered PDF breaks that. As a side benefit, the backend ships no Puppeteer or PDFKit dependency.

## Consequences

- Mobile analytics math runs on the client over the local SQLite store. The existing `/analytics/*` endpoints on the backend stay in place for the frozen web app and for any future reads but are not used by the mobile PDF flow.
- The `EnvelopeExporter` (or equivalent class in the mobile codebase) is the single place that knows the report layout. If the frozen web app ever ships PDFs, that will be a parallel server-side implementation — deliberate duplication accepted in exchange for the offline-first benefit.
- Older Android devices render multi-page PDFs more slowly than a server would; acceptable for the small report sizes in scope.

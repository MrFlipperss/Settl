# Project Status

Last Updated: 2026-07-28

## Current Project Phase

**Current Phase:** Flutter Foundation

**Current Ticket:** T1.4a – Architecture Alignment

**Overall Progress:** ~18%

---

## Current Priorities

1. Review generated Flutter foundation against `flutter_app_context.md`.
2. Replace direct Supabase repositories with offline-first repositories.
3. Introduce a local database (Drift recommended).
4. Implement the synchronization layer.
5. Begin the core expense workflow.

---

## Phase 0 — Backend Finalization

| Ticket | Status | Notes |
|---------|--------|-------|
| T0.1 Review backend architecture | ✅ | Completed |
| T0.2 Optional group_id | ✅ | Completed |
| T0.3 Contact search endpoint | ✅ | Completed |
| T0.4 Sync metadata | ✅ | Completed |
| T0.5 API verification | ✅ | Completed |

---

## Phase 1 — Flutter Foundation

| Ticket | Status | Notes |
|---------|--------|------|
| T1.1 Create Flutter project | ✅ | Completed |
| T1.2 Architecture | 🟡 | Initial architecture created |
| T1.3 Dependencies | ✅ | Supabase, Riverpod, UUID |
| T1.4 Folder structure | ✅ | Complete |
| T1.4a Architecture Alignment | ⬜ | Next priority |
| T1.5 Routing | 🟡 | Bottom-nav exists, migrate to swipe navigation later |
| T1.6 Environment config | ⬜ | |
| T1.7 HTTP client | 🟡 | Via Supabase client |
| T1.8 Secure storage | ⬜ | |

### Foundation Implemented

```
lib/
├── main.dart
├── app.dart
├── providers.dart
├── theme/
├── routing/
├── models/
├── database/
├── repositories/
├── services/
└── sync/
```

~450 lines of new Dart.

---

## Phase 2 — Theme & Navigation

- Theme: 🟡
- Dark Mode: 🟡
- Light Mode: 🟡
- Theme Switching: ⬜
- Navigation Shell: 🟡
- Swipe Navigation: ⬜

---

## Phase 3 — Local Database

Not started.

---

## Phase 4 — Models

Status: 🟡 Partial

---

## Phase 5 — Repositories

Status: 🟡 Partial

Target architecture:

UI → Repository → Local DB → Sync Layer → Backend

---

## Phase 6 — Authentication

- Login: 🟡
- Signup: 🟡
- Session Restore: ⬜
- Logout: ⬜
- Bootstrap Profile: ⬜
- Token Refresh: ⬜

---

## Phase 7 — API Layer

Status: 🟡 Partial

---

## Phase 8 — Synchronization

- Sync Architecture: 🟡
- Pending Queue: ⬜
- Sync Worker: ⬜
- Retry Strategy: ⬜
- Startup Sync: ⬜
- Connectivity Listener: ⬜
- Conflict Handling: ⬜

---

## Active Decisions

- Offline-first
- People-first UX
- Collections optional
- Local DB is source of truth
- Backend owns business logic
- Material 3
- Minimal UI
- Search-first workflow
- Planned swipe navigation
- Supabase Auth
- Render backend

---

## Known Issues

Current repositories are Supabase-backed. They should be refactored to use a local database with background synchronization before significant feature work continues.

---

## AI Session Checklist

- Read `flutter_app_context.md`
- Read `PROJECT_STATUS.md`
- Complete only one ticket
- Avoid unrelated changes
- Preserve architecture
- Update this file when finished

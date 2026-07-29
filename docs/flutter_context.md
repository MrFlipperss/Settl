# Flutter Frontend Context

## Project Overview

This project is a Flutter frontend for a shared expense application.

Current stack:

- Flutter
- Go backend
- Supabase Authentication
- Local database (offline-first)
- Render hosting (backend)

The current backend is functional but still evolving. The frontend should be designed around the intended product vision rather than current backend limitations wherever possible.

---

# Product Philosophy

This project is not trying to be a feature-heavy expense tracker. The primary goal is to make recording and settling shared expenses feel almost effortless.

Every architectural and UI decision should reinforce the following principles.

## People First

Users think about people, not groups.

The primary workflow is:

Amount → Who Paid → Who Was Involved → Done

Collections (currently represented by backend Groups) are optional conveniences for quickly selecting frequently used sets of people. They should never become the center of the user experience.

---

## Offline First

The application should remain fully usable without an internet connection.

The local database is the source of truth for the UI.

All reads should come from local storage.

User actions should immediately update local state and be synchronized with the backend in the background.

The backend exists primarily as a synchronization and validation service, not as something the UI constantly depends on.

---

## Fast Over Fancy

The application should always feel responsive.

Never wait for network requests before updating the interface.

Prefer optimistic updates whenever possible.

If the backend is unavailable, continue using cached data and synchronize later.

---

## Simplicity Over Features

Every screen should have a single primary purpose.

Avoid overwhelming users with dashboards, statistics or unnecessary information.

Only display what the user needs to complete their current task.

Advanced functionality should be discoverable rather than immediately visible.

---

## Minimal Interaction

Recording an expense should require as few interactions as possible.

Reduce unnecessary confirmations, dialogs and navigation.

One tap is better than three.

---

## Search-Centric UX

The home screen is not a dashboard.

Its primary purpose is to quickly add an expense.

The main interaction should revolve around a prominent search/spotlight style input for finding people and creating expenses.

Additional functionality should be accessible by swiping horizontally to secondary pages rather than cluttering the home screen.

---

## Invisible Synchronization

Users should rarely think about synchronization.

The application should quietly:

- synchronize in the background
- retry failed operations automatically
- wake the backend when needed
- continue functioning offline

Temporary network issues should not interrupt normal usage.

---

## Server Responsibilities

Authentication is handled by Supabase.

Business rules remain server-side, including:

- balance calculations
- split validation
- settlement logic
- data sharing between users

The frontend should never duplicate business logic that belongs on the backend.

---

## Future-Proof Architecture

The frontend should be designed around the intended product, not current backend limitations.

Backend implementation details (such as mandatory `group_id`s) should be abstracted behind repositories and services so future backend improvements require minimal UI changes.

The architecture should prioritize maintainability and adaptability over short-term convenience.

---

# Things We Deliberately Avoid

- Information-heavy dashboards
- Unnecessary statistics on the home screen
- Modal confirmations unless destructive
- Blocking loading screens when cached data exists
- UI that exposes backend implementation details
- Features that do not improve the core expense-sharing workflow

---

# Backend Configuration

Backend URL:

https://settl-kru1.onrender.com

Supabase URL:

https://rgrswhlyuvpicfbajhen.supabase.co

Authentication is performed entirely through Supabase.

The backend accepts the Supabase JWT as a Bearer token.

---

# Authentication Flow

1. Login or sign up using Supabase.
2. Retrieve the Supabase access token.
3. Use the token for every backend request.
4. Bootstrap the backend by ensuring the user profile exists.
5. Load initial application data.

---

# Application Startup

On launch:

1. Open local database.
2. Display cached data immediately.
3. Send a background request to `/health` to wake the Render backend.
4. Begin synchronization.
5. Refresh the local database.

The user should never wait on the backend to begin using the application.

---

# Offline Architecture

The local database is the source of truth.

The UI never communicates directly with HTTP.

All writes:

User Action

↓

Save locally

↓

Queue sync operation

↓

Background synchronization

↓

Server confirmation

↓

Update local database if needed

Reads always come from local storage.

---

# Synchronization Principles

- Synchronization is invisible.
- Network failures should not interrupt the user.
- Failed operations remain queued.
- Retry automatically.
- Optimistic updates are preferred.

Future synchronization should support incremental syncing rather than downloading all data.

---

# Data Ownership

Authentication:
- Supabase

Business Logic:
- Go Backend

UI State:
- Local Database

Synchronization:
- Backend ↔ Local Database

The backend remains authoritative for:

- balances
- settlements
- split validation
- ownership
- sharing logic

---

# Backend API

The HTML API test console represents the canonical API contract.

It documents:

- authentication flow
- profile creation
- contacts
- groups
- members
- expenses
- balances

The Flutter frontend should follow its request payloads and responses but should not copy its online-first networking approach.

---

# Product Model

Current backend:

Group

↓

Expense

Target product:

People

↓

Expenses

↓

Balances

↓

Collections

Collections should simply be reusable participant lists.

They should never be required before creating an expense.

---

# Expense Flow

Preferred UX:

Enter Amount

↓

Choose Payer

↓

Search People

↓

Choose Split

↓

(Optional) Select Collection

↓

Save

---

# Collections

Collections are optional.

They exist to save frequently used participant sets.

Selecting a collection should pre-populate participants, but users should still be free to modify the participant list.

The UI should present "Collections" instead of "Groups."

---

# Error Philosophy

- Never interrupt the user for temporary network failures.
- Validation errors should appear immediately.
- Synchronization failures remain queued.
- Authentication failures should log the user out.
- Cached data should always remain available.

---

# Performance Guidelines

- Avoid unnecessary rebuilds.
- Cache aggressively.
- Do not refetch data on every navigation.
- Prefer incremental updates.
- Lazy-load expensive resources where appropriate.

---

# Security

- Store authentication tokens securely.
- Never log JWTs.
- Never trust client-side calculations.
- Validate business rules server-side.

---

# Design Direction

The visual language should be:

- Minimal
- Clean
- Fast

Target inspirations:

- Material 3 / Material You
- Light Mode
- Dark Mode
- Apple Liquid Glass influences where appropriate

Avoid visual clutter.

Whitespace is preferred over excessive information density.

---

# Navigation

The application should not rely on a traditional information-heavy dashboard.

The home page should focus on:

- quick expense creation
- people search

Secondary functionality should be accessible through horizontal swiping to dedicated pages.

---

# Future Improvements

The architecture should anticipate support for:

- Incremental synchronization
- Background synchronization
- Push notifications
- Scheduled reminders

without requiring major structural changes.

---

# Backend Improvements Planned

The current backend works but should eventually evolve to support:

- Optional `group_id` on expenses.
- Contact search endpoint.
- Client-generated UUIDs.
- Synchronization metadata (`updated_at`, `deleted_at`, etc.).
- Incremental sync endpoints.

The Flutter architecture should be designed so these backend improvements require minimal frontend changes.
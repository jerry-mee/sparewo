# SpareWo Incident Report: Signup, Partial Onboarding, App Check, Notifications, and Auth Flow Regressions

**Prepared on:** February 20, 2026  
**Prepared for:** Senior Engineering Review  
**Scope:** iOS real-device behavior (iPhone 11), Flutter client (`sparewo_client_modified`), Firebase App Check/Auth/Firestore/Functions interactions, and related cross-app integration attempts.

---

## 1) Report Intent and Evidence Base

This document is a **chronological, descriptive incident record** of issues encountered, fixes attempted, and observed outcomes.  
It consolidates:
- Runtime logs shared during repeated iPhone 11 test cycles.
- Prior written assessments:
  - `/Users/jeremy/Development/sparewo/sparewo_client_modified/security_assessment.md`
  - `/Users/jeremy/.gemini/antigravity/brain/8c47d32b-4a33-4ac6-811f-be9f42084627/assessment.md`
  - `/Users/jeremy/Development/sparewo/sparewo_client_modified/reassessment_way_forward_2026-02-19.md`
  - `/Users/jeremy/Development/sparewo/sparewo_client_modified/reassessment_way_forward_2026-02-20.md`
  - `/Users/jeremy/Development/sparewo/sparewo_client_modified/firestore_audit_2026-02-19.md`
- Local repository state and changed-file footprint at time of report.
- Fresh command validation results run for this report.

This report intentionally contains **no remediation recommendations**.

---

## 2) Initial Baseline (Pre-Incident Context)

### 2.1 Security and architecture baseline findings
Earlier assessments identified:
- Sensitive key exposure patterns (`.env`, service-account handling, client-side email key usage).
- Auth/cart/provider coupling issues.
- Guest vs authenticated state transition fragility.
- Rule/model drift risks across client/admin/vendor apps.

### 2.2 Functional baseline that was reported as expected prior to regressions
- Push notifications were observed working in at least some flows.
- Booking creation and status-change events partially propagated (email + in-app notifications in some scenarios).

---

## 3) Chronological Incident Timeline

## Phase A — First major crash sequence after logout/login/cart transitions
**Observed on:** Feb 19, 2026 (device logs provided)

### A.1 Primary runtime failures observed
1. Repeated App Check backend failures:
   - `FAILED_PRECONDITION` with `App not registered`.
2. Firestore permission errors after logout:
   - `[cloud_firestore/permission-denied] The caller does not have permission...`
3. Navigation framework assertions:
   - `!navigator._debugLocked`
   - `!_debugLocked` during `NavigatorState.dispose`
4. App instability/glitching while transitioning between guest and authenticated actions.

### A.2 Notable supporting signals
- `CarRepository` switching between valid user snapshots and `userId is null` states around logout.
- APNS readiness retries and skipped FCM token fetches.

### A.3 Outcome at end of Phase A
- Crash/glitch was reproducible.
- Root symptom cluster established: auth teardown + listener/navigation race + backend auth/token instability.

---

## Phase B — Firebase/App Check console updates and token setup attempts
**Observed on:** Feb 19–20, 2026

### B.1 User-side config actions recorded
- Firebase login completed for project context.
- Firebase MCP server added for monorepo directory.
- App Check iOS app registration shown as enabled (DeviceCheck + App Attest in console).
- iPhone debug token configured (`7A486195-9D74-4592-B885-75656FB95D1E`) and visible in console.

### B.2 Runtime change in failure mode
- App Check moved from earlier `400 App not registered` to repeated `403 App attestation failed`.
- This indicates registration-state error changed to attestation-validation failure state.

### B.3 Outcome at end of Phase B
- App Check failures persisted in runtime despite console registration/debug-token presence.

---

## Phase C — Admin communications/notifications failure investigation
**Observed on:** Feb 20, 2026

### C.1 Primary runtime failure
- Admin dashboard send operation failed:
  - `WriteBatch.set() called with invalid data. Unsupported field value: undefined (found in field link ...)`

### C.2 Changes attempted for this issue
- Hardened notification/comms write paths to omit undefined `link` payloads.
- Added/expanded individual recipient flows.

### C.3 Outcome
- Fixes were implemented in admin-side code paths, but user still reported broader instability across systems and unresolved onboarding/auth issues.

---

## Phase D — Firestore/rules/index harmonization effort
**Observed on:** Feb 20, 2026

### D.1 Actions performed
- Rules/index files synchronized and deployed from monorepo contexts.
- Firestore dry-runs and deploy attempts were executed.

### D.2 Reported status in prior reassessment artifact
- Firestore rules/index deploy reported successful from one app root.
- Additional remote indexes remained outside local spec (not force-pruned).

### D.3 Outcome
- Infrastructure alignment improved on paper and in deployment logs, but did not resolve the user-reported signup/partial-onboarding runtime behavior.

---

## Phase E — Signup UX and onboarding state-machine change cycle
**Observed on:** Feb 20, 2026 (multiple retests)

### E.1 User-reported failures during this cycle
1. Signup flow crash / no progress.
2. Poor field behavior and ordering concerns.
3. Password helper visibility/scroll behavior issues.
4. Missing/insufficient feedback for:
   - email taken/available,
   - password mismatch,
   - offline/network state.
5. Google sign-up/login onboarding routing mismatch.
6. Partial onboarding handling failed expectations.
7. Verification-screen visual/readability issues (dark mode text invisibility).
8. Verification-field copy/paste caused assertion crash in one run.
9. Silent redirect/jump behavior persisted (login to sign-up with no clear message).
10. User reported auth modal UX regression (“auth modal popup gone”).

### E.2 Backend/email interaction failures observed during these tests
- `DotEnv NotInitializedError` in signup path after environment hardening changes.
- Email service warnings: Resend key unavailable in some runs.
- Later logs showed Cloud Function email path sending successfully (`Email sent successfully via Cloud Function (Resend)`).
- Verification sender/branding/template path oscillated between Firebase default and branded expectations during transition period.

### E.3 Outcome
- Despite multiple code adjustments, user-reported behavior remained unacceptable: stuck signup state, incorrect email availability signals for half-onboarded accounts, silent routing failures, and verification UI defects.

---

## Phase F — Latest reported state (current blocking condition)
**Observed on:** Feb 20, 2026, latest logs/test feedback

### F.1 User-stated current blockers
- “None of the fixes worked.”
- Still stuck at signup with half-onboarded account.
- Email still appears available when it should not.
- Silent transitions still occur.
- App Check attestation 403 spam remains present.

### F.2 Runtime signatures still present in latest logs
- Repeated App Check 403 (`PERMISSION_DENIED`, `App attestation failed`, often with “Too many attempts”).
- APNS not-ready retry loop and skipped FCM fetch messages.
- Verification emails being sent via Cloud Function/Resend while auth/onboarding state remains inconsistent.

---

## 4) Fix Attempt Ledger (Code-Level)

The following local code-change footprint is present at report time:

```text
ios/Podfile.lock
ios/Runner/AppDelegate.swift
lib/core/router/app_router.dart
lib/features/auth/application/auth_provider.dart
lib/features/auth/data/auth_repository.dart
lib/features/auth/presentation/email_verification_screen.dart
lib/features/auth/presentation/login_screen.dart
lib/features/auth/presentation/signup_screen.dart
lib/features/auth/presentation/widgets/auth_guard_modal.dart
lib/features/shared/services/email_service.dart
macos/Podfile.lock
```

`git diff --stat` summary:
- **11 files changed**
- **860 insertions**, **247 deletions**

### 4.1 Attempt categories represented in these edits
1. **Auth/navigation gating**
   - Router/auth guards and modal flow timing adjustments to prevent route lock/assertion failures.
2. **Signup and partial-onboarding state logic**
   - Existing-email handling, partial setup handling, signup/login branching behavior.
3. **Verification UX handling**
   - Field behavior, selection/paste handling, readability styling paths.
4. **Email sending path migration/hardening**
   - Client email behavior changes toward cloud function path and dotenv handling adjustments.
5. **iOS App Check native provider wiring**
   - AppDelegate-level App Check provider setup updates.

### 4.2 Observed net effect from user retests
- User reports unresolved or regressed behavior in critical signup/onboarding path despite these edits.

---

## 5) Test and Validation Results

## 5.1 Historical results cited during this incident window
- Earlier targeted validation runs had reported successful analyze/test/build in specific checkpoints.
- These did not correlate with successful real-device signup/onboarding outcomes.

## 5.2 Fresh validation run for this report (current workspace)

### A) Static analysis
Command:
```bash
flutter analyze
```
Result:
- Exit code: `1` (lint-level infos present)
- Output summary: `4 issues found` (all `info` severity)
- Reported items:
  - `curly_braces_in_flow_control_structures` (settings screen)
  - several `prefer_const_constructors` infos

### B) Unit/widget tests
Command:
```bash
flutter test
```
Result:
- Exit code: `0`
- Output: `All tests passed!`
- Test observed: `ProviderScope and MaterialApp smoke test`

### C) iOS debug build compilation
Command:
```bash
flutter build ios --debug --no-codesign
```
Result:
- Exit code: `0`
- Build output: `✓ Built build/ios/iphoneos/Runner.app`

### 5.3 Test result interpretation boundary
- Build/test success does **not** match current runtime acceptance from user on real signup/onboarding flow.

---

## 6) Issue Inventory by Symptom Class (As Encountered)

## 6.1 Auth/onboarding lifecycle
- Half-onboarded accounts mishandled across signup/login branches.
- Existing-email detection inconsistent with expected behavior.
- Silent routing transitions with no explanatory UI.
- Incomplete setup state not reliably resumed in user-facing flow.

## 6.2 Verification UX and correctness
- Visibility/readability regressions (dark mode code field text).
- Copy/paste interactions triggered crash/assertion in at least one run.
- Verification completion state sometimes inferred incorrectly from user perspective.

## 6.3 Firebase App Check / APNS signals
- Transition from 400 registration failures to persistent 403 attestation failures.
- Repeated “Too many attempts” noise.
- APNS token readiness delays and skipped FCM fetch logs recurring.

## 6.4 Email delivery path behavior during migration
- Periods of dotenv/key-not-initialized failures.
- Periods of Cloud Function/Resend success.
- Sender/branding/template expectation mismatches reported during transition.

## 6.5 Ancillary runtime errors encountered during broader testing
- Firestore permission-denied events around auth transitions.
- JSON encoding issue for Firestore `Timestamp` in notification listener path.
- Render overflow in AutoHub conversational screen.
- Admin dashboard notification write failure due to undefined payload field.

---

## 7) Environment and Operational Context Captured

- Device: **iPhone 11** (physical device).
- Firebase project: **`sparewoapp`**.
- Firestore DB: default database in `africa-south1`.
- App Check debug token in panel: **`7A486195-9D74-4592-B885-75656FB95D1E`**.
- Console evidence showed iOS app registered with DeviceCheck/App Attest and debug token entry present.
- Runtime still shows repeated attestation failures.

---

## 8) Current State Snapshot (At Report Generation)

1. Multiple auth/onboarding fixes have been attempted in code.
2. Local analysis/tests/build are passing at compile/test level (with non-blocking info lints).
3. User acceptance for the core signup + half-onboarded recovery flow is **failed**.
4. App Check attestation errors remain visible in runtime logs.
5. Senior-engineering review is required on the full state machine, Firebase/Auth/App Check interplay, and verification/onboarding orchestration.

---

## 9) Appendix: Files Referenced

- `/Users/jeremy/Development/sparewo/sparewo_client_modified/security_assessment.md`
- `/Users/jeremy/.gemini/antigravity/brain/8c47d32b-4a33-4ac6-811f-be9f42084627/assessment.md`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/reassessment_way_forward_2026-02-19.md`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/reassessment_way_forward_2026-02-20.md`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/firestore_audit_2026-02-19.md`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/core/router/app_router.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/application/auth_provider.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/data/auth_repository.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/presentation/email_verification_screen.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/presentation/login_screen.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/presentation/signup_screen.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/presentation/widgets/auth_guard_modal.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/shared/services/email_service.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/ios/Runner/AppDelegate.swift`


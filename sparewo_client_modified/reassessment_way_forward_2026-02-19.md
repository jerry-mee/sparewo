# SpareWo Reassessment and Way Forward (Post-Fix)

Date: February 19, 2026  
Scope: `sparewo_client_modified` app behavior, iOS real-device stability, Firebase/App Check/Crashlytics readiness, monorepo Firebase linkage sanity.

## 1) Executive Summary

This reassessment confirms your reported crash/glitch sequence is real and reproducible from the logs:

1. User logs out.
2. App still has active listeners and UI callbacks that race auth/navigation transitions.
3. Firestore listeners hit permission-denied during teardown window.
4. A modal success flow triggers navigation while navigator is locked.
5. Result: `_debugLocked` assertions and widget tree finalization crashes in debug.

In parallel, App Check and notification setup had configuration gaps:

- iOS App Check token exchange was failing repeatedly with `App not registered` / `FAILED_PRECONDITION` in your runtime logs.
- APNS token readiness remained unstable on device startup/logout/login transitions.
- Crashlytics was initialized in Dart but iOS dSYM upload pipeline was incomplete.

## 2) What I Implemented (Code Changes Applied)

## 2.1 Auth Modal Navigator Race Fix

File: `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/presentation/widgets/auth_guard_modal.dart`

Change made:

- `_completeAuthSuccess()` now pops the modal first and defers post-login callback/navigation to the next frame.

Why:

- Prevents `Navigator` re-entrant operations during transition lock (`!_debugLocked` assertions).

## 2.2 Listener Lifecycle Hardening in App Root

File: `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/main.dart`

Changes made:

- Moved auth-related listeners to `listenManual` setup during service init (instead of re-attaching in `build`).
- Switched listener source to `authStateChangesProvider` (Firebase auth stream) for immediate UID transitions.
- Explicitly stop Firestore notification listener on logout.
- Added `onError` handling for booking approval listener.
- Dispose now closes provider subscriptions and tears down notification listener.
- Removed eager debug `FirebaseAppCheck.getToken()` call to avoid repeated startup token spam.

Why:

- Prevents stale listeners from surviving logout transitions.
- Reduces race window where permission-denied errors bubble as uncaught zone errors.
- Stabilizes app lifecycle around login/logout.

## 2.3 Notification Service Teardown + Error Handling

File: `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/shared/services/notification_service.dart`

Changes made:

- Added tracked token-refresh subscription and proper disposal.
- Added `stopFirestoreNotificationListener()` and call path support.
- Added listener `onError` logging for Firestore notifications stream.

Why:

- Ensures clean shutdown on logout and reduces ghost subscriptions.

## 2.4 Car Stream Auth Source Correction + Permission Guard

Files:

- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/my_car/application/car_provider.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/my_car/data/car_repository.dart`

Changes made:

- Car repository/provider now derive identity from `authStateChangesProvider` (`uid`) instead of profile model stream.
- When logged out, cars provider returns empty stream immediately.
- Car stream implementation updated to `async*` with `FirebaseException` handling for `permission-denied`.

Why:

- Prevents delayed auth/profile mismatch from keeping a now-invalid Firestore listener alive.
- Avoids permission-denied surfacing as fatal-ish uncaught stream errors during logout.

## 2.5 Guest Cart Migration Safety

File: `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/cart/application/cart_provider.dart`

Changes made:

- Added guards against duplicate listener registration and concurrent cart migration.
- Migration now keeps failed items locally instead of clearing all guest items blindly.
- Strengthened login transition migration refresh with transient race protection.

Why:

- Prevents duplicate migration triggers.
- Prevents data loss when some cart writes fail.

## 2.6 Splash Navigation Conflict Removed

File: `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/presentation/splash_screen.dart`

Change made:

- Removed manual delayed `context.go(...)` from splash screen; routing is left to router redirect logic.

Why:

- Removes dual-navigation ownership (splash + router redirect), which contributes to navigator lock contention.

## 2.7 iOS Crashlytics and APNs Entitlements Pipeline

Files:

- `/Users/jeremy/Development/sparewo/sparewo_client_modified/ios/Runner.xcodeproj/project.pbxproj`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/ios/Runner/RunnerDebug.entitlements`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/ios/Runner/RunnerRelease.entitlements`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/firebase.json`

Changes made:

- Added Crashlytics run script build phase (`${PODS_ROOT}/FirebaseCrashlytics/run`) with dSYM input paths.
- Added iOS entitlements wiring:
  - Debug -> `RunnerDebug.entitlements` (`aps-environment = development`)
  - Release/Profile -> `RunnerRelease.entitlements` (`aps-environment = production`)
- Set FlutterFire iOS `uploadDebugSymbols` to `true`.

Why:

- Makes Crashlytics symbol upload and issue surfacing much more reliable.
- Ensures APNs entitlement is explicitly configured per build type.

## 2.8 Monorepo Firebase Linkage Alignment

File:

- `/Users/jeremy/Development/sparewo/sparewo_vendor/.firebaserc`

Change made:

- Updated vendor project mapping from `sparewo-vendor` to `sparewoapp` (keeping hosting target/site mapping).

Why:

- Aligns vendor app config with your target unified Firebase project.

## 3) Validation Run

Command run:

- `flutter analyze`

Result:

- No compile errors from these changes.
- 4 informational lint warnings remain (non-blocking, pre-existing style/deprecation cleanup).

## 4) Interpretation of Your New Firebase Console Screenshots

## 4.1 App Check Debug Token Input Error

You entered `1:858...:ios:...` as debug token value. That is **App ID**, not debug token.

Correct behavior:

- Debug token must be a UUID v4 value.
- Either click **Generate token** in Firebase console dialog, or use the runtime-generated debug token from logs when using App Check debug provider.

## 4.2 Why `App not registered` Happened Despite Seeing “Registered”

Given your screenshot shows iOS app registered with App Attest, and runtime still hit `exchangeDeviceCheckToken` with `App not registered`, the most likely causes are:

1. Runtime attempted a different attestation path/token than what is actually enabled for that app context.
2. Local app build was using stale Firebase iOS config metadata at that moment.
3. Debug path and App Check console token setup were mixed incorrectly.

The code changes reduce token-fetch noise and crash risk, but console-side App Check verification still needs to be completed with the exact steps below.

## 5) Remaining Firebase Console Actions (You Must Do)

## 5.1 App Check (iOS Client App)

1. Firebase Console -> App Check -> iOS `com.sparewo.client`.
2. Keep App Attest enabled.
3. In Manage debug tokens, add a valid UUID v4 token (not app id string).
4. Start in Monitoring mode (already true in your screenshot) until verified request ratio is healthy.
5. Only then enforce for Firestore/Storage/Auth in stages.

## 5.2 APNs + Messaging

1. Confirm Apple Developer key `UZ929YY9AC` is linked to Firebase Cloud Messaging settings for the same app bundle id `com.sparewo.client`.
2. Run fresh iOS build after entitlement changes.
3. Verify logs now show APNS token present before FCM token fetch.
4. Send Firebase test push to this physical iPhone 11 and confirm receipt foreground/background/terminated.

## 5.3 Crashlytics Visibility

1. Build and run app once on device (Debug okay for smoke, Release preferred for prelaunch fidelity).
2. Trigger a non-fatal test exception in app.
3. Trigger one fatal crash test in a controlled build.
4. Confirm both appear in Crashlytics dashboard with symbolicated stack traces.

## 6) Cloud Functions Handholding Plan (Practical Sequence)

This is the low-risk order:

1. Create or verify `/functions` in monorepo apps that need privileged backend logic.
2. Move sensitive client operations to functions first:
   - Email sending (Resend)
   - Any admin privilege operations
3. Add App Check enforcement on callable/https functions after clients send valid App Check token.
4. Add structured function logging and alerts.
5. Deploy to staging project first, then production.

If you want, next pass I can implement this end-to-end in your monorepo with:

- Function skeletons
- Secret manager wiring
- client callable integration
- deployment checklist and rollback commands

## 7) MCP Access Clarification (Firebase MCP)

You already added Firebase MCP globally:

- `codex mcp add firebase -- firebase mcp --dir /Users/jeremy/Development/sparewo`

That is the correct setup for whole-monorepo context.

Expected note:

- `codex mcp list` may show Auth as `Unsupported` for Firebase server; this is normal for current CLI MCP integration mode and does not mean the server is unusable.

To verify scope:

1. `firebase login:list` -> should show `admin@sparewo.ug`.
2. `firebase mcp --dir /Users/jeremy/Development/sparewo --generate-tool-list`.
3. Use MCP environment update/read tools (or CLI) to confirm active project and project directory.

## 8) Website Linkage Decision

Per your update, `sparewo_website` is informational Vite and does not require Firebase linkage unless you later add:

- Auth
- Firestore/Storage reads
- Cloud Functions calls
- Hosting rewrites to Firebase-backed APIs

No changes were made there.

## 9) Risk Register After This Patch

Current risk status after code-level fixes:

- Navigation lock crash on auth modal flow: **Mitigated (code)**
- Logout listener permission-denied cascades: **Mitigated (code)**
- Guest cart migration item loss: **Mitigated (code)**
- App Check iOS registration/debug token mismatch: **Pending (console action)**
- APNs token readiness: **Partially mitigated (code + entitlements), needs console/device validation**
- Crashlytics no-data complaint: **Partially mitigated (build phase), needs runtime verification**

## 10) Immediate UAT Script (Real iPhone 11)

Run exactly this flow after pulling these changes:

1. Fresh install app on device.
2. Open app as guest -> add 2 items to cart.
3. Sign in -> confirm cart merges and remains stable.
4. Sign out -> add 1 guest cart item.
5. Sign back in -> confirm:
   - no crash
   - no UI freeze
   - cart state is consistent
   - no `_debugLocked` assertion
6. Trigger local and push notification checks.
7. Trigger Crashlytics test event and confirm dashboard ingestion.

## 11) File-Level Change Log

- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/presentation/widgets/auth_guard_modal.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/main.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/shared/services/notification_service.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/my_car/application/car_provider.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/my_car/data/car_repository.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/cart/application/cart_provider.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/presentation/splash_screen.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/ios/Runner.xcodeproj/project.pbxproj`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/ios/Runner/RunnerDebug.entitlements`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/ios/Runner/RunnerRelease.entitlements`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/firebase.json`
- `/Users/jeremy/Development/sparewo/sparewo_vendor/.firebaserc`

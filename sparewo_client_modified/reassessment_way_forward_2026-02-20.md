# SpareWo Reassessment and Way Forward (Updated)
**Date:** February 20, 2026  
**Project:** `sparewoapp` (Firestore default DB, `africa-south1`)  
**Scope:** Client app, Vendor app, Admin dashboard, Firebase configuration and Firestore alignment

## 1. Executive Summary
This reassessment confirms the primary instability was a combination of:
- Auth-transition race conditions (signed-in streams/navigation still active at logout/login boundaries).
- Firestore schema drift across apps (`featured` vs `isFeatured`, old/new collections).
- Firestore rule/index/deploy drift between monorepo apps.
- Invalid admin comms payload (`link: undefined`) causing batch write failures.

All high-priority code and Firebase config fixes identified in this cycle have now been implemented, and Firestore rules/indexes were deployed to production successfully on **February 20, 2026**.

## 2. What Was Fixed in This Cycle

### 2.1 Admin communications workflow + runtime failure
**Problem:** Sending communications could fail with:
`WriteBatch.set() called with invalid data. Unsupported field value: undefined (field link)`

**Fixes implemented:**
- Hardened notification/comms writes to omit `link` when empty/undefined.
- Added **individual messaging** flow (target one client/vendor) in addition to broadcast.
- Added recipient discovery/search for individual sends.
- Kept batch delivery behavior for broadcasts.

**Files updated:**
- `/Users/jeremy/Development/sparewo/sparewo_admin/src/app/dashboard/comms/page.tsx`
- `/Users/jeremy/Development/sparewo/sparewo_admin/src/lib/firebase/comms/index.ts`
- `/Users/jeremy/Development/sparewo/sparewo_admin/src/lib/firebase/notifications.ts`
- `/Users/jeremy/Development/sparewo/sparewo_admin/src/lib/firebase/notifications/index.ts`

---

### 2.2 Catalog schema mismatch (`featured` vs `isFeatured`) and batch logic bug
**Problem:** Mixed field names caused inconsistent reads/filters, and bulk creation reused a committed batch (unsafe).

**Fixes implemented:**
- Standardized catalog filtering and updates on `isFeatured`.
- Added backward-compatible read fallback (`isFeatured ?? featured ?? false`).
- Fixed bulk create batch handling to recreate batch after commit and avoid invalid reuse.

**File updated:**
- `/Users/jeremy/Development/sparewo/sparewo_admin/src/lib/firebase/products/index.ts`

---

### 2.3 Client auth-transition crash/glitch hardening
**Problems observed in logs:**
- Firestore permission errors after logout.
- Navigator lock assertions (`!navigator._debugLocked`, `!_debugLocked`) during auth transitions.

**Fixes implemented:**
- Hardened route guard: guest users are redirected away from auth-required routes (`/orders`, `/my-cars`, `/addresses`, etc.).
- Converted fragile guest nav action from `push` to `go` in bottom shell.
- Reduced re-entrant auth navigation in login flow.
- Made cart/my-car streams more defensive during auth changes.
- Notification deep-link handling now navigates safely using post-frame `go`.

**Files updated:**
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/core/router/app_router.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/core/widgets/scaffold_with_nav_bar.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/presentation/login_screen.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/cart/application/cart_provider.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/my_car/application/car_provider.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/my_car/data/car_repository.dart`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/shared/services/notification_service.dart`

---

### 2.4 Vendor stats alignment and runtime safety
**Problem:** Vendor stats logic had collection/field alignment risk and brittle enum parsing.

**Fixes implemented:**
- Aligned stats reads to `vendor_products` + `order_fulfillments`.
- Hardened status parsing with safe defaults.
- Hardened numeric/date handling to avoid runtime failures on sparse docs.

**File updated:**
- `/Users/jeremy/Development/sparewo/sparewo_vendor/lib/services/stats_service.dart`

---

### 2.5 Firestore rules hardening (security + behavior)
**Fixes implemented:**
- Removed permissive list loopholes in `clients` and `vendors`.
- Added constrained vendor update path for `order_fulfillments` (ownership + immutable linkage checks + allowed fields only).
- Hardened `userRoles` self-create to prevent privilege escalation.
- Restricted `counters` collection to admin.

**Files updated:**
- `/Users/jeremy/Development/sparewo/sparewo_vendor/firestore.rules`
- Synced copies:
  - `/Users/jeremy/Development/sparewo/sparewo_client_modified/firestore.rules`
  - `/Users/jeremy/Development/sparewo/sparewo_admin/firestore.rules`

---

### 2.6 Firestore indexes and monorepo deploy linkage
**Fixes implemented:**
- Expanded composite indexes to match active query patterns.
- Removed invalid index definition (`admin_communications` single-field composite).
- Added Firestore config to all `firebase.json` files.
- Placed rules/index files locally per app folder (Firebase CLI disallows outside-project references).

**Files updated:**
- `/Users/jeremy/Development/sparewo/sparewo_vendor/firestore.indexes.json`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/firestore.indexes.json`
- `/Users/jeremy/Development/sparewo/sparewo_admin/firestore.indexes.json`
- `/Users/jeremy/Development/sparewo/sparewo_vendor/firebase.json`
- `/Users/jeremy/Development/sparewo/sparewo_client_modified/firebase.json`
- `/Users/jeremy/Development/sparewo/sparewo_admin/firebase.json`

## 3. Firebase Deployment/Validation Status

### 3.1 Firestore dry-runs
Confirmed in all 3 app folders:
- `sparewo_vendor`: PASS
- `sparewo_client_modified`: PASS
- `sparewo_admin`: PASS

### 3.2 Firestore deploy
Executed from vendor app:
- `firebase deploy --only firestore:rules,firestore:indexes --project sparewoapp`
- Status: **SUCCESS** (rules + indexes deployed)

Note: Firebase reported 8 existing remote indexes not present in local index file (not deleted because `--force` was not used).

## 4. App Check + APNs + Crashlytics Notes (Critical)

### 4.1 App Check (iPhone debug)
Your earlier 400 errors (`App not registered`) were from App Check token path mismatch/registration state during debug setup. You now generated a valid debug token UUID.

Production posture:
- Keep iOS provider as `App Attest` for release builds.
- Keep debug token only for development device(s).
- Do **not** enforce App Check in Firebase until all client/vendor/admin apps show stable verified request ratios.

### 4.2 APNs token timing warnings
`APNS not ready` warnings are common on cold launch timing; now handled with retries and non-fatal fallback.

### 4.3 Crashlytics “no logs” explanation
Common reasons:
- Running debug sessions where crash reports are delayed/not surfaced as expected.
- AppLogger console logs are not the same as Crashlytics events.
- Need at least one forced test crash from the exact app/build variant and correct GoogleService plist/json mapping.

## 5. Remaining Risks (Post-Fix)
1. The rule helper warning in Firestore (`isVendorOwner` unused / naming warning) is non-blocking but should be cleaned.
2. Monorepo now contains 3 copies of rules/index files; drift risk exists unless sync is enforced.
3. Vendor app has many legacy analyzer warnings (not release blockers for this specific fix set, but technical debt remains).

## 6. Immediate Next Steps (Handheld Runbook)
1. **Real-device regression test (iPhone 11):**
   - Login -> add cart items -> logout -> guest cart actions -> login again -> checkout/cart/profile transitions.
   - Confirm no permission-denied crash and no navigator assertion.
2. **Admin comms validation:**
   - Send broadcast to all clients.
   - Send individual message to one client.
   - Send individual message to one vendor.
   - Verify documents in `admin_communications` and `notifications` and in-app receipt.
3. **Crashlytics verification:**
   - Trigger one controlled test crash from iOS debug and release-like build.
   - Confirm it appears in Firebase Crashlytics dashboard.
4. **App Check rollout:**
   - Keep monitoring mode while tracking verified/unverified ratio.
   - Move to enforcement only after stable pass rates for client/vendor/admin.
5. **Rules/index sync policy:**
   - Treat `sparewo_vendor/firestore.rules` and `sparewo_vendor/firestore.indexes.json` as source of truth.
   - Sync copies into admin/client on every Firebase change before deploy.

## 7. Production-Readiness Verdict
- **Firestore security posture:** materially improved and now deploy-consistent.
- **Cross-app schema alignment:** significantly improved, key breakpoints fixed.
- **Critical user flow stability:** patched for known logout/login/cart/navigation race paths.
- **Overall:** not "done forever," but now in a substantially safer pre-launch state with the highest-impact blockers addressed.

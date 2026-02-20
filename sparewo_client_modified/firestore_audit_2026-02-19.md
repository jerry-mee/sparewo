# Firestore Audit (SpareWo Monorepo)

Date: February 19, 2026

## Scope
- `/Users/jeremy/Development/sparewo/sparewo_client_modified`
- `/Users/jeremy/Development/sparewo/sparewo_admin`
- `/Users/jeremy/Development/sparewo/sparewo_vendor`
- Firestore rules/index config in repo

## Live Firebase Access Status
I retried live inspection after reauthentication, but direct Firebase API access from this shell environment is blocked by DNS/network resolution:
- Error observed: `curl: (6) Could not resolve host: firestore.googleapis.com`
- Firebase CLI calls that need Google API access fail accordingly.

This means findings below are from code/rules/index artifacts in the repo (static audit), not from direct readback of currently deployed prod rules/indexes.

## Verdict
Firestore is **not prod-ready yet** and is **not fully aligned** with all application code paths.

## Critical Findings

1. Privilege escalation path via `userRoles` create rule.
- File: `/Users/jeremy/Development/sparewo/sparewo_vendor/firestore.rules`
- Rule block allows user to create own `userRoles/{uid}` doc:
  - `allow create: if isSignedIn() && (request.auth.uid == userId || isAdmin());`
- Same ruleset uses `userRoles` as an authority source for admin/staff checks.
- Impact: authenticated user can potentially self-assign elevated role.

2. Firestore rules/indexes are not centrally managed in Firebase config.
- Files:
  - `/Users/jeremy/Development/sparewo/sparewo_vendor/firebase.json`
  - `/Users/jeremy/Development/sparewo/sparewo_client_modified/firebase.json`
  - `/Users/jeremy/Development/sparewo/sparewo_admin/firebase.json`
- None contains a `firestore` section mapping `rules` and `indexes` for deploy orchestration.
- Impact: high drift risk between repo and production; no reliable IaC deployment path for rules/indexes.

## High Findings

1. Vendor app writes are incompatible with current rules for fulfillments.
- Vendor code updates fulfillments:
  - `/Users/jeremy/Development/sparewo/sparewo_vendor/lib/services/order_service.dart`
- Rules allow create/update/delete on `order_fulfillments` only for admin:
  - `/Users/jeremy/Development/sparewo/sparewo_vendor/firestore.rules`
- Impact: vendor order status actions can fail at runtime if executed with client SDK auth.

2. Vendor app queries collections not clearly covered for write/read parity.
- Vendor code references: `products`, `counters`, `reviews`, `userRoles`, etc.
  - `/Users/jeremy/Development/sparewo/sparewo_vendor/lib/services/stats_service.dart`
  - `/Users/jeremy/Development/sparewo/sparewo_vendor/lib/repositories/user_repository.dart`
- Rules explicitly define `reviews` and `userRoles`, but not a dedicated `products`/`counters` block.
- Impact: likely permission errors or dead paths.

3. Potential data exposure via permissive list allowance patterns.
- Rules include:
  - `match /clients/{clientId} { allow list: if isStaff() || request.query.limit == 1; }`
  - `match /vendors/{vendorId} { allow list: if isStaff() || request.query.limit == 1; }`
- File: `/Users/jeremy/Development/sparewo/sparewo_vendor/firestore.rules`
- Impact: non-staff list probing patterns may leak data under constrained queries.

## Medium Findings

1. Collection model drift remains (`users` + legacy `clients`).
- Client cart repository still reads fallback `clients`:
  - `/Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/cart/data/cart_repository.dart`
- Rules support both, but this increases complexity and bug surface.

2. Likely composite index debt (cannot verify deployed state due expired auth).
- Repo index file has only one index:
  - `/Users/jeremy/Development/sparewo/sparewo_vendor/firestore.indexes.json`
- Code issues many composite-style queries, for example:
  - `orders`: `where(status) + orderBy(createdAt)` (admin)
  - `orders`: `where(userId) + orderBy(createdAt)` (client)
  - `service_bookings`: `where(userId) + orderBy(createdAt)` (client/admin)
  - `product_mappings`: multiple where + orderBy combinations
- Impact: intermittent runtime "missing index" failures if not already manually created in prod.

## Cross-App Collection Alignment Snapshot

Client app uses:
- `users`, `clients`, `orders`, `service_bookings`, `notifications`, `catalog_products`, plus user subcollections (`cart`, `cars`, `addresses`, `tokens`, `wishlist`)

Admin app uses:
- `adminUsers`, `user_roles`, `users`, `vendors`, `vendor_products`, `catalog_products`, `orders`, `service_bookings`, `notifications`

Vendor app uses:
- `vendors`, `vendor_products`, `order_fulfillments`, `orders`, `products`, `reviews`, `counters`, `users`, `userRoles`, `product_drafts`, `car_brand`, `car_models`

There is partial overlap but not a fully consistent canonical model yet.

## Immediate Remediation Plan (Order Matters)

1. Fix role escalation rules first.
- Lock `userRoles`/`user_roles` creation and updates to admin-only.
- Keep only one canonical role collection if possible.

2. Add Firestore deploy config to one canonical project root.
- Define in one `firebase.json`:
  - `"firestore": { "rules": "...", "indexes": "..." }`
- Stop managing rules from multiple app directories.

3. Align vendor order workflow with rules.
- Either:
  - allow constrained vendor updates on `order_fulfillments`, or
  - move vendor status updates behind Cloud Functions/Admin SDK.

4. Remove/replace permissive list exceptions (`request.query.limit == 1`).
- Restrict list to staff/admin only.
- Use explicit public profile projection collections if needed.

5. Consolidate legacy `clients` paths.
- Migrate data to `users` and remove fallback reads gradually.

6. Generate and version-control full index spec from production after auth is restored.

## Required Live Verification (run from your machine terminal with normal internet)

Run and then I can complete definitive prod-readiness sign-off:
1. `firebase login --reauth`
2. `firebase use --project sparewoapp`
3. `firebase firestore:databases:list --project sparewoapp`
4. `firebase firestore:databases:get --project sparewoapp '(default)'`
5. `firebase firestore:indexes --project sparewoapp`
6. `firebase deploy --only firestore:rules --project sparewoapp --dry-run` (if unsupported in your CLI version, run without `--dry-run` only after review)
7. Share command outputs so I can complete a definitive go/no-go sign-off.

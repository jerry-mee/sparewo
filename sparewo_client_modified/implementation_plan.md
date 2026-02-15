# Guest Mode, High-Fidelity Web & My Car Redesign

## Goal Description
Transform the application into a dual-threat: a user-friendly mobile app with "Guest Mode" for easy browsing, and a high-fidelity, high-resolution Desktop Web application that feels native, not adapted. Additionally, completely overhaul the "My Car" section to be visually rich, using vehicle images as primary covers.

## User Review Required
> [!IMPORTANT]
> **Desktop First**: The Web version will deviate significantly from mobile. It will feature a **Sticky Top Navigation Bar**, **Hover Effects**, and **Grid Layouts** instead of lists.
> **Guest Access**: Browsing (Home, Catalog, Product, Cart) will be open to all. "Booking" or "Checkout" will trigger a **Soft Auth Modal**.
> **My Car Redesign**:
> - **Mobile**: Tall, immersive list cards with full background images.
> - **Desktop**: A responsive **Grid** of vehicle cards.
> - **Detail View**: A full-width `SliverAppBar` header showing the car image.

## Proposed Changes

### Phase 1: Guest Browsing & Smart Auth (Foundation)

#### [MODIFY] [app_router.dart](file:///Users/jeremy/Development/sparewo/sparewo_client_modified/lib/core/router/app_router.dart)
- Relax `redirect` to allow `/home`, `/catalog`, `/product/*`.
- Web: Bypass `/splash` and `/welcome`.

#### [NEW] [auth_guard_modal.dart](file:///Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/auth/presentation/widgets/auth_guard_modal.dart)
- Friendly, "District Noir" themed modal.
- Explains *why* login is needed for the specific action.

### Phase 2: High-Fidelity Web Shell

#### [MODIFY] [scaffold_with_nav_bar.dart](file:///Users/jeremy/Development/sparewo/sparewo_client_modified/lib/core/widgets/scaffold_with_nav_bar.dart)
- **Responsive Switch logic**:
  - `maxWidth < 800`: Mobile Bottom Nav.
  - `maxWidth >= 800`: **Desktop Top Nav**.

#### [NEW] [desktop_nav_bar.dart](file:///Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/home/presentation/widgets/desktop_nav_bar.dart)
- **Glassmorphism Header**: Sticky top bar.
- **Logo**: Left aligned.
- **Nav Links**: "Home", "Catalog", "AutoHub". Hover underline effects.
- **Actions**: "My Garage" (Dropdown), Search Bar (Expanded), Cart, Profile.

#### [MODIFY] [home_screen.dart](file:///Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/home/presentation/home_screen.dart)
- **Layout**: Wrap in `Center(child: ConstrainedBox(maxWidth: 1440))` for ultra-wide monitors.
- **Grid**: Use `SliverGridDelegateWithMaxCrossAxisExtent` (max 150px) for categories.
- **Banner**: Reduce height aspect ratio on Desktop.

### Phase 3: My Car Visual Redesign

#### [MODIFY] [my_cars_screen.dart](file:///Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/my_car/presentation/my_cars_screen.dart)
- **Visuals**:
  - **Mobile**: Increase Card height to `220.h`. Use a darker gradient overlay to ensure text pops over the image.
  - **Desktop**: Switch `ListView` to `GridView`. Create a "Garage Card" that looks like a premium car selector in racing games.
- **Empty State**: Make it more graphical/illustrated.

#### [MODIFY] [car_detail_screen.dart](file:///Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/my_car/presentation/car_detail_screen.dart)
- **Header**: Replace standard `AppBar` with `SliverAppBar(expandedHeight: 300)`.
- **Background**: Display `car.frontImageUrl` in the `flexibleSpace`.
- **Content**: Scrollable body below the image header.

### Phase 4: Desktop Enhancements

#### [MODIFY] [catalog_screen.dart](file:///Users/jeremy/Development/sparewo/sparewo_client_modified/lib/features/catalog/presentation/catalog_screen.dart)
- **Sidebar Filters**: On Desktop, show filters in a permanent left column (width ~280px).
- **Product Grid**: Adaptive columns (4-6 on wide screens).

## Verification Plan

### Manual Verification
1.  **Guest Flow**:
    - Fresh install/Incognito. Verify Home access.
    - Click "Book Service" -> Verify Auth Modal.
2.  **Desktop Experience**:
    - Resize window > 1000px.
    - Check Top Nav appears.
    - Check "My Garage" grid layout.
    - Check "Catalog" sidebar filters.
3.  **Visual Quality**:
    - Verify car images load effectively as backgrounds.
    - Verify text readability over images.
    - Verify spacing is "breathing" on large screens.

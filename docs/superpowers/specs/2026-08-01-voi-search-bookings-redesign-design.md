# Design Specification: Voi Search & Bookings UI Redesign & Functional Wiring

## 1. Overview
This specification details the 1:1 visual redesign and complete functional wiring of two core passenger screens in the 7s mobile application:
1. `BookingsScreen` (`mobile/lib/features/passenger/presentation/screens/bookings_screen.dart`)
2. `DestinationSearchScreen` (`mobile/lib/features/passenger/presentation/screens/destination_search_screen.dart`)

## 2. Component Specifications

### 2.1 BookingsScreen (`bookings_screen.dart`)
- **Top Header**:
  - Title: "My Bookings", Subtitle: "View and manage your rides".
  - Top-Right Circular Calendar-Clock Badge: Interactive tap opens `/passenger/schedule`.
- **Segmented Tab Switcher**:
  - 4-tab pill selector (`Active`, `Scheduled`, `Past`, `Canceled`).
  - Live count badges rendered on tabs with items.
- **Empty State Hero**:
  - Radial gradient peach backdrop with motorcycle graphic and destination pin.
  - Title: "No Active Rides Right Now".
  - Interactive CTA Button: "[Location Pin] Book a Ride" -> Navigates to `/passenger/search`.
- **Scheduled Ride Item Cards**:
  - Action 1: "Chat Driver" -> Navigates to `/driver-chat`.
  - Action 2: "Reschedule" -> Displays Date & Time picker dialog to update scheduled ride.
  - Action 3: "Cancel" -> Shows confirmation modal and moves ride to Canceled list.
- **Support Footer Banner**:
  - "Need help with a trip? Visit our Help Center for support".
  - Interactive "Get Help >" button -> Navigates to `/help-center`.

### 2.2 DestinationSearchScreen (`destination_search_screen.dart`)
- **Header & Floating Input Card**:
  - Vibrant orange top bar with back navigation.
  - Dual-input container for Pickup (green indicator) and Destination (orange indicator).
  - "Use GPS" button -> Queries live coordinates via `DeviceLocationService`.
  - "Swap Origin/Destination" button -> Flips pickup and destination text values.
- **Voi Town Landmarks Section**:
  - Header: "| VOI TOWN LANDMARKS" with top-right "[Map Icon] View on Map" button.
  - "View on Map" tap -> Opens an interactive Voi Town Map modal view showing landmark pins.
  - Real-Time List: Renders matching items from `VoiTownLandmarksData` with icon containers, category chips, and badges ("Popular", "University").
  - Landmark Item Tap -> Sets destination, computes fixed route in `PassengerNotifier`, and pushes `/passenger/fare-offer`.
- **Saved Places Section**:
  - Header: "| SAVED PLACES" with top-right "Manage >" link.
  - Interactive Star Icons: Toggles favorite bookmark status.
  - "Home" / "Work" card tap -> Selects location and advances to `/passenger/fare-offer`.
  - "Manage >" tap -> Navigates to `/settings/saved-places`.

## 3. Architecture Review & Safety Constraints
- **Risk Assessment**: LOW RISK (Internal UI refactoring and component wiring).
- **Data Flow**: Consumes `PassengerNotifier`, `FareTemplatesNotifier`, `RideStateNotifier`, and `DeviceLocationService`.
- **Testing Gate**: Verification via Flutter widget & unit tests in `mobile/test/features/passenger/`.

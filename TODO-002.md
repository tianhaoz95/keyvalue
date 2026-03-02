# Tasks

- [ ] on the home screen, clients section, show the planned next engagement time in the client row
    - [ ] Modify `_buildCustomerTile` in `lib/screens/dashboard_screen.dart`.
    - [ ] Add a new `Text` widget displaying `customer.nextEngagementDate`.
    - [ ] Format the date for better readability (e.g., "Jan 15, 2024").
    - [ ] Use a subtle style (smaller font, grey color) and place it on the trailing side of the row.
- [ ] for the search button on the home screen for clients, add a animation to open the search bar
    - [ ] Locate the search bar logic in `lib/screens/dashboard_screen.dart`.
    - [ ] Replace the conditional `if (_isSearching)` with an `AnimatedContainer` or `AnimatedSwitcher`.
    - [ ] Define the duration and curve for the expansion/collapse of the search input.
    - [ ] Ensure the focus is still requested automatically when it opens.
- [ ] add a animation for all side bar opening, for example, add client, ai onboarding, ai assisted profile and guideline update, etc
    - [ ] Refactor the `Positioned` sidebar container in `lib/screens/dashboard_screen.dart` to use `AnimatedPositioned`.
    - [ ] Use `isAnySidebarOpen` to drive the `right` property (e.g., `0` when open, `-sidebarWidth` when closed).
    - [ ] Add an overlay/scrim (using `AnimatedOpacity` and a `GestureDetector`) that appears behind the sidebar to allow closing it by clicking outside.
    - [ ] Apply similar logic to all sidebars (manual add, AI onboarding, settings).

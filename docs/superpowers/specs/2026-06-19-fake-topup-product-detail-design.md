# Fake Top Up and Product Detail Design

Date: 2026-06-19

## Goal

Make the Top Up page work as a local payment simulation while keeping the rest of the app connected to the backend. Add a product detail page for the existing featured product cards.

Backend calls remain active for auth, profile, user refresh, and licenses. Only the Top Up payment flow becomes local/fake.

## Fake Top Up

### User flow

1. User opens Top Up from dashboard or bottom navigation.
2. User enters or selects an amount.
3. Tapping `Continue to QRIS` validates the amount and creates a local order in app state.
4. The QRIS step shows a polished payment screen with:
   - a locally rendered QR-like visual,
   - amount,
   - order id,
   - countdown,
   - status `Awaiting payment`,
   - primary button `Saya sudah bayar`,
   - secondary button `Cancel & Go Back`.
5. Tapping `Saya sudah bayar` immediately credits the amount to the current in-memory user and shows the success screen.
6. Dashboard, Profile, and Top Up balance displays update immediately because they all watch `AuthProvider`.

The UI should look like a normal payment simulation and should not show a `Demo payment` label.

### Architecture

`TopUpPage` will stop calling `TopUpService.createTopUp()` and `TopUpService.getStatus()`. It will also stop using polling timers. It can keep a countdown timer for the QR screen expiry display.

`AuthProvider` will get a method such as `applyFakeTopUp(int amount)`. This method updates the current `User` in memory by increasing:

- `walletBalance` by `amount`
- `totalTopUp` by `amount`

Then it calls `notifyListeners()`.

Because `User` is immutable, the implementation should add a small `copyWith` method to `User` rather than mutating fields directly.

### State lifetime

The fake balance is session-only. If the app restarts, or if a later backend refresh replaces `AuthProvider.user`, the balance returns to backend data. This is intentional for the current simulation scope.

### Error handling

- Empty/non-numeric amount: show the existing validation error style.
- Amount below Rp 1,000: show the existing minimum error.
- Amount above Rp 500,000: show the existing maximum error.
- If `Saya sudah bayar` is tapped with no authenticated user, show an error and return to input instead of crashing.

## Product Detail

### Data source

Move the existing dummy product list from `lib/pages/dashboard_page.dart` to a shared file such as `lib/data/dummy_products.dart`. Dashboard and product detail will both import this shared list.

This keeps the current backend-shaped product JSON and preserves `Product.fromJson` as the future migration path to a real product service.

### Routing

Add a route inside the authenticated `ShellRoute`:

- `/products/:slug`

The route builds `ProductDetailPage(slug: state.pathParameters['slug']!)`.

Keeping it inside the shell preserves the existing bottom navigation frame.

### Dashboard integration

`ProductCard` taps on dashboard should navigate to `/products/<slug>`.

The featured products section remains horizontally scrollable and continues using `ProductCard`.

### Detail UI

`ProductDetailPage` should match the existing violet/fuchsia glassmorphism style and use `AppTheme`, `PanelCard`, and `GradientButton`.

For a found product, show:

- large gradient/placeholder hero area,
- featured badge when applicable,
- category,
- product name,
- short description,
- version,
- sold count,
- tags,
- three license price cards: Personal, Commercial, Enterprise,
- CTA actions:
  - primary: `Buy Personal`,
  - secondary: `Top Up Balance`.

For now, purchase checkout is not implemented. `Top Up Balance` navigates to `/topup`. `Buy Personal` can also navigate to `/topup` so users can fund their wallet first, avoiding a dead button.

### Missing product handling

If no product matches the slug, show a centered card with:

- title `Product not found`,
- short explanation,
- button back to `/dashboard`.

## Tests

Add or update widget/unit tests where practical:

- `AuthProvider.applyFakeTopUp` increases wallet and total top-up for an authenticated user.
- `TopUpPage` can move from amount input to QR screen and then success after `Saya sudah bayar`.
- `DashboardPage` product card tap navigates to the product detail route, if existing router/widget test setup makes this low-friction.
- Product detail renders product information for a valid slug and not-found UI for an invalid slug.

## Out of scope

- Persisting fake balances across restarts.
- Updating backend wallet balance.
- Real product API integration.
- Real product checkout/license purchasing.

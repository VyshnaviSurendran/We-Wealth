# Our Balance — Frontend

Flutter app (Android + responsive web, one codebase) for the Our Balance
couple finance tracker. Consumes the FastAPI backend in `../backend`.

Authentication (register/login/session restore/logout), the dashboard, and
account management (list/create/edit/archive/transaction history) are
implemented end to end against the real backend. Income, expenses,
transfers, savings, budgets, recurring bills, and household/couple
management (invite a partner, manage members) are not implemented yet — see
`lib/features/*`, most of which are still empty aside from a `.gitkeep`.

## Prerequisites

- Flutter SDK (stable channel). This was built and tested against
  Flutter 3.47.4 / Dart 3.13.3.
- For Android builds specifically: Android SDK + a JDK (not required for
  web).
- The backend running locally — see `../backend/README.md`.

## Run the website

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

By default the web build talks to `http://localhost:8000/api/v1`. Override
with:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

To produce a static build (e.g. to serve behind nginx):

```bash
flutter build web --release
# output in build/web
```

## Run the Android app

```bash
cd frontend
flutter pub get
flutter run -d <device-or-emulator-id>   # flutter devices to list
```

On the Android **emulator**, the app defaults to `http://10.0.2.2:8000/api/v1`
(the documented alias the emulator uses to reach the host machine's
`localhost`) — no configuration needed as long as the backend is running on
your host at port 8000.

On a **physical device**, `10.0.2.2` doesn't resolve, so you must point it at
your machine's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
```

Cleartext (plain HTTP, not HTTPS) is only permitted for `10.0.2.2` and
`localhost` — see `android/app/src/main/res/xml/network_security_config.xml`.
If you point the app at a real host, either serve it over HTTPS or add that
host to the same config.

## Configuring the backend API URL

Everything reads the base URL from one place:
`lib/core/config/app_config.dart` (`AppConfig.apiBaseUrl`). Nothing else in
the app hardcodes a URL. Resolution order:

1. `--dart-define=API_BASE_URL=...` (always wins if set).
2. Web default: `http://localhost:8000/api/v1`.
3. Android default: `http://10.0.2.2:8000/api/v1` (emulator only).

## Authentication

Implements exactly what the backend exposes — see the endpoint reference
below. There is no refresh-token endpoint, so re-login is the only recovery
once a token expires (see **Known limitations**).

- **Register** (`POST /auth/register`) creates the account only; it does
  *not* return a token. `AuthController.register()` immediately follows it
  with a login call using the same credentials so the user isn't asked to
  type them twice.
- **Login** (`POST /auth/login`) stores the returned `access_token` via
  `TokenStorage` (flutter_secure_storage) and never touches the plaintext
  password again — it's only held in the form's `TextEditingController`
  for the duration of the request.
- **Session restore** (`GET /auth/me`): on startup, `SplashPage` waits for
  `AuthController` to read any stored token and validate it against `/me`.
  An expired/invalid token (401) clears storage and shows the login screen;
  a network failure while restoring shows a retry instead of logging the
  user out.
- **Logout** is local only (delete the stored token) — the backend has no
  logout endpoint since JWTs are stateless.
- **Protected routes**: `app/router.dart`'s `redirect` gates every route on
  `authControllerProvider`'s state — unauthenticated users can only reach
  `/login`/`/register`; authenticated users are bounced off those onto
  `/dashboard`. A 401 from *any* API call (via the Dio interceptor in
  `core/network/api_client.dart`) flips the session back to unauthenticated
  reactively, mid-session.
- The `Authorization: Bearer <token>` header is attached automatically by
  the same Dio interceptor — feature code never sets it manually. Network
  logging (debug builds only) explicitly excludes headers and redacts
  `password`/`access_token` fields from logged bodies.

## Dashboard & accounts

All figures come straight from the backend (`GET
/households/{id}/dashboard/summary`) — this app never recomputes a balance;
`DashboardSummary.monthNetCashFlow` is the one exception, and it's just
`monthIncomeReceived - monthExpensesPaid` for a single display line, not new
financial logic.

- **No household-selection UI yet.** There's no server-side "default
  household" concept and building the invite/switch-household flow is out
  of scope for this pass, so `currentHouseholdProvider`
  (`features/household/application/current_household_provider.dart`) just
  uses the first household from `GET /households`. A user with zero
  households sees an explanatory empty state instead of an error.
- **Recent activity** has no dedicated backend endpoint — it's built by
  calling the existing per-account `GET /accounts/{id}/transactions` for
  every active account (from the dashboard summary) in parallel, then
  merging and sorting the results client-side, capped at
  `recentActivityLimit` (10) entries.
- **Accounts list vs. dashboard accounts** use different backend responses
  on purpose: `GET /households/{id}/accounts` (the list endpoint) has no
  balance fields, so the Accounts screen additionally calls `GET
  /accounts/{id}` per account to enrich it — while the Dashboard reuses the
  summary's already-enriched `accounts` array directly. The Accounts screen
  also shows archived accounts (the dashboard doesn't; the backend filters
  those out of the summary).
- **Edit** only exposes `name` and "shared with partner" — matching the
  backend's `AccountUpdate` schema exactly; `account_type` and
  `opening_balance` cannot be changed after creation. **Archive** is
  `DELETE /accounts/{id}` (soft — `is_active=false`); **Unarchive** reuses
  the same `PATCH` endpoint's `is_active` field, since the backend already
  supports flipping it back.

## Project layout

```
lib/
  main.dart                 # entry point: ProviderScope + OurBalanceApp
  app/                       # root widget, theme, router (incl. auth redirect), nav shell
  core/
    config/                  # AppConfig — API base URL, app-wide constants
    network/                 # Dio client (auth header + redacted logging), endpoint paths
    storage/                 # secure token storage
    auth/                    # AuthStatus flag — core-layer seam the network layer flips on 401
    errors/                  # ApiException hierarchy + Dio -> ApiException mapper
    widgets/                 # LoadingView, ErrorView, EmptyStateView, InlineErrorBanner, placeholder page
    utils/                   # Money (parses/formats backend Decimal-as-string amounts)
  features/
    auth/
      data/                  # AuthApi (register/login/me), AuthUser model
      application/           # AuthController (session state), form validators
      presentation/          # splash, login, register pages + password field widget
    household/
      data/                  # HouseholdApi (list), Household model
      application/           # currentHouseholdProvider (first-household resolution)
    dashboard/
      data/                  # DashboardApi + DashboardSummary model
      application/           # dashboardSummaryProvider, recentActivityProvider
      presentation/          # DashboardPage (responsive: 1 column mobile, 2 columns wide)
    accounts/
      data/                  # AccountsApi, Account/AccountDetail models, AccountType enum
      application/           # accountsWithBalancesProvider, AccountsController (mutations)
      presentation/          # list (responsive grid), detail, create/edit form sheet
    transactions/  savings/  reports/
      # placeholder pages wired into navigation
    settings/                # shows current user + sign out
    categories/  income/  expenses/  transfers/  budgets/  recurring_bills/
      # empty (.gitkeep) — folders reserved for when each feature is built
  shared/
    models/                  # AccountTransaction — used by both accounts and dashboard
    widgets/                 # AmountText, BalanceCard, AccountCard, HouseholdScopedBuilder
```

## Tests & static analysis

```bash
flutter analyze
flutter test
```

Both are clean as of this commit — 61 tests: unit tests for `AuthController`
and the dashboard/accounts/household providers; API response-parsing tests
for every new model (`Account`, `AccountDetail`, `DashboardSummary`,
`AccountTransaction`); and widget tests for the auth pages, the dashboard,
the accounts list/create-sheet, the shared `BalanceCard`/`AccountCard`/
`AmountText` widgets, and the router's auth gating. All using manual fakes
for the `*Api` classes and `TokenStorage` (no mocking library, no real
network/platform channel calls in tests).

## Known limitations

- **No refresh token.** The backend has no refresh-token endpoint; once the
  access token expires (`ACCESS_TOKEN_EXPIRE_MINUTES`, 60 min by default),
  the only recovery is a full re-login. A 401 from any request clears the
  session and returns the user to `/login`.
- `flutter_secure_storage` on **web** falls back to browser storage, which
  is not hardware-encrypted the way Android Keystore-backed storage is. This
  is a package limitation, not a bug here — acceptable given the token's
  short lifetime.
- `flutter build web --wasm` is not currently possible because
  `flutter_secure_storage_web` uses `dart:html`/`dart:js_util`, which the
  Wasm compiler doesn't support yet. The normal (non-Wasm) web build is
  unaffected.

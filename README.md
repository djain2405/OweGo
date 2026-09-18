# OweGoGo

*Less owing. More going.*

Trip expense companion for iOS — track shared spending during group trips with ultra-fast expense entry, live balances, and settlements. Friendly, fast, zero-accounting-energy.

## Requirements

- Xcode 16+
- iOS 17+ (SwiftData)
- iPhone or iPad

## Getting Started

1. Open `OweGo.xcodeproj` in Xcode
2. Select your development team under **Signing & Capabilities** (required for device builds)
3. Run on simulator or device (`Cmd+R`)

## Run Tests

```bash
xcodebuild -scheme OweGo -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Architecture

```
OweGo/
├── App/              # Entry point, dependency wiring
├── Domain/           # Models, use cases, BalanceEngine
├── Data/             # SwiftData entities, local repositories
├── Presentation/     # SwiftUI views
└── Core/             # Formatters, settings, notifications
```

**Phase 1** (current): Local-only, single device. No backend or invite links.

**Phase 2** (planned): Supabase sync, Sign in with Apple, invite links, web participant view.

## Key Flows

- **Create trip** — name, dates, participants (you are auto-added)
- **Add expense** — enter amount, tap Save (defaults: you paid, everyone splits equally)
- **Trip dashboard** — live balances, recent expenses, settle
- **Settle** — mark paid, copy payment request, open Venmo
- **End trip** — summary with remaining balances

## Settings

Configure your name and Venmo handle in **Settings** (gear icon on trip list).

## App Store

See [`docs/RELEASE.md`](docs/RELEASE.md) for archive / TestFlight / submit steps. Listing copy and privacy policy drafts live in [`docs/APP_STORE_LISTING.md`](docs/APP_STORE_LISTING.md) and [`docs/PRIVACY_POLICY.md`](docs/PRIVACY_POLICY.md).

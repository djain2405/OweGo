# OweGo Release Checklist

Ship a TestFlight / App Store build of the local-first OweGo app.

## Before you archive

- [ ] Set a real Venmo username in Settings only for your own dogfood; reviewers can leave it blank  
- [ ] Confirm **Version** (`MARKETING_VERSION`) and **Build** (`CURRENT_PROJECT_VERSION`) in Xcode  
- [ ] Confirm App Icon appears on Simulator/device home screen  
- [ ] Enable GitHub Pages: repo **Settings → Pages → Deploy from branch `main` / folder `/docs`**  
- [ ] Confirm URLs load: Support `https://djain2405.github.io/OweGo/` · Privacy `https://djain2405.github.io/OweGo/privacy.html`  
- [ ] Paste listing copy from [`APP_STORE_LISTING.md`](APP_STORE_LISTING.md) into App Store Connect  

## App Store Connect

1. Create a new app: bundle ID `com.owego.app`, name **OweGo**  
2. Fill subtitle, description, keywords, category **Travel**  
3. Add Privacy Policy URL and Support URL  
4. Complete **App Privacy** using the draft in the listing doc (Data Not Collected / no tracking for v1)  
5. Complete age rating questionnaire (expect **4+**)  
6. Upload screenshots (required sizes for the devices you support):  
   - iPhone 6.7" and/or 6.5" (and 5.5" if still required for your account)  
   - iPad 12.9" if you keep iPad in `TARGETED_DEVICE_FAMILY`  
7. Suggested screenshot flows: trip list with logo, active trip hero, add expense, balances/settlement, share report  

## Archive & upload (Xcode)

1. Select target **OweGo**, destination **Any iOS Device (arm64)**  
2. Product → **Archive**  
3. Organizer → **Distribute App** → App Store Connect → Upload  
4. Wait for processing, then add the build to a version in ASC  

Signing uses Automatic signing + team `VNMK5763A9`. If archive fails on signing, open Signing & Capabilities, select your team, and ensure a Distribution certificate exists in your Apple Developer account.

## TestFlight

1. Add internal testers (and external if desired; external may need Beta App Review)  
2. Install on a **physical iPhone** to verify Venmo deep links (Simulator has no Venmo)  
3. Smoke test: create trip, expense, settle, copy request, Request on Venmo, share report  

## Submit for review

1. Select the processed build  
2. Answer export compliance: **ITSAppUsesNonExemptEncryption = NO** is already in Info.plist (standard HTTPS-only)  
3. Add App Review notes from the listing doc  
4. Submit  

## After approval

- [ ] Smoke-test the production App Store build  
- [ ] Bump build number for the next upload; bump marketing version for user-facing releases  

## Out of scope for v1

Cloud sync, accounts, and in-app payment processing are not part of this release. Update privacy policy and App Privacy answers before shipping those features.

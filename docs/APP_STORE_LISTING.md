# OweGo App Store Listing Draft

Use this copy in App Store Connect. Edit to match your voice before submit.

## App information

| Field | Value |
|-------|--------|
| Name | OweGo |
| Subtitle (30 chars) | Split trip expenses easily |
| Bundle ID | `com.owego.app` |
| Primary category | Travel |
| Secondary category | Finance (optional) |
| Content rights | Does not contain third-party content you don’t have rights to |
| Age rating | 4+ (no unrestricted web, no gambling, infrequent mature themes) |

## Promotional text (optional, 170 chars)

Track group trip spending in the moment—then settle up with clear balances and Venmo-ready pay links.

## Description

OweGo makes shared trip spending simple so nobody has to reconstruct the group chat after you get home.

Create a trip, add friends, and log expenses as they happen. OweGo keeps balances clear, shows who owes whom, and helps you settle up—including optional Venmo pay and request links.

**Highlights**
• Create trips and add participants in seconds  
• Log expenses with equal or custom splits  
• See balances and simplified settlements  
• Attach receipt photos (stored on your device)  
• Copy payment requests or open Venmo deep links  
• Share trip wrap-up reports with your group  

**Local-first**  
Your trips and expenses stay on your iPhone. No account required for this version. OweGo does not process payments—Venmo links open Venmo so you can pay or request there.

## Keywords (100 chars max, comma-separated)

trip,expenses,split,travel,venmo,settle,group,bill,balance,friends,receipt

## What’s New (1.0)

First release of OweGo: track shared trip expenses, see who owes whom, settle up, and share trip reports—with a fresh suitcase + split-coin app icon.

## Support & marketing URLs

| Field | Notes |
|-------|--------|
| Support URL | Required — e.g. a simple contact page or GitHub Issues |
| Marketing URL | Optional |
| Privacy Policy URL | Required — host `docs/PRIVACY_POLICY.md` over HTTPS |

## App Privacy questionnaire (draft answers)

| Question | Answer for v1 |
|----------|----------------|
| Do you or third-party partners collect data? | **No** (data stays on device; no analytics SDKs) |
| Tracking? | **No** |
| Payment info collected by app? | **No** (Venmo is opened externally) |
| Photos? | Used only on device if user attaches receipts — if ASC asks “collected,” choose **No** unless Apple’s definition forces “linked to user” for on-device only; prefer **Data Not Collected** for this local-first build |
| Contact info (name / Venmo handle)? | Stored on device only → typically **Data Not Collected** from *your* servers; if ASC requires declaring on-device storage that never leaves the device, follow current ASC guidance and mark not linked / not used for tracking |

Re-check Apple’s App Privacy definitions at submit time; they change periodically.

## Review notes (for App Review)

- App is fully usable offline.  
- Optional Venmo username is entered in Settings; leave blank to hide Venmo buttons.  
- PhotosPicker attaches optional receipt images; no account or backend.  
- Demo: Create Trip → Add Expense → view balances → Settlement → optional Request on Venmo (requires Venmo installed on device).

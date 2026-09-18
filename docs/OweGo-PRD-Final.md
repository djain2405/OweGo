# OweGo — Product Requirements Document (Final)

**Document version:** 1.0 (merged)  
**Last updated:** August 30, 2026  
**Status:** Phase 1 built (local iOS); Phase 2 planned  

This document combines the **original OweGo PRD** with **implementation status**, **gaps**, and **roadmap** in one place. Import into Google Docs via File → Import, or copy-paste the full contents.

---

# Part 1 — Product Requirements (Original PRD)

## 1. Product Summary

**Working name:** OweGo

**Category:** Group travel expense management

**Core promise:** Make shared trip spending effortless enough to handle in the moment, so nobody has to reconstruct expenses or chase payments after the trip.

The product still supports the expected basics—who paid, who participated, equal or custom splits, balances, settlements—but the differentiation is proactive trip expense management instead of passive bookkeeping.

---

## 2. Problem

On group trips, one or two people often pay for many common expenses: gas, groceries, lodging, meals, parking, activities, supplies.

The problem is usually not willingness to pay upfront. The painful part comes later:

- Forgetting what an expense was for
- Remembering who participated
- Digging through card statements and receipts
- Manually entering many transactions
- Figuring out who owes whom
- Sending payment requests
- Following up with people who forget
- Discovering that one person unintentionally fronted hundreds or thousands of dollars

Existing expense-splitting apps are primarily ledgers. They help users record and calculate expenses, but still rely heavily on users remembering to maintain that ledger.

---

## 3. Product Vision

A trip should end like this:

> Trip complete. Everything is accounted for. $18.40 remains unsettled.

Not:

> "Okay, I need to sit down tonight and figure out what everyone owes me."

The long-term vision is an ambient financial companion for group experiences that captures, categorizes, attributes, balances, and settles shared spending with minimal human input.

---

## 4. Target User

### Primary user: The Trip Organizer / Frequent Payer

Someone who:

- Travels frequently with friends or family
- Naturally books or pays for common expenses
- Doesn't mind fronting money
- Wants accurate reimbursement
- Dislikes administrative cleanup afterward
- Tends to be the person coordinating everyone else

### Secondary user: Trip Participant

Someone who:

- Doesn't want another finance app to manage
- Wants transparency into what they owe
- Wants an easy way to review and pay
- May participate through a simple shared link rather than installing an app

---

## 5. Jobs To Be Done

### Primary JTBD

When I'm traveling with a group, help me capture shared spending as it happens so I don't have to reconstruct and split everything afterward.

### Supporting JTBDs

- Help me know whether I'm fronting significantly more money than everyone else.
- Make it obvious who owes what at any point during the trip.
- Let participants pay back money before the balance becomes large.
- Minimize the number of decisions required to log a normal expense.
- Let me manage the trip even if some participants don't install the app.

---

## 6. Product Principles

1. **The default case should take seconds** — Most expenses are: I paid → everyone participated → split equally. That flow should require nearly zero configuration.

2. **Ask for exceptions, not complete information** — Default to everyone and offer "Change." Default payer to the person entering the expense.

3. **Trips are temporary contexts** — "For the next four days, these five people and these expenses belong together."

4. **Reduce bookkeeping, don't improve bookkeeping** — If users are entering twenty fields per expense, the product has failed regardless of how polished the UI is.

5. **Money should remain transparent** — Users should always understand what was recorded, how it was split, why they owe something, and what changed their balance.

---

## 7. MVP

The MVP should validate one question:

> Will people actually manage expenses during a trip if the interaction is dramatically easier than Splitwise?

Do not begin with bank integrations, financial custody, automatic payment movement, or complicated AI.

### MVP User Flows

#### A. Create a trip

User enters:

- Trip name
- Start/end dates
- Participants

Example:

- Mt. Whitney Weekend
- Sept 7–9
- Divya, Gabe, Sarah, Bennett

Generate an invite link. Participants can join without creating a full account.

#### B. Trip dashboard

The main screen should prioritize only four things:

- Mt. Whitney Weekend
- You've paid: $482
- Your share: $194
- You're ahead: +$288

Then: **3 expenses need review**

And group balances:

- Sarah owes $94
- Gabe owes $102
- Bennett owes $92

Primary CTA: **+ Add expense**  
Secondary CTA: **Settle**

#### C. Ultra-fast expense entry

The initial screen should be:

**How much?** $ ______

Then:

- Paid by: You
- Split with: Everyone
- Split: Equally
- Save

For the common case, entering `84` and tapping save should be enough.

Optional fields remain available: description, category, different payer, exclude participants, unequal amounts, percentage split, notes, receipt image — but they should never block the default flow.

#### D. Quick contextual entry

After entering $84, the app can show:

- $84 shared with all 4 people
- Your share: $21
- Others owe you: $63
- Done

#### E. Live trip balance

Each participant gets a simple running balance. Users should not need accounting terminology. Translate into plain language:

- Divya should receive $288
- Gabe owes $102

#### F. Settle anytime

Tap a participant: Gabe owes you $102

Actions:

- Mark as paid
- Copy payment request
- Optionally: Open Venmo

For MVP, don't process money. Deep-link to payment apps or let users mark settlements manually. Balances update instantly.

#### G. Trip completion

At the end date:

- Mt. Whitney Weekend is over
- 18 expenses
- $1,284 total spent
- 3 balances remaining

Then show exact settlements needed. When everyone reaches zero: **All settled. Nothing left to do.** That moment is the product payoff.

---

## 8. MVP Feature Scope

### MUST HAVE

**Trip management**

- Create trip
- Start/end date
- Add participants
- Invite via shareable link
- Join without mandatory app install

**Expenses**

- Add expense (amount, description, payer, participants)
- Equal split
- Custom amount split
- Edit/delete expense

**Balance engine**

- Running balances
- Simplified debts
- Individual ledger
- Group total

**Settlement**

- Record settlement
- Payment-app deep link where feasible
- Remaining amount calculation

**Trip Mode**

- Clearly visible active-trip state
- Fast expense entry optimized for current trip
- End-of-trip summary

**Basic notifications**

- "Trip ending tomorrow—3 expenses still need review."
- "You currently owe $124."
- "Sarah marked your $82 payment as received."

---

## 9. Explicitly NOT in MVP

Do not build yet:

- Linked bank accounts
- Automatic card transaction import
- Holding user funds
- Credit/debit card payments
- Automated Venmo/Zelle transactions
- AI categorization
- AI participant prediction
- OCR receipt itemization
- Location detection
- Recurring expense prediction
- Chat
- Complex budgeting
- Travel itinerary
- Currency conversion beyond simple manual currencies
- Rewards
- Social feeds
- "Who pays next"
- Sophisticated spending analytics

They don't help answer the MVP hypothesis.

---

## 10. MVP Differentiator — Trip Mode

Even without advanced automation, the experience should feel different because the entire app is designed around **Trip Mode**.

Instead of: Groups → Expenses → Activity → Friends

It looks like:

> You're currently on Tahoe Weekend. Add expenses here. We'll keep everything handled until the trip ends.

The trip itself is the primary object—not the ledger.

---

## 11. V1.1 — Make Capture Nearly Effortless

Once MVP behavior is validated, this is the first expansion.

### Receipt capture

Take a photo. OCR detects merchant, total, and date. App asks: "Shared with everyone?" → Yes → Done. Initially, don't itemize receipts.

### Voice expenses

Hold mic: "I paid 68 dollars for gas for everyone except Sarah." App previews split and asks to confirm.

### Smart defaults

Learn simple trip behavior. If 90% of expenses are "Divya paid + everyone participates," make that the permanent default during that trip.

---

## 12. V2 — Ambient Trip Mode

### Connected-card transaction inbox

User optionally connects a card/account. During an active trip, show detected purchases. Swipe **Shared** or **Personal**. The app detects; the human confirms.

### Smart trip classification

Based on dates, merchant category, amount, behavior, trip context, and participant patterns, predict likely shared vs personal. Eventually: "I found 7 purchases. Six look shared. Approve?"

---

## 13. V2 — Continuous Settlement

Settlement threshold trip setting: settle when balance reaches $100, $200, $500, end of trip, or custom. Nudge mini-settlement when threshold hit. Users can disable completely.

---

## 14. V2 — Who Pays Next

Optional feature. If the group prefers rotating expenses: "Sarah should grab the next ~$70 expense." Algorithm considers everyone's current net balance. Playful guidance, not obligation.

---

## 15. V3 — Zero-Admin Trips

**Before:** Create trip, add friends, connect preferred payment source.

**During:** Spend normally. Occasional prompts: "$142 at Safeway looks shared with everyone." ✓

**After:** Lake Tahoe complete. 24 shared expenses captured. $1,846 spent. Everyone settled ✓

The user almost never manually enters an expense.

---

## 16. Longer-Term Features

- **Intelligent participant inference** — Dinner receipt suggests who was involved; user confirms.
- **Item-level receipt splitting** — AI suggests per-person items; useful but not MVP.
- **Multi-currency travel** — FX at transaction or settlement time with transparent calculation.
- **Trip budget layer** — Shared budget, % spent, remaining, by category.
- **Group expense intelligence** — Cross-trip analytics (average cost per person, spending patterns).

---

## 17. Future Monetization

### Free

- Unlimited basic trips
- Manual expenses
- Balances
- Settlements
- Links
- Basic receipt storage

### Plus ($2.99–$4.99/month or annual)

- Automatic card import
- Receipt scanning
- Voice entry
- AI classification
- Multi-currency
- Advanced trip insights
- Automatic reminders
- Historical analytics

### Trip Pass ($3.99 per trip)

Unlock automation for that trip. Attractive for users who won't want another subscription.

---

## 18. Key Metrics

Don't optimize initially for MAU.

**Post-trip cleanup rate** — What percentage of trips end with no new expenses added after the trip ends?

| Metric | Goal |
|--------|------|
| Capture latency | < 5 minutes during active trips |
| Expense entry completion time | < 5 seconds for standard expense |
| Settled-at-trip-end rate | < $25 outstanding when trip ends |
| Participant friction | % of invited participants who can view/manage balance without installing the app |
| Organizer workload | Eventually ~1 tap per shared transaction |

---

## 19. North Star Metric

**% of trips that end financially complete**

Meaning:

- Expenses captured
- Balances known
- Settlements complete or explicitly deferred
- No post-trip reconciliation required

---

## 20. Roadmap in One View

| Stage | Goal | Signature capability |
|-------|------|---------------------|
| MVP | Make trip expense entry dramatically faster | Trip Mode + instant expense entry |
| V1.1 | Reduce typing | Receipt + voice capture |
| V2 | Remove remembering | Transaction inbox + smart classification |
| V2.5 | Avoid large IOUs | Continuous settlements + Who Pays Next |
| V3 | Remove expense administration | Mostly automatic shared expense management |

**Long-term transition:** Log expenses → confirm expenses → don't think about expenses.

---

# Part 2 — Implementation Status (August 2026)

## Executive Summary

Phase 1 (personal, local-only iOS app) is **~95% complete** for single-device dogfooding and **~85% complete** against the full PRD MVP (which requires multi-user collaboration).

**Built:** Trip CRUD, ultra-fast expense entry, balance engine (tested), settlements, Trip Mode UI, local notifications.

**Missing for full PRD MVP:** Invite links, web participant view (no-install), settlement-received notifications, "expenses need review" dashboard item.

---

## Scorecard

| PRD MVP Area | Done | Partial | Missing |
|--------------|------|---------|---------|
| Trip management | 4 | 0 | 2 (invite, web join) |
| Expenses | 9 | 0 | 0 |
| Balance engine | 4 | 0 | 0 |
| Settlement | 3 | 1 | 0 |
| Trip Mode | 3 | 0 | 0 |
| Notifications | 2 | 0 | 1 |
| **Total** | **25** | **1** | **3** |

---

## Feature Status by Area

### Trip Management

| Requirement | Status | Notes |
|-------------|--------|-------|
| Create trip | Done | TripFormView, CreateTripUseCase |
| Start/end dates | Done | isActive, isPast, isEnded |
| Add participants | Done | Names only (no real accounts yet) |
| Edit/delete trip | Done | Beyond MVP — added in UI redesign |
| Invite via shareable link | Not built | Phase 2 |
| Join without app install | Not built | Phase 2 web view |

### Expenses

| Requirement | Status | Notes |
|-------------|--------|-------|
| Amount-first entry | Done | 2-tap default flow |
| Description, payer, participants | Done | In "More options" |
| Equal / custom / percentage split | Done | BalanceEngine |
| Edit/delete | Done | ExpenseDetailView |
| Categories, notes, receipt photo | Done | Bonus beyond MVP minimum |

### Balance Engine

| Requirement | Status |
|-------------|--------|
| Running balances | Done |
| Simplified debts | Done |
| Individual ledger | Done |
| Group total | Done |
| Unit tests (7 passing) | Done |

### Settlement

| Requirement | Status | Notes |
|-------------|--------|-------|
| Record settlement | Done | Mark as Paid |
| Copy payment request | Done | Clipboard |
| Venmo deep link | Done | Configurable in Settings |
| Remaining balance after settle | Done | Engine recalculates |
| Partial settlement | Partial | Always full debt amount |
| Other payment apps | Not built | Venmo only |

### Trip Mode

| Requirement | Status |
|-------------|--------|
| Active trip state | Done |
| Ultra-fast expense entry | Done |
| End-of-trip summary | Done |
| Plain-language balances | Done |

### Notifications

| Requirement | Status | Notes |
|-------------|--------|-------|
| Trip ending tomorrow | Done | Local notification |
| You currently owe $X | Done | Scheduled next morning |
| Payment marked as received | Not built | Needs sync + push |

### PRD Sections 1–20 — Quick Status

| Section | Status |
|---------|--------|
| 1. Product summary | Aligned; distributed capture pending Phase 2 |
| 2. Problem | Addressed for organizer; participants can't self-report yet |
| 3. Vision | End-of-trip summary done; ambient automation not started |
| 4. Users | Organizer done; participant persona not built |
| 5. JTBD | 4/6 done; distributed capture + no-install management missing |
| 6. Principles | All 5 aligned in current UX |
| 7. MVP flows A–G | A, B partial; C–G done |
| 8. MVP scope | 3 items missing (invite, web join, settlement notification) |
| 9. Not in MVP | Correctly skipped |
| 10. Trip Mode | Done |
| 11. V1.1 | Not started |
| 12–14. V2 / V2.5 | Not started |
| 15. V3 | Not started |
| 16. Long-term | Not started |
| 17. Monetization | Not started |
| 18. Metrics | Not instrumented |
| 19. North star | Supported by engine; tracking not built |
| 20. Roadmap | MVP ~85%; rest not started |

---

## Architecture Readiness

| Layer | Status |
|-------|--------|
| Domain models | Clean structs, no UI deps |
| BalanceEngine | Pure, unit tested |
| Repository protocols | Ready to swap implementations |
| SwiftData persistence | LocalTripRepository |
| Use cases | CreateTrip, AddExpense, UpdateExpense, RecordSettlement, UpdateTrip, EndTrip |
| UI design system | OweGoTheme + shared components |

Phase 2 is additive (SyncingTripRepository), not a rewrite.

---

# Part 3 — Roadmap & Strategic Direction

## Where You Are

**Implemented (Phase 1):** Trip CRUD · Expense Entry · Balance Engine · Settlements · Trip Mode UI

**PRD MVP gaps:** Invite Links · Web Participant View · Settlement Notifications

**Recommended next steps:**

1. Phase 1 (done) → Dogfood on real trip
2. PRD gaps → Phase 2 backend (invite links, web view, sync)
3. Dogfood → Phase 2 backend
4. Phase 2 → V1.1 capture (receipt OCR, voice entry)

---

## What's Next — Recommended Order

### Now: Dogfood on a Real Trip (0–2 weeks)

Use the app on your next group trip. Other participants are names you type in.

**Validate:** Is expense entry during the trip dramatically easier than Splitwise?

Watch for: 2-tap speed, balance trust, settle-during vs after-trip behavior, friction after 10+ expenses.

### Short-Term Polish (optional, 1–2 days)

1. Partial settlements (pay less than full debt)
2. App icon (placeholder today)
3. Dark mode (currently locked to light)
4. "Expenses need review" on dashboard

### Phase 2: Production / Multi-User (2–4 weeks)

| Feature | Approach |
|---------|----------|
| Supabase backend | Postgres mirrors domain models |
| Sign in with Apple | Supabase Auth (organizer) |
| Sync | SyncingTripRepository |
| Invite links | owego.app/trip/{code} |
| Web participant view | View balance, add expenses, no install |
| Push notifications | Settlement received, trip reminders |
| App Store | Privacy policy, TestFlight, screenshots |

**Phase 2 priority order:**

1. Supabase backend + real-time sync
2. Shareable trip link + mobile web participant view (before App Store polish)
3. Push notifications
4. Sign in with Apple for organizer (participants anonymous via link token)
5. App Store / TestFlight

### V1.1: Make Capture Effortless

| Feature | Approach |
|---------|----------|
| Receipt OCR | Vision — merchant + total + date |
| Voice expenses | Speech framework |
| Smart defaults | Learn per-trip patterns |

### V2+

- Connected-card transaction inbox
- Smart trip classification
- Continuous settlement thresholds
- Who Pays Next
- Multi-currency, trip budget layer

### V3

Most expenses auto-detected and confirmed, not manually entered.

---

## Strategic Bet: No-Install Participant Links

**Verdict:** Core product pillar in Phase 2, not optional.

Participants are **data capture nodes**, not primary customers. Success = tap link, log expense, close tab.

### Minimum web participant surface

| Web can do | Web should NOT do (yet) |
|------------|-------------------------|
| View you owe / you're owed | Full trip admin |
| Add expense (amount → save) | Edit others' expenses |
| See recent expenses | OCR, voice entry |
| Mark self as paid | Create new trips |
| Pick name on first visit | Require account creation |

### The flywheel

1. Organizer installs OweGo
2. Creates trip + shares link
3. Participants open link in browser
4. They log what they paid
5. Balances stay accurate in real time
6. Organizer does less admin
7. Trip ends financially complete
8. Organizer uses OweGo on next trip (repeat)

### Risks

| Risk | Mitigation |
|------|------------|
| Spam / fake expenses | Secret link; optional organizer approval later |
| Identity | Pick name from participant list on first visit |
| Organizer does everything | Track % of expenses added by non-organizer |
| Fewer app installs | Monetize organizer (Trip Pass, Plus) |

---

## Decision Point After Dogfood

> "Did I actually log expenses during the trip instead of reconstructing afterward?"

- **Yes** → Invest in Phase 2 (backend, invites, App Store)
- **No** → Fix friction first (UX, speed, defaults) before infrastructure

North star: **% of trips that end financially complete** — not feature count.

---

## PRD Gaps Summary

### MVP gaps (must close for full PRD MVP)

1. Invite via shareable link
2. Join / add expenses without app install (web participant view)
3. "Expenses need review" on dashboard
4. Notification: "Sarah marked your payment as received"
5. Partial settlement amounts (optional polish)
6. Payment deep links beyond Venmo (optional)

### Post-MVP (PRD roadmap order)

- V1.1: Receipt OCR, voice entry, smart defaults
- V2: Card inbox, smart classification, continuous settlement
- V2.5: Who Pays Next
- V3: Zero-admin trips
- Long-term: participant inference, item splits, multi-currency, budgets, intelligence
- Monetization: Free / Plus / Trip Pass
- Metrics: Analytics for Section 18 KPIs

---

*End of document*

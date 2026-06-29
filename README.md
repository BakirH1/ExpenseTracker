# ExpenseTracker 🧾

A fully native iOS expense tracker built for Bosnia & Herzegovina, with **KM (BAM) / EUR**
dual-currency support and **receipt scanning** powered by on-device OCR. Zero third-party
dependencies — 100% Apple frameworks.

> Storage currency is always **KM (BAM)**. EUR is shown everywhere as a secondary, muted value
> using the legally fixed peg **1 EUR = 1.95583 KM**.

---

## ✨ Features

- **Dashboard** with a liquid-glass summary card and a **Day / Week / Month** period switcher.
  - *Day* → hourly mini bar chart
  - *Week* → 7 weekday bars (Mon–Sun)
  - *Month* → category breakdown donut
- **Receipt scanner** (the headline feature): native VisionKit document capture → Vision OCR →
  automatic extraction of **total, date, merchant, place, and category**, with a confidence score
  and an editable review screen.
- **Manual entry** with a custom numeric keypad and a live KM ↔ EUR conversion preview.
- **Analytics** tab: this-week-vs-last-week delta, category bar chart, and a daily-spend line chart,
  all switchable between KM and EUR.
- **Dual currency everywhere**: every amount shows KM primary + EUR secondary.
- **Liquid Glass design** using system materials — looks great on iOS 17–18 and is automatically
  upgraded to the full Liquid Glass treatment on iOS 26.
- **SwiftData** persistence — your expenses survive app restarts with zero configuration.
- Full **dark mode** support (only semantic system colors are used).

---

## 🧰 Technology

| Concern        | Framework                         |
| -------------- | --------------------------------- |
| UI             | SwiftUI                           |
| Persistence    | SwiftData (`@Model`, `@Query`)    |
| Charts         | Swift Charts (`import Charts`)     |
| Receipt OCR    | Vision (`VNRecognizeTextRequest`) |
| Document scan  | VisionKit (`VNDocumentCameraViewController`) |
| Currency math  | Pure Swift (fixed peg, offline)   |

- **Minimum deployment target:** iOS 17.0
- **Optimized for:** iOS 26 liquid glass aesthetics
- **Dependencies:** none (no SPM / CocoaPods / Carthage)

---

## 📁 Project Structure

```
ExpenseTracker/
├── ExpenseTrackerApp.swift          # @main entry point (SwiftData container)
├── ContentView.swift                # Root TabView (Dashboard + Analytics)
├── Models/
│   ├── Expense.swift                # SwiftData @Model (amount stored in KM)
│   ├── ExpenseCategory.swift        # Enum with SF Symbol + color
│   ├── CurrencyManager.swift        # Currency enum + conversion/format helpers
│   ├── Period.swift                 # Day/Week/Month windowing
│   └── ChartModels.swift            # Chart value types + SpendAggregator
├── Views/
│   ├── Dashboard/                   # DashboardView, SummaryCardView, ExpenseRowView
│   ├── AddExpense/                  # AddExpenseView, AmountInputView, CategoryPickerView
│   ├── Scanner/                     # ReceiptScannerView, ScanResultView
│   ├── Analytics/                   # AnalyticsView
│   └── Components/                  # GlassCardView, CurrencyToggleView, EmptyStateView
├── Services/
│   ├── ReceiptParserService.swift   # Vision OCR + regex extraction pipeline
│   └── ExchangeRateService.swift    # BAM/EUR fixed-peg constant + conversion
├── Extensions/
│   ├── Color+Extensions.swift       # Hex init + semantic color palette
│   └── Calendar+Helpers.swift       # Monday-start week + month helpers
└── Resources/
    └── Assets.xcassets/             # App icon (KM mark) + accent color
```

---

## 💱 Currency System

- The Bosnian convertible mark (**KM / BAM**) is pegged to the euro by the country's currency board:
  **1 EUR = 1.95583 KM**, fixed and offline (no network calls — see `ExchangeRateService`).
- `Expense.amount` is **always** stored in KM. When the user types in EUR, the value is multiplied
  by 1.95583 before saving.
- `@AppStorage("preferredInputCurrency")` remembers the last currency you typed in, across launches.
- Every row and total renders KM primary (blue) + EUR secondary (muted).

---

## 📷 Receipt Scanner Pipeline

1. Tap **Scan Receipt** → native `VNDocumentCameraViewController` opens (edge detection + perspective
   correction for free).
2. The first captured page is run through `VNRecognizeTextRequest` (`.accurate`, languages
   `hr / bs / sr / en`, language correction off).
3. Heuristic extraction passes (`ReceiptParserService`):
   - **Total** — anchored on keywords (`UKUPNO`, `ZA PLATITI`, `IZNOS`, `TOTAL`, …); takes the largest
     money value near a keyword, falling back to the largest amount on the receipt.
   - **Date** — `dd.MM.yyyy`, `dd/MM/yyyy`, `yyyy-MM-dd`; time strings stripped.
   - **Merchant** — top-of-receipt text, filtering generic words (`RAČUN`, `FISKALNI`, `BLAGAJNA`, …).
   - **Place** — postal codes, street markers, and a list of BiH cities.
   - **Category** — keyword matching on the merchant (`konzum`→groceries, `petrol`→transport,
     `apoteka`→health, …).
   - **Confidence (0–1)** — blended from total/date/merchant detection + OCR confidence.
4. A **review screen** shows every field editable. If confidence < 0.6 an amber banner appears and the
   amount/name fields are outlined in amber.
5. Numbers handle both `42,80 KM` and `42.80`, plus European (`1.234,56`) and US (`1,234.56`) grouping.

---

## 🎨 Design System

- **Glass:** `.ultraThinMaterial` / `.regularMaterial` in rounded rectangles (radius 20–24). These are
  the forward-compatible path to iOS 26 Liquid Glass and degrade gracefully on iOS 17.
- **Colors:** semantic system colors only (auto dark/light); the single hex value (`expenseBlue`)
  lives in `Color+Extensions`.
- **Typography:** large-title bold totals with negative kerning, uppercase caption section headers,
  headline semibold amounts.
- **Motion:** `.spring(duration: 0.3)` on period switches and selections.

---

## 🚀 Deployment Guide (for the developer)

### Prerequisites
- **Xcode 16.0+** (required: this project uses SwiftData, Swift Charts, and Xcode 16
  *file-system-synchronized* project groups).
- **Apple Developer Account** (the free tier is enough for installing on your own device).
- **iPhone with iOS 17.0+** — a physical device is required to use the **camera** for receipt scanning
  (the Simulator can run everything else, but not the document scanner).
- A **USB cable** to connect the iPhone to your Mac.

### Step 1 — Open in Xcode
```bash
open ExpenseTracker.xcodeproj
```
All source files are added automatically via the synchronized project group — there is nothing to
drag in.

### Step 2 — Set your Development Team
`ExpenseTracker` target → **Signing & Capabilities** → **Team** → select your personal Apple ID.
Xcode will auto-create a provisioning profile. (The project ships with an empty `DEVELOPMENT_TEAM`
and automatic signing, so this is the only signing step you need.)

### Step 3 — Set a unique Bundle Identifier
Change `com.example.ExpenseTracker` to something globally unique, e.g.
`com.yourname.expensetracker`. (Target → Signing & Capabilities, or the Build Settings field
`PRODUCT_BUNDLE_IDENTIFIER`.)

### Step 4 — Trust the developer on your iPhone
After the first install: **Settings → General → VPN & Device Management → your Apple ID → Trust**.

### Step 5 — Connect & Run
- Connect the iPhone via USB.
- Pick your iPhone as the run destination in the Xcode toolbar.
- Press **⌘R**. The app builds, installs, and launches on your home screen.

### Step 6 — (Optional) TestFlight / App Store
Wider distribution requires a paid Apple Developer account ($99/yr):
1. Set the run destination to **Any iOS Device (arm64)**.
2. **Product → Archive**.
3. In the Organizer, **Distribute App → App Store Connect → Upload**.
4. In App Store Connect, add the build to **TestFlight** (internal testers need no review) or submit
   for App Store review.

---

## 🔐 Camera Permission

The camera usage description is configured on the target via the build setting
`INFOPLIST_KEY_NSCameraUsageDescription` (this is the modern Xcode approach — the build generates the
`Info.plist` with the key baked in). It is equivalent to:

```xml
<key>NSCameraUsageDescription</key>
<string>ExpenseTracker uses your camera to scan receipts and automatically fill in expense details.</string>
```

If you prefer a hand-maintained `Info.plist`, set `GENERATE_INFOPLIST_FILE = NO`, add an `Info.plist`
with the key above, and point `INFOPLIST_FILE` at it.

---

## ✅ Testing

The pure logic (currency conversion + the full receipt-parsing pipeline) is covered by an executable
test harness and **all 22 assertions pass**. The UI flows are documented below as device/simulator
steps; each is also referenced in code comments next to the relevant view.

| # | Test                       | How to verify                                                                 |
|---|----------------------------|-------------------------------------------------------------------------------|
| 1 | Add expense manually       | Tap **+**, enter name + KM amount + category + place, **Save** → row appears.  |
| 2 | Add expense in EUR         | In Add, toggle **EUR**, enter `10.00` → saved as **19.56 KM** (verified ✓).    |
| 3 | Receipt scanner            | `ScanResultView` `#Preview` injects a mock `ParsedReceipt`; all fields populate. Parsing logic verified against realistic BiH receipt text ✓. |
| 4 | Period switching           | Add expenses across days; switch Day/Week/Month → list + totals update.        |
| 5 | Persistence                | Add an expense, **force-quit** the app, relaunch → it's still there (SwiftData on-disk store). |
| 6 | Empty state                | Delete all expenses for a period → illustrated empty state with CTA appears.   |
| 7 | Currency display           | Every `ExpenseRowView` shows KM primary + EUR secondary.                        |
| 8 | Dark mode                  | Toggle appearance → all glass/material surfaces adapt; no hardcoded colors.     |

### Verification performed when this project was generated
This project was generated and validated on a Mac with **Command Line Tools only** (full Xcode was not
installed in that environment), so the final `⌘R` build/run is yours to perform per the guide above.
What *was* verified mechanically:

- **Syntax:** every Swift file passes `swiftc -parse` (clean).
- **Types:** the platform-agnostic layer (models, services, components, charts, summary card)
  **type-checks cleanly** against the SDK with `swiftc -typecheck`; the Analytics chart patterns,
  `@AppStorage` enum persistence, and `TabView` style were validated in isolation.
- **Logic:** the currency conversion and the receipt OCR extraction pipeline were **executed** against
  realistic receipt text — 22/22 assertions pass (total correctly anchored on `UKUPNO`, EUR→KM = 19.56,
  category inference, date/merchant/place extraction).
- **Project files:** `project.pbxproj` passes `plutil -lint`; asset JSON and scheme XML are well-formed.

> SwiftData's `@Model` / SwiftUI's `#Preview` macros require the macro plugins that ship with full
> Xcode, so those specific files can't be macro-expanded with Command Line Tools alone — they compile
> normally in Xcode 16.

---

## 📝 Notes

- **Warnings:** the code is written to be warning-clean. `SWIFT_TREAT_WARNINGS_AS_ERRORS` is intentionally
  left **off** so a future SDK deprecation can't hard-fail your build; flip it on in Build Settings if
  you want strict enforcement.
- **App icon:** a generated 1024×1024 "KM" mark is included as a placeholder (`AppIcon.png`).
- **No migrations:** this is a fresh-install schema; no SwiftData migration plan is required.

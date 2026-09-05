# 📱 iOS Expense Tracker (100% On-Device & Serverless)

A privacy-focused iOS expense tracking application where **all financial data is stored strictly on your iPhone** using Apple's modern **SwiftData** engine. There are zero external servers, zero cloud accounts required, and zero network calls made.

The app features an interactive financial dashboard with **SwiftUI Charts**, transaction filtering, budget management, and an intelligent **Bank SMS Transaction Parser** with native support for **iOS Shortcuts Automations**.

---

## ✨ Features

- 🔒 **100% Local On-Device Database**: Built on **SwiftData** (backed by encrypted SQLite inside the iOS sandbox). No server, no account signup, no telemetry.
- 💬 **Bank SMS Reader & Intelligent Parser**:
  - Automatically parses bank alerts (HDFC, SBI, ICICI, Axis, Chase, BofA, Wells Fargo, Amex, UPI, and global banks).
  - Extracts **Amount**, **Transaction Type** (Debit / Credit), **Merchant / Payee**, **Bank Name**, **Card / Account Last 4 Digits**, and **Available Balance**.
  - Auto-assigns categories based on merchant recognition (e.g., Starbucks/Swiggy -> Food & Dining, Uber -> Transport, Walmart -> Groceries).
  - Preserves the **exact original bank SMS** inside each transaction so you can inspect the full message anytime.
- ⚡ **Automated Background SMS Logging (iOS Shortcuts)**:
  - Implements Apple's native `AppIntents` framework (`ParseBankSMSIntent`).
  - Configure a simple 1-minute automation in Apple's built-in **Shortcuts** app: whenever your bank sends an SMS containing *"debited"* or *"spent"*, it automatically logs into your iPhone's database in the background!
- 📋 **Smart Clipboard Detection**:
  - Copy any bank message and open the app—it detects the transaction alert and prompts you to log it in 1 tap.
- 📊 **Financial Analytics Dashboard**:
  - **SwiftUI Charts**: Donut category breakdown (`SectorMark`) and 7-day spending trends (`BarMark`).
  - Total Spend, Total Income, and Net Savings metrics.
  - Monthly budget limit progress bar with visual overspending alerts.
- 🗂️ **Transaction Management**:
  - Search by vendor, bank, note, or account digits.
  - Filter by Expense/Income, category, or payment mode.
  - Grouped chronologically (Today, Yesterday, Earlier This Month, Older).
- ⚙️ **Customization & Data Ownership**:
  - Multi-currency support (₹ INR, $ USD, € EUR, £ GBP, ¥ JPY, etc.).
  - Category manager with custom SF Symbols and colors.
  - One-tap local CSV export to save or share via iOS ShareSheet.

---

## 📂 Project Architecture

```
c:\expnese\
├── ExpenseTrackerApp.swift          # Main entrypoint with SwiftData container & clipboard watcher
├── Package.swift                    # Swift Package definition (iOS 17.0+)
│
├── Models\                          # SwiftData on-device schema
│   ├── Enums.swift                  # TransactionType, PaymentMode, Currency definitions
│   ├── ExpenseTransaction.swift     # Core model (amount, merchant, date, rawSMS, bank, etc.)
│   ├── ExpenseCategory.swift        # Pre-seeded & custom categories with icons and colors
│   ├── BankAccount.swift            # Local bank accounts and credit cards tracker
│   └── Budget.swift                 # Monthly spending limit model
│
├── Services\                        # Business logic & parsers
│   ├── BankSMSParser.swift          # Regex & heuristic extraction engine
│   ├── BankPatternRegistry.swift    # Known banks & merchant-to-category dictionary
│   ├── CurrencyFormatter.swift      # Multi-currency formatting & compact notations
│   └── ExportImportService.swift    # 100% offline CSV data export
│
├── ViewModels\                      # State & aggregation logic
│   ├── DashboardViewModel.swift     # Spend/income totals, category shares, 7-day trends
│   └── TransactionListViewModel.swift # Filtering, searching, sorting, date grouping
│
├── Views\                           # SwiftUI user interface
│   ├── Dashboard\
│   │   ├── DashboardView.swift      # Main dashboard overview & quick actions
│   │   ├── SpendingChartView.swift  # SwiftUI Charts (Donut & Bar trends)
│   │   └── BudgetProgressCard.swift # Visual monthly budget tracker
│   ├── Transactions\
│   │   ├── TransactionListView.swift    # Searchable list with filter chips
│   │   ├── TransactionDetailView.swift  # Detailed view with original bank SMS viewer
│   │   └── AddTransactionView.swift     # Clean manual expense creation form
│   ├── SMSParser\
│   │   ├── QuickSMSInputView.swift      # Interactive SMS paste & sample tester sheet
│   │   └── SMSAutomationGuideView.swift # Visual tutorial for iOS Shortcuts setup
│   ├── Settings\
│   │   ├── SettingsView.swift           # Currency, offline CSV backup, privacy guarantee
│   │   └── ManageCategoriesView.swift   # Add/delete custom categories
│   └── Components\
│       ├── StatCard.swift               # Overview metric cards
│       └── TransactionRowView.swift     # Standard transaction row item
│
├── Intents\
│   └── ParseSMSIntent.swift         # Apple AppIntents for native iOS Shortcuts automation
│
└── Tests\
    └── BankSMSParserTests.swift     # Unit tests verifying multi-bank parsing
```

---

## 🚀 How to Run in Xcode

1. **Prerequisites**: Mac with **macOS Sonoma / Sequoia** and **Xcode 15.0+** (targeting iOS 17.0+).
2. **Open in Xcode**:
   - Launch Xcode, select **File > Open**, and select the `c:\expnese` folder (or open via `Package.swift`).
   - Alternatively, create a standard iOS SwiftUI project in Xcode and drag the `Models`, `Services`, `ViewModels`, `Views`, `Intents`, and `ExpenseTrackerApp.swift` files into your project target.
3. **Select Target**:
   - In Xcode's scheme selector, choose an **iPhone 15 / 16 Simulator** or connect your physical iPhone.
4. **Build & Run**:
   - Press `Cmd + R` to build and launch the app!

---

## 🤖 How to Automate Bank SMS on your iPhone (iOS Shortcuts)

Because Apple restricts third-party apps from secretly scanning your personal SMS inbox in the background, Apple provides an official, private bridge via the **Shortcuts App**:

1. Open Apple's built-in **Shortcuts** app on your iPhone.
2. Tap the **Automation** tab at the bottom, then tap **+** (New Automation).
3. Select **Message** as the trigger.
4. In **Message Contains**, enter keywords your bank uses: e.g. `debited`, `spent`, `credited`, `withdrawn`.
5. Select **Run Immediately** (uncheck "Ask Before Running").
6. Tap **Next**, then add an Action: search for **ExpenseTracker** and choose **Parse Bank SMS**.
7. Select **Shortcut Input** (the incoming message text) as the input.
8. Tap **Done**!

Now, whenever you pay via UPI, Credit Card, or Debit Card and receive a bank alert, it is extracted and logged into your on-device expense tracker automatically without opening the app!

import Foundation

/// Result of parsing a bank SMS or push notification
public struct ParsedSMSResult: Identifiable {
    public let id = UUID()
    public var amount: Double?
    public var type: TransactionType
    public var merchant: String
    public var bankName: String?
    public var accountLast4: String?
    public var date: Date
    public var suggestedCategoryName: String
    public var paymentMode: PaymentMode
    public var remainingBalance: Double?
    public var rawMessage: String
    public var confidenceScore: Double // 0.0 to 1.0

    public var isValidTransaction: Bool {
        amount != nil && amount! > 0
    }
}

/// Intelligent parser for financial transaction alerts from SMS and push notifications
public struct BankSMSParser {

    /// Parses an incoming SMS text and extracts financial parameters
    public static func parse(message: String) -> ParsedSMSResult {
        let cleaned = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = cleaned.lowercased()

        // 1. Determine Transaction Type (Debit vs Credit)
        let type = determineType(lower)

        // 2. Extract Amount
        let amount = extractAmount(from: cleaned)

        // 3. Extract Bank Name
        let bankName = extractBankName(from: cleaned)

        // 4. Extract Account / Card Last 4 Digits
        let accountLast4 = extractAccountLast4(from: cleaned)

        // 5. Extract Payment Mode
        let paymentMode = determinePaymentMode(lower)

        // 6. Extract Merchant / Beneficiary
        let merchant = extractMerchant(from: cleaned, lower: lower)

        // 7. Auto-categorize based on Merchant
        let suggestedCategory = categorize(merchant: merchant)

        // 8. Extract Available Balance (if present)
        let balance = extractBalance(from: cleaned)

        // 9. Compute Confidence Score
        var score: Double = 0.0
        if amount != nil { score += 0.4 }
        if !merchant.isEmpty && merchant != "Unknown Merchant" { score += 0.3 }
        if bankName != nil { score += 0.15 }
        if accountLast4 != nil { score += 0.15 }

        return ParsedSMSResult(
            amount: amount,
            type: type,
            merchant: merchant,
            bankName: bankName,
            accountLast4: accountLast4,
            date: Date(),
            suggestedCategoryName: suggestedCategory,
            paymentMode: paymentMode,
            remainingBalance: balance,
            rawMessage: cleaned,
            confidenceScore: min(score, 1.0)
        )
    }

    // MARK: - Amount Extraction

    private static func extractAmount(from text: String) -> Double? {
        // Regex patterns for amounts:
        // Matches: Rs. 1,450.00, Rs 500, INR 1299.50, $45.99, USD 120, EUR 35.00, debited by 450.00
        let patterns = [
            #"(?:(?:rs\.?|inr|usd|eur|gbp|\$|€|£)\s*)([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?)"#,
            #"(?:debited|credited|spent|paid|withdrawn|charged|txn of|amount of)\s+(?:by\s+)?(?:(?:rs\.?|inr|usd|\$|€|£)\s*)?([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?)"#,
            #"([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?)\s*(?:inr|usd|eur|gbp)"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   match.numberOfRanges > 1,
                   let amountRange = Range(match.range(at: 1), in: text) {
                    let amountStr = String(text[amountRange]).replacingOccurrences(of: ",", with: "")
                    if let val = Double(amountStr), val > 0 {
                        return val
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Type Determination

    private static func determineType(_ text: String) -> TransactionType {
        let isIncome = BankPatternRegistry.incomeKeywords.contains { text.contains($0) }
        let isExpense = BankPatternRegistry.expenseKeywords.contains { text.contains($0) }

        if isIncome && !isExpense {
            return .income
        }
        return .expense // default to expense for bank alerts
    }

    // MARK: - Bank Name Extraction

    private static func extractBankName(from text: String) -> String? {
        for (pattern, displayName) in BankPatternRegistry.knownBanks {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(text.startIndex..., in: text)
                if regex.firstMatch(in: text, range: range) != nil {
                    return displayName
                }
            }
        }
        return nil
    }

    // MARK: - Account Number Extraction

    private static func extractAccountLast4(from text: String) -> String? {
        // Matches: A/C ending 1234, XX1234, **1234, card ending in 4567, Card 1234
        let patterns = [
            #"(?:a\/c|account|acct|card|ending in|ending with|ending)\s*(?:no\.?)?\s*[:\-]?\s*(?:[xX\*]+)?([0-9]{4})\b"#,
            #"[xX\*]{2,}([0-9]{4})\b"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   match.numberOfRanges > 1,
                   let last4Range = Range(match.range(at: 1), in: text) {
                    return String(text[last4Range])
                }
            }
        }
        return nil
    }

    // MARK: - Payment Mode Determination

    private static func determinePaymentMode(_ text: String) -> PaymentMode {
        if text.contains("upi") || text.contains("vpa") {
            return .upi
        } else if text.contains("credit card") || text.contains("card ending") || text.contains("spent on card") {
            return .creditCard
        } else if text.contains("debit card") || text.contains("atm") {
            return .debitCard
        } else if text.contains("netbanking") || text.contains("neft") || text.contains("imps") || text.contains("rtgs") {
            return .netBanking
        }
        return .other
    }

    // MARK: - Merchant Extraction

    private static func extractMerchant(from text: String, lower: String) -> String {
        // Pattern 1: Look for "at [Merchant]", "to [Merchant]", "towards [Merchant]", "info: [Merchant]"
        let merchantPatterns = [
            #"(?:at|to|towards|info\/|info:)\s+([A-Za-z0-9\.\s\*\&]{3,30}?)(?:\s+on|\s+ref|\s+avl|\s+bal|\.|$)"#,
            #"(?:vpa\s+)([A-Za-z0-9\.\@\_]+)"#
        ]

        for pattern in merchantPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range),
                   match.numberOfRanges > 1,
                   let mRange = Range(match.range(at: 1), in: text) {
                    var candidate = String(text[mRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    candidate = candidate.replacingOccurrences(of: "Ref.*", with: "", options: .regularExpression)
                    candidate = candidate.replacingOccurrences(of: "Avl.*", with: "", options: .regularExpression)
                    if candidate.count > 2 && candidate.count < 35 {
                        return candidate
                    }
                }
            }
        }

        // Pattern 2: Scan for known vendors directly in text
        for (keyword, _) in BankPatternRegistry.merchantCategoryMap {
            if lower.contains(keyword) {
                return keyword.capitalized
            }
        }

        return "Unknown Merchant"
    }

    // MARK: - Auto-Categorization

    public static func categorize(merchant: String) -> String {
        let clean = merchant.lowercased()
        for (keyword, category) in BankPatternRegistry.merchantCategoryMap {
            if clean.contains(keyword) {
                return category
            }
        }
        return "General / Miscellaneous"
    }

    // MARK: - Available Balance Extraction

    private static func extractBalance(from text: String) -> Double? {
        let pattern = #"(?:avl(?:ilable)?\s*bal(?:ance)?|bal(?:\s*is)?)\s*[:\-]?\s*(?:rs\.?|inr|usd|\$)?\s*([0-9]{1,3}(?:,[0-9]{2,3})*(?:\.[0-9]{1,2})?)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               match.numberOfRanges > 1,
               let balRange = Range(match.range(at: 1), in: text) {
                let balStr = String(text[balRange]).replacingOccurrences(of: ",", with: "")
                return Double(balStr)
            }
        }
        return nil
    }
}

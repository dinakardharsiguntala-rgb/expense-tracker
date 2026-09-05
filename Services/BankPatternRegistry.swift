import Foundation

/// Defines rules and dictionaries for bank SMS recognition and vendor classification
public struct BankPatternRegistry {

    /// Known bank names and regex identifiers
    public static let knownBanks: [(identifier: String, displayName: String)] = [
        ("HDFCBK|HDFC", "HDFC Bank"),
        ("SBIINB|SBIPSG|SBMSMS|SBI", "State Bank of India"),
        ("ICICIB|ICICI", "ICICI Bank"),
        ("AXISBK|AXIS", "Axis Bank"),
        ("KOTAKB|KOTAK", "Kotak Mahindra Bank"),
        ("CHASE|JPMORGAN", "JPMorgan Chase"),
        ("BOFA|BANK OF AMERICA", "Bank of America"),
        ("WELLS FARGO|WF", "Wells Fargo"),
        ("CITIBK|CITI", "Citibank"),
        ("AMEX|AMERICAN EXPRESS", "American Express"),
        ("CAPONE|CAPITAL ONE", "Capital One"),
        ("BARCLAYS", "Barclays"),
        ("REVOLUT", "Revolut"),
        ("PAYTM", "Paytm Bank"),
        ("IDFC", "IDFC First Bank"),
        ("PNBSMS|PNB", "Punjab National Bank")
    ]

    /// Mapping of known merchants/keywords to standard category names
    public static let merchantCategoryMap: [String: String] = [
        // Food & Dining
        "starbucks": "Food & Dining",
        "mcdonald": "Food & Dining",
        "burger king": "Food & Dining",
        "subway": "Food & Dining",
        "domino": "Food & Dining",
        "pizza hut": "Food & Dining",
        "kfc": "Food & Dining",
        "taco bell": "Food & Dining",
        "chipotle": "Food & Dining",
        "dunkin": "Food & Dining",
        "swiggy": "Food & Dining",
        "zomato": "Food & Dining",
        "doordash": "Food & Dining",
        "ubereats": "Food & Dining",
        "uber eats": "Food & Dining",
        "grubhub": "Food & Dining",
        "restaurant": "Food & Dining",
        "cafe": "Food & Dining",
        "diner": "Food & Dining",

        // Groceries
        "walmart": "Groceries",
        "target": "Groceries",
        "whole foods": "Groceries",
        "trader joe": "Groceries",
        "kroger": "Groceries",
        "safeway": "Groceries",
        "aldi": "Groceries",
        "costco": "Groceries",
        "blinkit": "Groceries",
        "zepto": "Groceries",
        "bigbasket": "Groceries",
        "instacart": "Groceries",
        "supermarket": "Groceries",
        "grocery": "Groceries",

        // Transportation & Fuel
        "uber": "Transportation & Fuel",
        "lyft": "Transportation & Fuel",
        "ola": "Transportation & Fuel",
        "rapido": "Transportation & Fuel",
        "shell": "Transportation & Fuel",
        "chevron": "Transportation & Fuel",
        "exxon": "Transportation & Fuel",
        "bp gas": "Transportation & Fuel",
        "fuel": "Transportation & Fuel",
        "petrol": "Transportation & Fuel",
        "hpcl": "Transportation & Fuel",
        "bpcl": "Transportation & Fuel",
        "ioc": "Transportation & Fuel",
        "parking": "Transportation & Fuel",
        "metro": "Transportation & Fuel",
        "transit": "Transportation & Fuel",
        "toll": "Transportation & Fuel",
        "fastag": "Transportation & Fuel",

        // Shopping & Retail
        "amazon": "Shopping",
        "flipkart": "Shopping",
        "myntra": "Shopping",
        "ebay": "Shopping",
        "best buy": "Shopping",
        "apple store": "Shopping",
        "zara": "Shopping",
        "h&m": "Shopping",
        "nike": "Shopping",
        "adidas": "Shopping",
        "sephora": "Shopping",
        "ikea": "Shopping",
        "mall": "Shopping",

        // Bills & Utilities
        "verizon": "Bills & Utilities",
        "at&t": "Bills & Utilities",
        "t-mobile": "Bills & Utilities",
        "airtel": "Bills & Utilities",
        "jio": "Bills & Utilities",
        "vi": "Bills & Utilities",
        "vodafone": "Bills & Utilities",
        "electricity": "Bills & Utilities",
        "electric": "Bills & Utilities",
        "water bill": "Bills & Utilities",
        "gas bill": "Bills & Utilities",
        "broadband": "Bills & Utilities",
        "wifi": "Bills & Utilities",

        // Entertainment & Subscriptions
        "netflix": "Entertainment",
        "spotify": "Entertainment",
        "disney": "Entertainment",
        "hulu": "Entertainment",
        "prime video": "Entertainment",
        "apple.com/bill": "Entertainment",
        "itunes": "Entertainment",
        "youtube": "Entertainment",
        "playstation": "Entertainment",
        "xbox": "Entertainment",
        "steam": "Entertainment",
        "cinema": "Entertainment",
        "amc": "Entertainment",
        "bookmyshow": "Entertainment",

        // Healthcare
        "cvs": "Healthcare & Pharmacy",
        "walgreens": "Healthcare & Pharmacy",
        "pharmacy": "Healthcare & Pharmacy",
        "chemist": "Healthcare & Pharmacy",
        "apollo": "Healthcare & Pharmacy",
        "netmeds": "Healthcare & Pharmacy",
        "1mg": "Healthcare & Pharmacy",
        "hospital": "Healthcare & Pharmacy",
        "clinic": "Healthcare & Pharmacy",
        "dental": "Healthcare & Pharmacy",

        // Travel
        "airline": "Travel & Hotels",
        "airways": "Travel & Hotels",
        "delta": "Travel & Hotels",
        "united airlines": "Travel & Hotels",
        "american air": "Travel & Hotels",
        "indigo": "Travel & Hotels",
        "air india": "Travel & Hotels",
        "booking.com": "Travel & Hotels",
        "airbnb": "Travel & Hotels",
        "expedia": "Travel & Hotels",
        "hotel": "Travel & Hotels",
        "marriott": "Travel & Hotels",
        "hilton": "Travel & Hotels"
    ]

    /// Debit keywords indicating an expense
    public static let expenseKeywords = [
        "debited", "spent", "paid", "sent", "charged", "withdrawn",
        "purchase", "deducted", "dr", "debit", "txn of", "transferred to",
        "payment of"
    ]

    /// Credit keywords indicating income or refund
    public static let incomeKeywords = [
        "credited", "received", "deposited", "refund", "reversed",
        "cr", "credit", "cashback", "salary", "added to"
    ]
}

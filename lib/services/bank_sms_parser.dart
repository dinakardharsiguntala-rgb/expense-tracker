import '../models/transaction.dart';

class ParsedBankSMS {
  final double amount;
  final TransactionType type;
  final String? merchant;
  final String? accountLast4;
  final String? bankName;
  final PaymentMode paymentMode;
  final String categoryId;
  final String rawSMS;
  final DateTime date;

  ParsedBankSMS({
    required this.amount,
    required this.type,
    this.merchant,
    this.accountLast4,
    this.bankName,
    required this.paymentMode,
    required this.categoryId,
    required this.rawSMS,
    required this.date,
  });

  ExpenseTransaction toExpenseTransaction({String? id}) {
    return ExpenseTransaction(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      type: type,
      categoryId: categoryId,
      merchant: merchant ?? (type == TransactionType.income ? 'Deposit/Salary' : 'General Store'),
      date: date,
      note: 'Auto-parsed from SMS (${bankName ?? "Bank"})',
      rawSMS: rawSMS,
      bankName: bankName,
      accountLast4: accountLast4,
      paymentMode: paymentMode,
      isAutoParsed: true,
    );
  }
}

class BankSMSParser {
  static final BankSMSParser instance = BankSMSParser._();
  BankSMSParser._();

  // Common Bank Senders
  static final Map<String, String> bankSenderMap = {
    'HDFCBK': 'HDFC Bank',
    'SBINB': 'State Bank of India',
    'SBIPAY': 'SBI UPI',
    'ICICIB': 'ICICI Bank',
    'AXISBK': 'Axis Bank',
    'KOTAKB': 'Kotak Bank',
    'PNBSMS': 'Punjab National Bank',
    'BOBTXN': 'Bank of Baroda',
    'CHASE': 'Chase Bank',
    'CITI': 'Citi',
    'BOFA': 'Bank of America',
    'WELLS': 'Wells Fargo',
    'AMEX': 'American Express',
  };

  ParsedBankSMS? parse(String smsText, {String? sender}) {
    final clean = smsText.trim();
    if (clean.isEmpty) return null;

    // 1. Determine Bank Name
    String? bankName;
    if (sender != null) {
      final upperSender = sender.toUpperCase();
      for (var entry in bankSenderMap.entries) {
        if (upperSender.contains(entry.key)) {
          bankName = entry.value;
          break;
        }
      }
    }
    if (bankName == null) {
      if (RegExp(r'\bHDFC\b', caseSensitive: false).hasMatch(clean)) bankName = 'HDFC Bank';
      else if (RegExp(r'\bSBI\b', caseSensitive: false).hasMatch(clean)) bankName = 'State Bank of India';
      else if (RegExp(r'\bICICI\b', caseSensitive: false).hasMatch(clean)) bankName = 'ICICI Bank';
      else if (RegExp(r'\bAxis\b', caseSensitive: false).hasMatch(clean)) bankName = 'Axis Bank';
      else if (RegExp(r'\bKotak\b', caseSensitive: false).hasMatch(clean)) bankName = 'Kotak Bank';
      else if (RegExp(r'\bChase\b', caseSensitive: false).hasMatch(clean)) bankName = 'Chase';
      else if (RegExp(r'\bAmex|American Express\b', caseSensitive: false).hasMatch(clean)) bankName = 'American Express';
      else if (RegExp(r'\bCiti\b', caseSensitive: false).hasMatch(clean)) bankName = 'Citi';
    }

    // 2. Extract Amount
    // Matches Rs. 450.00, INR 1,299, USD 45.00, $50.00, €30.00
    final amountPattern = RegExp(
      r'(?:(?:Rs\.?|INR|\$|€|USD|EUR)\s*|debited\s+by\s*|credited\s+by\s*)([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );

    final amountMatch = amountPattern.firstMatch(clean);
    if (amountMatch == null) return null;

    final rawAmountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '';
    final amount = double.tryParse(rawAmountStr);
    if (amount == null || amount <= 0) return null;

    // 3. Determine Transaction Type (Debit vs Credit)
    TransactionType type = TransactionType.expense;
    if (RegExp(r'\b(credited|deposited|refunded|received|cashback|added)\b', caseSensitive: false).hasMatch(clean)) {
      type = TransactionType.income;
    } else if (RegExp(r'\b(debited|spent|paid|withdrawn|purchase|deducted)\b', caseSensitive: false).hasMatch(clean)) {
      type = TransactionType.expense;
    }

    // 4. Extract Account / Card Last 4 Digits
    String? accountLast4;
    final acctMatch = RegExp(r'(?:A/c|Acct|Account|Card|ending|A/C)\s*(?:no\.?)?\s*(?:[*xX]+)?\s*([0-9]{4})\b', caseSensitive: false).firstMatch(clean);
    if (acctMatch != null) {
      accountLast4 = acctMatch.group(1);
    }

    // 5. Detect Payment Mode
    PaymentMode mode = PaymentMode.other;
    if (RegExp(r'\b(UPI|VPA|GPay|PhonePe|Paytm)\b', caseSensitive: false).hasMatch(clean)) {
      mode = PaymentMode.upi;
    } else if (RegExp(r'\b(Credit Card|CC)\b', caseSensitive: false).hasMatch(clean)) {
      mode = PaymentMode.creditCard;
    } else if (RegExp(r'\b(Debit Card|ATM|DC)\b', caseSensitive: false).hasMatch(clean)) {
      mode = PaymentMode.debitCard;
    } else if (RegExp(r'\b(NetBanking|IMPS|NEFT|RTGS)\b', caseSensitive: false).hasMatch(clean)) {
      mode = PaymentMode.netBanking;
    }

    // 6. Extract Merchant / Beneficiary
    String? merchant;
    final merchantMatch = RegExp(r'(?:at|to|info|towards|vpa)\s+([A-Za-z0-9\s&.\-_]+?)(?=\s+(?:on|using|ref|bal|avl|available|\.|$))', caseSensitive: false).firstMatch(clean);
    if (merchantMatch != null) {
      final rawM = merchantMatch.group(1)?.trim();
      if (rawM != null && rawM.length > 1 && !rawM.toLowerCase().startsWith('a/c')) {
        merchant = rawM;
      }
    }

    // 7. Auto-Categorize based on merchant/keywords
    String categoryId = 'others';
    final lower = clean.toLowerCase();
    final lowerMerchant = (merchant ?? '').toLowerCase();

    if (type == TransactionType.income) {
      if (lower.contains('salary') || lower.contains('payroll')) {
        categoryId = 'salary';
      } else if (lower.contains('dividend') || lower.contains('interest') || lower.contains('mutual fund')) {
        categoryId = 'investments';
      } else {
        categoryId = 'salary';
      }
    } else {
      if (lowerMerchant.contains('swiggy') || lowerMerchant.contains('zomato') ||
          lowerMerchant.contains('starbucks') || lowerMerchant.contains('mcdonald') ||
          lowerMerchant.contains('cafe') || lowerMerchant.contains('restaurant') ||
          lower.contains('dining') || lower.contains('food')) {
        categoryId = 'food';
      } else if (lowerMerchant.contains('blinkit') || lowerMerchant.contains('zepto') ||
          lowerMerchant.contains('instamart') || lowerMerchant.contains('supermarket') ||
          lowerMerchant.contains('grocery') || lowerMerchant.contains('walmart')) {
        categoryId = 'groceries';
      } else if (lowerMerchant.contains('uber') || lowerMerchant.contains('ola') ||
          lowerMerchant.contains('fuel') || lowerMerchant.contains('petrol') ||
          lowerMerchant.contains('shell') || lower.contains('hpcl') || lower.contains('bpcl')) {
        categoryId = 'transport';
      } else if (lowerMerchant.contains('amazon') || lowerMerchant.contains('flipkart') ||
          lowerMerchant.contains('myntra') || lowerMerchant.contains('zara') ||
          lowerMerchant.contains('apple')) {
        categoryId = 'shopping';
      } else if (lowerMerchant.contains('netflix') || lowerMerchant.contains('spotify') ||
          lowerMerchant.contains('cinema') || lowerMerchant.contains('bookmyshow') ||
          lowerMerchant.contains('hotstar')) {
        categoryId = 'entertainment';
      } else if (lowerMerchant.contains('bescom') || lowerMerchant.contains('airtel') ||
          lowerMerchant.contains('jio') || lowerMerchant.contains('electricity') ||
          lowerMerchant.contains('water') || lower.contains('bill')) {
        categoryId = 'bills';
      } else if (lowerMerchant.contains('pharmacy') || lowerMerchant.contains('apollo') ||
          lowerMerchant.contains('hospital') || lowerMerchant.contains('clinic')) {
        categoryId = 'health';
      } else if (lowerMerchant.contains('indigo') || lowerMerchant.contains('air india') ||
          lowerMerchant.contains('makemytrip') || lowerMerchant.contains('hotel') ||
          lowerMerchant.contains('irctc')) {
        categoryId = 'travel';
      }
    }

    return ParsedBankSMS(
      amount: amount,
      type: type,
      merchant: merchant,
      accountLast4: accountLast4,
      bankName: bankName,
      paymentMode: mode,
      categoryId: categoryId,
      rawSMS: clean,
      date: DateTime.now(),
    );
  }
}


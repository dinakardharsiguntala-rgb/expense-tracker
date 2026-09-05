import XCTest
@testable import ExpenseTracker

final class BankSMSParserTests: XCTestCase {

    func testHDFCCreditCardDebit() {
        let sms = "Alert: You've spent Rs.1,499.00 on your HDFC Bank Credit Card ending 4321 at STARBUCKS COFFEE on 05-SEP-26. Avl Bal: Rs.45,200.00."
        let result = BankSMSParser.parse(message: sms)

        XCTAssertTrue(result.isValidTransaction)
        XCTAssertEqual(result.amount, 1499.00)
        XCTAssertEqual(result.type, .expense)
        XCTAssertEqual(result.accountLast4, "4321")
        XCTAssertEqual(result.bankName, "HDFC Bank")
        XCTAssertEqual(result.suggestedCategoryName, "Food & Dining")
        XCTAssertEqual(result.remainingBalance, 45200.00)
    }

    func testSBIUPITransaction() {
        let sms = "Dear SBI User, A/C 1234 debited by Rs 420.00 on 05Sep26 transfer to SWIGGY UPI: swiggy@icici Ref 429381. Bal: Rs 8,310.00"
        let result = BankSMSParser.parse(message: sms)

        XCTAssertTrue(result.isValidTransaction)
        XCTAssertEqual(result.amount, 420.00)
        XCTAssertEqual(result.type, .expense)
        XCTAssertEqual(result.accountLast4, "1234")
        XCTAssertEqual(result.bankName, "State Bank of India")
        XCTAssertEqual(result.paymentMode, .upi)
        XCTAssertEqual(result.suggestedCategoryName, "Food & Dining")
    }

    func testChaseUSDebitAlert() {
        let sms = "Chase Alert: You made a $45.50 debit card transaction at WHOLE FOODS with card ending in 8892 on 09/05/2026."
        let result = BankSMSParser.parse(message: sms)

        XCTAssertTrue(result.isValidTransaction)
        XCTAssertEqual(result.amount, 45.50)
        XCTAssertEqual(result.type, .expense)
        XCTAssertEqual(result.accountLast4, "8892")
        XCTAssertEqual(result.bankName, "JPMorgan Chase")
        XCTAssertEqual(result.suggestedCategoryName, "Groceries")
    }

    func testSalaryCredit() {
        let sms = "Your A/C ending in 9876 has been CREDITED with Rs 85,000.00 on 01-Sep-26 towards SALARY by TECH CORP. Avl Bal: Rs 92,450.00"
        let result = BankSMSParser.parse(message: sms)

        XCTAssertTrue(result.isValidTransaction)
        XCTAssertEqual(result.amount, 85000.00)
        XCTAssertEqual(result.type, .income)
        XCTAssertEqual(result.accountLast4, "9876")
    }

    func testUberRideExpense() {
        let sms = "Paid Rs 385.00 for your Uber ride using Paytm Wallet / ICICI NetBanking. Transaction ID: UB839201."
        let result = BankSMSParser.parse(message: sms)

        XCTAssertTrue(result.isValidTransaction)
        XCTAssertEqual(result.amount, 385.00)
        XCTAssertEqual(result.type, .expense)
        XCTAssertEqual(result.suggestedCategoryName, "Transportation & Fuel")
    }

    func testNonFinancialMessage() {
        let sms = "Your OTP for login is 492819. Do not share this with anyone."
        let result = BankSMSParser.parse(message: sms)

        XCTAssertFalse(result.isValidTransaction)
        XCTAssertNil(result.amount)
    }
}

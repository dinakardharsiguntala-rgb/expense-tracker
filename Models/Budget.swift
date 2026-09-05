import Foundation
import SwiftData

@Model
public final class Budget {
    @Attribute(.unique) public var id: UUID
    public var monthYear: String // e.g. "2026-09"
    public var monthlyLimit: Double
    public var notes: String

    public init(
        id: UUID = UUID(),
        monthYear: String,
        monthlyLimit: Double,
        notes: String = ""
    ) {
        self.id = id
        self.monthYear = monthYear
        self.monthlyLimit = monthlyLimit
        self.notes = notes
    }

    public static func currentMonthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
}

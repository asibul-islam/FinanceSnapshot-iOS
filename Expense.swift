import Foundation
import SwiftData

@Model
class Expense {
    var title: String
    var amount: Double
    var category: String
    var date: Date

    init(title: String, amount: Double, category: String, date: Date) {
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
    }
}

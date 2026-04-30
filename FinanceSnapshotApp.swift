import SwiftData
import SwiftUI

@main
struct FinanceSnapshotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Expense.self)
    }
}

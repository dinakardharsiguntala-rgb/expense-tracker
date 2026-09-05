import SwiftUI

public struct SMSAutomationGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(number: Int, title: String, description: String, icon: String)] = [
        (
            1,
            "Open Shortcuts App",
            "Open Apple's pre-installed 'Shortcuts' app on your iPhone.",
            "square.stack.3d.up.fill"
        ),
        (
            2,
            "Create New Automation",
            "Tap the 'Automation' tab at the bottom, then tap the '+' (New Automation) button.",
            "plus.circle.fill"
        ),
        (
            3,
            "Choose 'Message' Trigger",
            "Scroll and select 'Message'. In 'Message Contains', add keywords: 'debited, spent, credited, txn'.",
            "message.fill"
        ),
        (
            4,
            "Set 'Run Immediately'",
            "Select 'Run Immediately' so the shortcut runs automatically without requiring manual confirmation.",
            "bolt.badge.automatic.fill"
        ),
        (
            5,
            "Add Expense Action",
            "Tap Next, search for 'Expense Tracker' and choose the 'Parse Bank SMS' action, passing 'Shortcut Input'.",
            "arrow.right.circle.fill"
        ),
        (
            6,
            "All Set!",
            "Whenever your bank texts you, the transaction is extracted and stored on your iPhone instantly!",
            "checkmark.seal.fill"
        )
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Banner
                    HStack(spacing: 16) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple Privacy & SMS Automation")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("iOS does not allow third-party apps to read your SMS inbox secretly. Apple's Shortcuts provides a private, official way to automate bank alerts.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.08))
                    )

                    Text("Step-by-Step Configuration")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.top, 4)

                    // Step cards
                    VStack(spacing: 14) {
                        ForEach(steps, id: \.number) { step in
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 32, height: 32)
                                    Text("\(step.number)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(step.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: step.icon)
                                            .foregroundColor(.blue.opacity(0.8))
                                            .font(.subheadline)
                                    }

                                    Text(step.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                            )
                        }
                    }

                    // Tip box
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Tip: You can also copy any bank notification and open the app—it will detect the clipboard text automatically!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("SMS Automation Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

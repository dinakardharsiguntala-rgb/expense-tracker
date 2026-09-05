import SwiftUI

public struct SMSPermissionGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [(number: Int, title: String, description: String, icon: String)] = [
        (
            1,
            "Open iPhone Settings",
            "Go to your iPhone's home screen and open the 'Settings' app.",
            "gear"
        ),
        (
            2,
            "Tap 'Messages'",
            "Scroll down in Settings and tap the 'Messages' option.",
            "message.fill"
        ),
        (
            3,
            "Tap 'Unknown & Spam'",
            "Under the 'Message Filtering' section, tap 'Unknown & Spam'.",
            "shield.lefthalf.filled"
        ),
        (
            4,
            "Select 'Expense Tracker'",
            "Turn on 'Filter Unknown Senders', and under 'SMS Filtering', tap 'Expense Tracker' and choose 'Enable'.",
            "checkmark.seal.fill"
        ),
        (
            5,
            "You're All Set!",
            "iOS will now automatically route all incoming bank transaction messages to Expense Tracker in the background.",
            "sparkles"
        )
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Official Apple SMS Access")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Apple IdentityLookup Framework")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("By enabling SMS Filtering in iOS Settings, your iPhone automatically allows Expense Tracker to parse incoming bank and transaction messages in the background.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.appSecondaryBackground)
                    )

                    Text("How to Enable in iOS Settings:")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.top, 4)

                    // Steps List
                    VStack(spacing: 12) {
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

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(step.title)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: step.icon)
                                            .foregroundColor(.blue)
                                            .font(.caption)
                                    }

                                    Text(step.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.appSecondaryBackground)
                            )
                        }
                    }

                    // Privacy Note
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("100% Private to Your iPhone")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("The SMS filtering extension runs strictly on your device. Personal messages from your contacts are never touched, and no data is ever transmitted online.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(Color.green.opacity(0.08))
                    .cornerRadius(14)
                }
                .padding(16)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Automatic SMS Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


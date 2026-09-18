import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dependencies) private var dependencies

    @State private var userName = AppSettings.currentUserName
    @State private var venmoHandle = AppSettings.venmoHandle
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your profile")
                            .font(.headline)
                        TextField("Your name", text: $userName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                        Text("This name appears on trips and in shared reports — not “You”.")
                            .font(.caption)
                            .foregroundStyle(OweGoTheme.textSecondary)
                    }
                    .padding(16)
                    .owegoCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Venmo")
                            .font(.headline)
                        TextField("Venmo username", text: $venmoHandle)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Text("Used for payment deep links when settling. Leave blank to hide the Venmo option.")
                            .font(.caption)
                            .foregroundStyle(OweGoTheme.textSecondary)
                    }
                    .padding(16)
                    .owegoCard()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image("OweGoLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("OweGo")
                                    .font(.headline)
                                Text("Split trip expenses, settle up easily")
                                    .font(.caption)
                                    .foregroundStyle(OweGoTheme.textSecondary)
                            }
                        }
                        LabeledContent("Version", value: appVersionLabel)
                        LabeledContent("Data", value: "Local-first on this device")
                    }
                    .padding(16)
                    .owegoCard()
                }
                .padding()
            }
            .owegoScreenBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var appVersionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func save() {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        AppSettings.currentUserName = trimmed
        AppSettings.venmoHandle = venmoHandle
        do {
            if let dependencies {
                try CurrentUserNameSync.apply(name: trimmed, using: dependencies.tripRepository)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

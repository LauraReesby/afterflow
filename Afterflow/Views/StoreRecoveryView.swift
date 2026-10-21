import Foundation
import SwiftUI

/// Shown instead of the app when the data store can't be opened. Everything it offers
/// is non-destructive: the store files are only ever copied or moved aside, never deleted.
struct StoreRecoveryView: View {
    let error: Error
    let persistence: PersistenceController
    let onRetry: () -> Void
    let onStartFresh: () throws -> Void

    @State private var didRetry = false
    @State private var copiedFiles: [URL] = []
    @State private var showStartFreshConfirmation = false
    @State private var actionError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignConstants.Spacing.lg) {
                self.header
                self.reassuranceCard
                self.actions
                self.technicalDetails
            }
            .padding(.horizontal, DesignConstants.Spacing.large)
            .padding(.vertical, DesignConstants.Spacing.xl)
            .frame(maxWidth: DesignConstants.Recovery.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(AF.bg.ignoresSafeArea())
        .accessibilityIdentifier("storeRecoveryView")
        .task { self.prepareCopy() }
        .errorAlert(title: "Couldn't Move Your Data", error: self.$actionError)
        .confirmationDialog(
            "Start with a new, empty journal?",
            isPresented: self.$showStartFreshConfirmation,
            titleVisibility: .visible
        ) {
            Button("Start Fresh", role: .destructive) { self.startFresh() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current data stays on this device in a recovered-data folder. "
                + "It won't appear in Afterflow, and nothing is deleted.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignConstants.Spacing.small) {
            KickerLabel("Your data")
            Text("Afterflow couldn't open your data")
                .font(.afterflowDisplay(30))
                .foregroundStyle(AF.text)
                .accessibilityAddTraits(.isHeader)
            Text(self.explanation)
                .font(.afterflowBody(15))
                .foregroundStyle(AF.neutral(600))
        }
    }

    private var explanation: String {
        let cause = "This can happen after an interrupted update or when the device is low on storage."
        return self.didRetry ? "It still isn't opening. " + cause : cause
    }

    private var reassuranceCard: some View {
        TokenCard {
            HStack(alignment: .top, spacing: DesignConstants.Spacing.sm) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AF.accent2(700))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DesignConstants.Spacing.xxs) {
                    Text("Your data has not been deleted.")
                        .font(.afterflowBody(16, weight: .semibold))
                        .foregroundStyle(AF.text)
                    Text("It is still stored privately on this device. You can try again, "
                        + "save a copy to keep safe, or start with a fresh journal.")
                        .font(.afterflowBody(14))
                        .foregroundStyle(AF.neutral(600))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("storeRecoveryReassurance")
    }

    private var actions: some View {
        VStack(spacing: DesignConstants.Spacing.medium) {
            Button {
                self.didRetry = true
                self.onRetry()
            } label: {
                self.buttonLabel("Try Again", systemImage: "arrow.clockwise", color: AF.onAccent)
            }
            .buttonStyle(AFCapsuleButtonStyle(fill: AF.accent, pressedFill: AF.accentPressed))
            .accessibilityIdentifier("storeRecoveryRetryButton")
            .accessibilityHint("Tries to open your data again")

            if !self.copiedFiles.isEmpty {
                ShareLink(
                    items: self.copiedFiles,
                    preview: { SharePreview($0.lastPathComponent) },
                    label: {
                        self.buttonLabel(
                            "Save a Copy of My Data",
                            systemImage: "square.and.arrow.up",
                            color: AF.text
                        )
                    }
                )
                .buttonStyle(AFCapsuleButtonStyle(fill: AF.neutral(200), pressedFill: AF.neutral(300)))
                .accessibilityIdentifier("storeRecoverySaveCopyButton")
                .accessibilityHint("Shares a copy of your data files to keep or send to the developer")
            }

            Button {
                self.showStartFreshConfirmation = true
            } label: {
                Text("Start Fresh…")
                    .font(.afterflowBody(15, weight: .semibold))
                    .foregroundStyle(AF.accent(800))
                    .frame(minHeight: DesignConstants.Recovery.buttonHeight)
            }
            .buttonStyle(AFLinkButtonStyle())
            .accessibilityIdentifier("storeRecoveryStartFreshButton")
            .accessibilityHint("Asks for confirmation, then moves your data aside and starts a new journal")
        }
    }

    private var technicalDetails: some View {
        DisclosureGroup("Technical details") {
            Text(self.error.localizedDescription)
                .font(.afterflowBody(12))
                .foregroundStyle(AF.neutral(600))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, DesignConstants.Spacing.xs)
                .accessibilityIdentifier("storeRecoveryErrorDetails")
        }
        .font(.afterflowBody(13, weight: .semibold))
        .foregroundStyle(AF.neutral(600))
        .tint(AF.neutral(600))
    }

    private func buttonLabel(_ title: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: DesignConstants.Spacing.xs) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .accessibilityHidden(true)
            Text(title)
                .font(.afterflowBody(16, weight: .semibold))
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, minHeight: DesignConstants.Recovery.buttonHeight)
    }

    private func prepareCopy() {
        self.copiedFiles = (try? self.persistence.makeExportCopy()) ?? []
    }

    private func startFresh() {
        do {
            try self.onStartFresh()
        } catch {
            self.actionError = "Nothing was deleted. Please try again, or save a copy first."
        }
    }
}

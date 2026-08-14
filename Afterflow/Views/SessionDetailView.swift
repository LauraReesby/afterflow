import Foundation
import SwiftData
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

struct SessionDetailView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let session: TherapeuticSession
    /// Pushes the dedicated reflection screen; falls back to the edit sheet when
    /// unset (context-menu previews, calendar pushes).
    var onAddReflection: (() -> Void)?

    private let metadataService = MusicLinkMetadataService()

    @State private var showingEdit = false
    @State private var linkErrorMessage: String?
    @State private var updateError: String?
    @State private var isHydratingMusicLink = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignConstants.Spacing.lg) {
                self.identityBlock

                MoodJourneyCard(session: self.session)

                self.intentionSection

                self.musicSection

                self.reflectionSection
            }
            .padding(.horizontal, DesignConstants.Spacing.large)
            .padding(.top, DesignConstants.Spacing.md)
            .padding(.bottom, DesignConstants.Spacing.xl)
        }
        .background(AF.bg)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Session")
                    .font(.afterflowBody(15, weight: .semibold))
                    .foregroundStyle(AF.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .accessibilityLabel("Session: \(self.session.treatmentType.displayName)")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    self.showingEdit = true
                } label: {
                    Text("Edit")
                        .font(.afterflowBody(14, weight: .semibold))
                        .foregroundStyle(AF.accent(700))
                }
                .accessibilityHint("Opens the form to edit this session")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: self.$showingEdit) {
            NavigationStack {
                SessionFormView(session: self.session)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(DesignConstants.CornerRadius.card)
            .toolbarBackground(.visible, for: .automatic)
        }
        .alert(
            "Music Link",
            isPresented: Binding(
                get: { self.linkErrorMessage != nil },
                set: { if !$0 { self.linkErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.linkErrorMessage ?? "")
        }
        .errorAlert(title: "Update Failed", error: self.$updateError)
        .task {
            await self.hydrateMusicMetadataIfNeeded()
        }
    }

    // MARK: - Identity

    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: DesignConstants.Spacing.medium) {
            HStack(spacing: DesignConstants.Spacing.sm) {
                TreatmentAvatar(type: self.session.treatmentType, size: 52)

                VStack(alignment: .leading, spacing: 3) {
                    Text(self.session.treatmentType.displayName)
                        .font(.afterflowDisplay(30))
                        .foregroundStyle(AF.text)
                        .lineSpacing(30 * 0.05)

                    HStack(spacing: 4) {
                        Text(self.metaLine)
                            .font(.afterflowBody(13))
                            .foregroundStyle(AF.neutral(600))

                        if self.session.hasMusicLink {
                            self.summaryBadge
                        }
                    }
                }
            }

            if self.session.status == .needsReflection,
               let reminderText = self.session.reminderDisplayText {
                self.reminderPill(text: reminderText)
            }
        }
    }

    private var metaLine: String {
        let dayText = self.session.sessionDate.relativeSessionLabel
        let timeText = self.session.sessionDate.formatted(date: .omitted, time: .shortened)
        return "\(dayText), \(timeText) · \(self.session.administration.displayName)"
    }

    private func reminderPill(text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "bell")
                .font(.system(size: 11, weight: .semibold))
                .accessibilityHidden(true)
            Text(text)
                .font(.afterflowBody(12, weight: .semibold))
                .accessibilityIdentifier("detailReminderLabel")
        }
        .foregroundStyle(AF.accent(800))
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Capsule().fill(AF.accent(200)))
        .accessibilityLabel("Reminder: \(text)")
    }

    private var summaryBadge: some View {
        if let brand = brandImage(for: session.musicLinkProvider) {
            return AnyView(
                brand
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            )
        }
        return AnyView(
            Image(systemName: "music.note.list")
                .font(.system(size: 11))
                .foregroundStyle(AF.neutral(600))
        )
    }

    // MARK: - Intention

    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            KickerLabel("Intention")
            TokenCard {
                Text(self.session.intention.isEmpty ? "No intention captured." : self.session.intention)
                    .font(.afterflowBody(16))
                    .lineSpacing(16 * 0.5)
                    .foregroundStyle(self.session.intention.isEmpty ? AF.neutral(600) : AF.text)
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Music

    private var musicSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            KickerLabel("Music")
            TokenCard(padding: 12) {
                if self.session.hasMusicLink {
                    MusicLinkDetailCard(
                        title: self.session.musicLinkTitle ?? "Playlist link",
                        provider: self.session.musicLinkProvider,
                        author: self.session.musicLinkAuthorName,
                        durationSeconds: self.session.musicLinkDurationSeconds,
                        artworkURL: self.session.musicLinkArtworkURL.flatMap(URL.init(string:)),
                        openAction: self.openMusicLink
                    )
                } else {
                    Button {
                        self.showingEdit = true
                    } label: {
                        Label("Attach music link", systemImage: "link.badge.plus")
                            .font(.afterflowBody(14, weight: .semibold))
                            .foregroundStyle(AF.accent(700))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("attachMusicLinkFromDetail")
                    .accessibilityHint("Opens the form to attach a music link to this session")
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Reflection

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                KickerLabel("Reflection")
                Spacer()
                Button {
                    if let onAddReflection {
                        onAddReflection()
                    } else {
                        self.showingEdit = true
                    }
                } label: {
                    Text("Add more")
                        .font(.afterflowBody(12, weight: .semibold))
                        .foregroundStyle(AF.accent(700))
                }
                .buttonStyle(AFLinkButtonStyle())
                .accessibilityIdentifier("addMoreReflectionButton")
                .accessibilityHint("Adds to this session's reflection")
            }
            TokenCard {
                if self.session.reflections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("You haven't added reflections yet.")
                        .font(.afterflowBody(15))
                        .foregroundStyle(AF.neutral(600))
                } else {
                    Text(MarkdownRenderer.render(self.session.reflections))
                        .font(.afterflowBody(15))
                        .lineSpacing(15 * 0.6)
                        .foregroundStyle(AF.neutral(800))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Mood card (as drawn: circles + rising dotted arc)

struct MoodJourneyCard: View {
    let session: TherapeuticSession

    var body: some View {
        VStack(alignment: .leading, spacing: DesignConstants.Spacing.medium) {
            HStack {
                KickerLabel("Mood")
                Spacer()
                Text(self.deltaText)
                    .font(.afterflowBody(13, weight: .semibold))
                    .foregroundStyle(AF.accent(700))
            }

            HStack(alignment: .center, spacing: DesignConstants.Spacing.medium) {
                VStack(spacing: 4) {
                    Text("\(self.session.moodBefore)")
                        .font(.afterflowBody(16, weight: .semibold))
                        .foregroundStyle(AF.neutral(800))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(AF.neutral(200)))
                    Text("before")
                        .font(.afterflowBody(11))
                        .foregroundStyle(AF.neutral(600))
                }

                if let moodAfter = self.session.moodAfter {
                    RisingArc()
                        .stroke(
                            AF.accent(400),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 5])
                        )
                        .frame(height: 34)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)

                    VStack(spacing: 4) {
                        Text("\(moodAfter)")
                            .font(.afterflowBody(20, weight: .bold))
                            .foregroundStyle(AF.accent(800))
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(AF.accent(200)))
                        Text(MoodRatingScale.descriptor(for: moodAfter).lowercased())
                            .font(.afterflowBody(11))
                            .foregroundStyle(AF.neutral(600))
                    }
                } else {
                    Text("after not added yet")
                        .font(.afterflowBody(13))
                        .foregroundStyle(AF.neutral(600))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)

                StatusTag(status: self.session.status)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                .fill(AF.neutral(100))
        )
        .afShadow(.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.accessibilitySummary)
    }

    private var deltaText: String {
        guard self.session.hasAfterMood else { return "" }
        let change = self.session.moodChange
        if change == 0 { return "no shift" }
        let sign = change > 0 ? "+" : "−"
        return "\(sign)\(abs(change)) shift"
    }

    private var accessibilitySummary: String {
        if let moodAfter = self.session.moodAfter {
            let before = MoodRatingScale.descriptor(for: self.session.moodBefore)
            let after = MoodRatingScale.descriptor(for: moodAfter)
            return "Mood before \(self.session.moodBefore), \(before). "
                + "Mood after \(moodAfter), \(after)."
        }
        return "Mood before \(self.session.moodBefore). After mood not added yet."
    }
}

/// Gently rising dotted curve between the before and after mood circles.
private struct RisingArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX + rect.width * 0.15, y: rect.maxY)
        )
        return path
    }
}

// MARK: - Music card

private struct MusicLinkDetailCard: View {
    let title: String
    let provider: MusicLinkProvider
    let author: String?
    let durationSeconds: Int?
    let artworkURL: URL?
    let openAction: () -> Void

    var body: some View {
        Button(action: self.openAction) {
            HStack(spacing: DesignConstants.Spacing.medium) {
                self.artworkView

                VStack(alignment: .leading, spacing: 3) {
                    Text(self.title)
                        .font(.afterflowBody(15, weight: .semibold))
                        .foregroundStyle(AF.text)
                        .lineLimit(2)

                    // Separate Texts so each meta piece stays its own accessibility element.
                    HStack(spacing: 4) {
                        Text(self.provider.displayName)
                        if let author, !author.isEmpty {
                            Text("·")
                            Text(author)
                        }
                        if let durationText {
                            Text("·")
                            Text(durationText)
                        }
                    }
                    .font(.afterflowBody(12))
                    .foregroundStyle(AF.neutral(600))
                    .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AF.neutral(600))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("musicLinkDetailCard")
        .accessibilityHint("Opens the music link in your browser or music app")
    }

    private var durationText: String? {
        guard let seconds = self.durationSeconds, seconds > 0 else { return nil }
        let minutes = seconds / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainder = minutes % 60
            return remainder == 0 ? "\(hours) hr" : "\(hours) hr \(remainder) min"
        }
        return "\(minutes) min"
    }

    @ViewBuilder
    private var artworkView: some View {
        if let artworkURL {
            AsyncImage(url: artworkURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ZStack {
                        AF.neutral(200)
                        ProgressView()
                    }
                case .failure:
                    self.fallbackArtwork
                @unknown default:
                    self.fallbackArtwork
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.large))
        } else {
            self.fallbackArtwork
        }
    }

    private var fallbackArtwork: some View {
        if let brand = brandImage(for: self.provider) {
            return AnyView(
                brand
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.large))
            )
        }

        return AnyView(
            ZStack {
                AF.neutral(200)
                Image(systemName: "music.note.list")
                    .imageScale(.medium)
                    .foregroundStyle(AF.neutral(600))
            }
            .frame(width: 54, height: 54)
            .clipShape(RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.large))
        )
    }
}

private func brandImage(for provider: MusicLinkProvider) -> Image? {
    let baseName: String
    switch provider {
    case .spotify: baseName = "spotify"
    case .youtube: baseName = "youtube"
    case .soundcloud: baseName = "soundcloud"
    case .appleMusic: baseName = "appleMusic"
    case .applePodcasts: baseName = "applePodcasts"
    case .bandcamp: baseName = "bandcamp"
    case .tidal: baseName = "tidal"
    default: return nil
    }

    for candidate in ["Brands/\(baseName)", baseName] {
        if let uiImage = UIImage(named: candidate) {
            return Image(uiImage: uiImage)
        }
    }
    return nil
}

// MARK: - Behavior

extension SessionDetailView {
    private func openMusicLink() {
        var seen = Set<String>()
        let candidates = [self.session.musicLinkURL, self.session.musicLinkWebURL]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }

        for candidate in candidates {
            guard let url = URL(string: candidate) else { continue }
            self.openURL(url)
            return
        }

        if seen.isEmpty {
            self.linkErrorMessage = "Playlist link is missing."
        } else {
            self.linkErrorMessage = "Unable to open playlist link."
        }
    }

    private func hydrateMusicMetadataIfNeeded() async {
        guard self.session.hasMusicLink else { return }
        let hasMetadata = !(self.session.musicLinkTitle?.isEmpty ?? true)
            || self.session.musicLinkAuthorName != nil
            || self.session.musicLinkArtworkURL != nil
            || self.session.musicLinkDurationSeconds != nil
        guard !hasMetadata else { return }
        guard let link = self.session.musicLinkWebURL ?? self.session.musicLinkURL else { return }

        await MainActor.run { self.isHydratingMusicLink = true }
        defer { Task { @MainActor in self.isHydratingMusicLink = false } }

        do {
            let metadata = try await self.metadataService.fetchMetadata(for: link)
            await MainActor.run {
                self.session.musicLinkURL = metadata.originalURL.absoluteString
                self.session.musicLinkWebURL = metadata.canonicalURL.absoluteString
                self.session.musicLinkTitle = metadata.title
                self.session.musicLinkAuthorName = metadata.authorName
                self.session.musicLinkArtworkURL = metadata.thumbnailURL?.absoluteString
                self.session.musicLinkDurationSeconds = metadata.durationSeconds
                self.session.musicLinkProvider = metadata.provider

                do {
                    try self.sessionStore.update(self.session)
                } catch {
                    self.updateError = "Failed to save music metadata: \(error.localizedDescription)"
                }
            }
        } catch {}
    }
}

#Preview {
    let container: ModelContainer = {
        do {
            return try ModelContainer(
                for: TherapeuticSession.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
    let store = SessionStore(modelContext: container.mainContext, owningContainer: container)
    let session = TherapeuticSession(intention: "Feel more open with my partner", moodBefore: 4, moodAfter: 7)

    try? store.create(session)
    return NavigationStack {
        SessionDetailView(session: session)
    }
    .modelContainer(container)
    .environment(store)
}

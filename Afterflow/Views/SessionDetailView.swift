// swiftlint:disable file_length
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

    private let metadataService = MusicLinkMetadataService()

    @State private var showingEdit = false
    @State private var linkErrorMessage: String?
    @State private var isHydratingMusicLink = false

    var body: some View {
        List {
            SessionSummarySection(session: self.session, dateFormatter: self.dateFormatter)

            SessionMetadataSection(session: self.session, dateFormatter: self.dateFormatter)

            SessionTreatmentSection(session: self.session)

            SessionIntentionSection(intention: self.session.intention)

            SessionMoodSection(session: self.session)

            SessionMusicSection(
                session: self.session,
                onAttachMusic: { self.showingEdit = true },
                onOpenLink: openMusicLink
            )

            SessionReflectionSection(reflections: self.session.reflections)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    TreatmentAvatar(type: self.session.treatmentType)
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .accessibilityHidden(true)
                    Text("Session")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .accessibilityLabel("Session: \(self.session.treatmentType.displayName)")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Edit") {
                    self.showingEdit = true
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: self.$showingEdit) {
            NavigationStack {
                SessionFormView(session: self.session)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(16)
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
        .task {
            await self.hydrateMusicMetadataIfNeeded()
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

private struct SessionDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(self.title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(self.value)
                .multilineTextAlignment(.trailing)
        }
        .font(.body)
    }
}

private extension SessionLifecycleStatus {
    var symbolName: String {
        switch self {
        case .draft: "square.dashed"
        case .needsReflection: "hourglass"
        case .complete: "checkmark.seal.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .draft: .blue
        case .needsReflection: .orange
        case .complete: .green
        }
    }
}

private struct StatusPill: View {
    let status: SessionLifecycleStatus

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: self.status.symbolName)
            Text(self.labelText)
        }
        .font(.footnote)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(self.status.accentColor.opacity(0.15))
        .foregroundStyle(self.status.accentColor)
        .clipShape(Capsule())
    }

    private var labelText: String {
        switch self.status {
        case .needsReflection: "Reflect"
        default: self.status.displayName
        }
    }
}

private struct MoodDeltaPill: View {
    let before: Int
    let after: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: self.iconName)
            Text("Mood \(self.before) → \(self.after)")
        }
        .font(.footnote)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(self.tintColor.opacity(0.15))
        .foregroundStyle(self.tintColor)
        .clipShape(Capsule())
    }

    private var iconName: String {
        self.after >= self.before ? "arrow.up.right" : "arrow.down"
    }

    private var tintColor: Color {
        self.after >= self.before ? .blue : Color.purple.opacity(0.9)
    }
}

private struct MoodBeforePill: View {
    let value: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "face.smiling")
            Text("Mood \(self.value)")
        }
        .font(.footnote)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.teal.opacity(0.15))
        .foregroundStyle(Color.teal)
        .clipShape(Capsule())
    }
}

private struct ReminderPill: View {
    let text: String

    var body: some View {
        let tint = Color(.systemRed)
        return HStack(spacing: 3) {
            Image(systemName: "bell")
            Text(self.text)
        }
        .font(.footnote)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.15))
        .foregroundStyle(tint)
        .clipShape(Capsule())
    }
}

private struct MusicLinkDetailCard: View {
    let title: String
    let provider: MusicLinkProvider
    let author: String?
    let urlDisplay: String
    let artworkURL: URL?
    let openAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: self.openAction) {
                HStack(spacing: 12) {
                    self.artworkView

                    VStack(alignment: .leading, spacing: 4) {
                        Text(self.title)
                            .font(.body)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text(self.providerText)
                            if let author, !author.isEmpty {
                                Text("•")
                                Text(author)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                        if !self.urlDisplay.isEmpty {
                            Text(self.urlDisplay)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.right.square")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("musicLinkDetailCard")
    }

    private var providerText: String {
        self.provider.displayName
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
                        Color.gray.opacity(0.15)
                        ProgressView()
                    }
                case .failure:
                    self.fallbackArtwork
                @unknown default:
                    self.fallbackArtwork
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            )
        }

        return AnyView(
            ZStack {
                Color.gray.opacity(0.12)
                Image(systemName: "music.note.list")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        )
    }
}

private struct SessionSummarySection: View {
    let session: TherapeuticSession
    let dateFormatter: DateFormatter

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(self.session.treatmentType.displayName)
                            .font(.headline)
                        Text(self.dateFormatter.string(from: self.session.sessionDate))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if self.session.hasMusicLink {
                        self.summaryBadge
                            .accessibilityLabel("Music attached")
                    }
                }

                HStack(spacing: 8) {
                    StatusPill(status: self.session.status)
                    if self.hasAfterMood {
                        MoodDeltaPill(before: self.session.moodBefore, after: self.session.moodAfter)
                    } else {
                        MoodBeforePill(value: self.session.moodBefore)
                    }
                }
                .padding(.top, 2)

                if self.session.status == .needsReflection,
                   let reminderLabel = session.reminderRelativeDescription {
                    ReminderPill(text: reminderLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 2)
                        .accessibilityIdentifier("detailReminderLabel")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .accessibilityElement(children: .contain)
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 2, leading: 0, bottom: 0, trailing: 0))
    }

    private var hasAfterMood: Bool {
        let reflectionSet = !self.session.reflections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return reflectionSet || self.session.moodAfter != 5
    }

    private var summaryBadge: some View {
        if let brand = brandImage(for: session.musicLinkProvider) {
            return AnyView(
                brand
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            )
        }
        return AnyView(
            Image(systemName: "music.note.list")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        )
    }
}

private struct SessionMetadataSection: View {
    let session: TherapeuticSession
    let dateFormatter: DateFormatter

    var body: some View {
        Section("When") {
            SessionDetailRow(title: "Date & Time", value: self.dateFormatter.string(from: self.session.sessionDate))
        }
        .accessibilityElement(children: .contain)
    }
}

private struct SessionTreatmentSection: View {
    let session: TherapeuticSession

    var body: some View {
        Section("Treatment") {
            SessionDetailRow(title: "Type", value: self.session.treatmentType.displayName)
            SessionDetailRow(title: "Administration", value: self.session.administration.displayName)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct SessionIntentionSection: View {
    let intention: String

    var body: some View {
        Section("Intention") {
            Text(self.intention.isEmpty ? "No intention captured." : self.intention)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct SessionMoodSection: View {
    let session: TherapeuticSession

    var body: some View {
        Section("Mood") {
            self.moodRow(title: "Before", value: self.session.moodBefore)
            if self.hasAfterMood {
                self.moodRow(title: "After", value: self.session.moodAfter)
            } else {
                SessionDetailRow(title: "After", value: "Not added yet")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var hasAfterMood: Bool {
        let reflectionSet = !self.session.reflections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return reflectionSet || self.session.moodAfter != 5
    }

    private func moodRow(title: String, value: Int) -> some View {
        let descriptor = MoodRatingScale.descriptor(for: value)
        let emoji = MoodRatingScale.emoji(for: value)
        return SessionDetailRow(title: title, value: "\(value) (\(descriptor)) \(emoji)")
    }
}

private struct SessionMusicSection: View {
    let session: TherapeuticSession
    let onAttachMusic: () -> Void
    let onOpenLink: () -> Void

    var body: some View {
        Section("Music") {
            if self.session.hasMusicLink {
                MusicLinkDetailCard(
                    title: self.session.musicLinkTitle ?? "Playlist link",
                    provider: self.session.musicLinkProvider,
                    author: self.session.musicLinkAuthorName,
                    urlDisplay: self.session.musicLinkWebURL ?? self.session.musicLinkURL ?? "",
                    artworkURL: self.session.musicLinkArtworkURL.flatMap(URL.init(string:)),
                    openAction: self.onOpenLink
                )
                .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
            } else {
                Button {
                    self.onAttachMusic()
                } label: {
                    Label("Attach music link", systemImage: "link.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("attachMusicLinkFromDetail")
                .padding(.vertical, 2)
                .listRowInsets(.init(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct SessionReflectionSection: View {
    let reflections: String

    var body: some View {
        Section("Reflection") {
            if self.reflections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("You haven't added reflections yet.")
                    .foregroundStyle(.secondary)
            } else {
                Text(MarkdownRenderer.render(self.reflections))
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .accessibilityElement(children: .contain)
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

private extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

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
                try? self.sessionStore.update(self.session)
            }
        } catch {
            // Silent failure; UI continues with existing data.
        }
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

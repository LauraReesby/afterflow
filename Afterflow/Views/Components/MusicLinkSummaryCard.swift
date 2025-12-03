import SwiftUI

struct MusicLinkSummaryCard: View {
    let session: TherapeuticSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(self.session.musicLinkTitle ?? "Playlist link")
                .font(.headline)
            if let providerRaw = session.musicLinkProviderRawValue,
               let provider = MusicLinkProvider(rawValue: providerRaw) {
                Text(provider.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let duration = session.musicLinkDurationSeconds,
               duration > 0 {
                Text(Self.formattedDuration(seconds: duration))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if let urlString = session.musicLinkWebURL ?? session.musicLinkURL,
                      let url = URL(string: urlString) {
                Text(url.absoluteString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private static func formattedDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            if minutes > 0 {
                return "\(hours) hr \(minutes) min"
            }
            return "\(hours) hr"
        }
        if minutes > 0 {
            return "\(minutes) min"
        }
        return "Under 1 min"
    }
}

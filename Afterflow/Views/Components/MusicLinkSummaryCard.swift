import SwiftUI

struct MusicLinkSummaryCard: View {
    let session: TherapeuticSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(self.session.musicLinkTitle ?? "Playlist link")
                .font(.headline)
            if let provider = session.musicLinkProviderRawValue {
                Text(provider.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let urlString = session.musicLinkWebURL ?? session.musicLinkURL,
               let url = URL(string: urlString)
            {
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
}

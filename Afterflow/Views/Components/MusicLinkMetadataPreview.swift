import SwiftUI

struct MusicLinkMetadataPreview: View {
    let metadata: MusicLinkMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(self.metadata.title ?? "Playlist link")
                .font(.headline)
            Text(self.metadata.provider.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(self.metadata.canonicalURL.absoluteString)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AF.neutral(200))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("musicLinkPreview")
    }
}

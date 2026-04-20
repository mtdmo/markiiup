import AppKit
import SwiftUI

private enum MarkiiupBrandResources {
    static let catImage: NSImage? = {
        guard let url = Bundle.main.url(forResource: "markiiup_cat", withExtension: "png") else {
            return nil
        }

        return NSImage(contentsOf: url)
    }()
}

struct MarkiiupBrandIcon: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.white)

            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)

            if let image = MarkiiupBrandResources.catImage {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .padding(size * 0.16)
            } else {
                Image(systemName: "doc.text")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.accentColor)
                    .padding(size * 0.24)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
    }
}

struct MarkiiupBrandHeaderView: View {
    var body: some View {
        HStack(spacing: 12) {
            MarkiiupBrandIcon(size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("markiiup")
                    .font(.title3.weight(.semibold))

                Text("Desktop Markdown workspace")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

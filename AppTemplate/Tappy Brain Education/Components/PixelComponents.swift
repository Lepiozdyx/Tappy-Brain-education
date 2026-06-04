import SwiftUI
import UIKit
import AudioToolbox

enum TappyColors {
    static let skyTop = Color(red: 0.44, green: 0.82, blue: 0.86)
    static let skyBottom = Color(red: 0.62, green: 0.88, blue: 0.91)
    static let grass = Color(red: 0.44, green: 0.76, blue: 0.18)
    static let yellow = Color(red: 1.00, green: 0.82, blue: 0.00)
    static let orange = Color(red: 1.00, green: 0.70, blue: 0.28)
    static let red = Color(red: 1.00, green: 0.29, blue: 0.31)
    static let green = Color(red: 0.45, green: 0.75, blue: 0.18)
    static let grey = Color(red: 0.62, green: 0.66, blue: 0.72)
    static let ink = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let paper = Color(uiColor: .systemBackground)
    static let muted = Color(red: 0.39, green: 0.43, blue: 0.50)
}

extension Font {
    static func pixel(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("PixelifySans-Regular", size: size).weight(weight)
    }
}

struct PixelCard<Content: View>: View {
    var borderColor: Color = TappyColors.ink
    var shadowColor: Color = TappyColors.ink.opacity(0.9)
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(TappyColors.paper)
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: 4)
            )
            .offset(x: -4, y: -4)
            .background(shadowColor.offset(x: 4, y: 4))
    }
}

struct PixelButton: View {
    let title: String
    var systemImage: String?
    var color: Color = TappyColors.yellow
    var foreground: Color = TappyColors.ink
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                }
                Text(title)
                    .font(.pixel(22, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity)
            .minHeight(58)
            .foregroundStyle(foreground)
            .background(disabled ? TappyColors.grey.opacity(0.35) : color)
            .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
            .background(TappyColors.ink.offset(x: 5, y: 6))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(title)
    }
}

struct PixelIconTile: View {
    let color: Color
    let systemName: String
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            color
            Image(systemName: systemName)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(TappyColors.ink)
        }
        .frame(width: size, height: size)
        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
        .accessibilityHidden(true)
    }
}

enum SafeAssetScaleMode {
    case cover
    case contain
    case fill
}

struct SafeAssetImage: View {
    let name: String
    var mode: SafeAssetScaleMode = .contain

    private var hasImage: Bool {
        UIImage(named: name) != nil
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if hasImage {
                    imageView
                } else {
                    fallback(size: proxy.size)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }

    @ViewBuilder
    private var imageView: some View {
        switch mode {
        case .cover:
            Image(name)
                .resizable()
                .scaledToFill()
        case .contain:
            Image(name)
                .resizable()
                .scaledToFit()
        case .fill:
            Image(name)
                .resizable()
        }
    }

    private func fallback(size: CGSize) -> some View {
        ZStack {
            Rectangle()
                .fill(Color(uiColor: .secondarySystemBackground))
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
                .foregroundStyle(TappyColors.muted)
            Text(name)
                .font(.pixel(max(10, min(14, size.width / 10))))
                .foregroundStyle(TappyColors.muted)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.45)
                .padding(8)
        }
        .accessibilityLabel("Missing asset \(name)")
    }
}

struct AvatarView: View {
    let avatar: AvatarKind
    var size: CGFloat = 58
    var showsTile = true

    var body: some View {
        ZStack {
            if let assetName = avatar.assetName {
                SafeAssetImage(name: assetName, mode: .contain)
            } else {
                Text(avatar.emoji)
                    .font(.system(size: size * 0.48))
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(width: size, height: size)
        .background(showsTile ? TappyColors.orange : Color.clear)
        .overlay {
            if showsTile {
                Rectangle().stroke(TappyColors.ink, lineWidth: 4)
            }
        }
        .accessibilityLabel(avatar.title)
    }
}

struct HeaderBar: View {
    let title: String
    var subtitle: String?
    var showBack = false
    var onBack: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    var body: some View {
        HStack(spacing: 12) {
            if showBack {
                Button(action: {
                    if let onBack {
                        onBack()
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 22, weight: .bold))
                        .frame(width: 52, height: 52)
                        .background(Color(uiColor: .systemBackground))
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.pixel(28, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
                if let subtitle {
                    Text(subtitle)
                        .font(.pixel(12))
                        .foregroundStyle(TappyColors.muted)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(Color(uiColor: .systemBackground))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TappyColors.ink)
                .frame(height: 4)
        }
    }
}

struct RootBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [TappyColors.skyTop, TappyColors.skyBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func tappyBackground() -> some View {
        modifier(RootBackground())
    }

    func minHeight(_ height: CGFloat) -> some View {
        frame(minHeight: height)
    }
}

struct PipeView: View {
    var label: String
    var status: DayStatus = .pending

    private var pipeColor: Color {
        switch status {
        case .failed: TappyColors.red
        case .completed, .pending: TappyColors.green
        case .rest, .future: TappyColors.grey
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(pipeColor)
                    .frame(width: 110, height: 34)
                    .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
                Rectangle()
                    .fill(pipeColor)
                    .frame(width: 76, height: 150)
                    .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
            }

            Text(label)
                .font(.pixel(13, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 8)
                .frame(width: 150, height: 28)
                .background(TappyColors.paper)
                .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Course pipe, \(label)")
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

enum SoundPlayer {
    static func tap(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    static func success(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1025)
    }

    static func fail(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(1053)
    }
}

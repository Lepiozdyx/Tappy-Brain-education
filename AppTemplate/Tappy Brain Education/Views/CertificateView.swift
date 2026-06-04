import SwiftUI

struct CertificateView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let course: Course
    @State private var showShare = false

    var body: some View {
        ZStack {
            TappyColors.ink.opacity(0.65)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    certificate
                    HStack(spacing: 16) {
                        PixelButton(title: "SHARE", systemImage: "square.and.arrow.up", color: TappyColors.green, foreground: .white) {
                            showShare = true
                        }
                        PixelButton(title: "CLOSE", color: TappyColors.paper) {
                            dismiss()
                        }
                    }
                }
                .padding(26)
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: [store.shareText(for: course)])
        }
    }

    private var certificate: some View {
        VStack(spacing: 18) {
            Text(course.avatar.emoji)
                .font(.system(size: 68))
                .accessibilityHidden(true)
            Text("CERTIFICATE\nOF\nCOMPLETION")
                .font(.pixel(31, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.55)

            Rectangle()
                .fill(accent)
                .frame(height: 8)
                .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 2))

            Text("This certifies that")
                .font(.pixel(16))
            Text("LEARNER")
                .font(.pixel(32, weight: .bold))
                .foregroundStyle(TappyColors.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text("has successfully\ncompleted")
                .font(.pixel(16))
                .multilineTextAlignment(.center)

            Text(course.name)
                .font(.pixel(29, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.48)

            Text("Completed on \(course.completedAt.map { DateFormatter.shortDate.string(from: $0) } ?? DateFormatter.shortDate.string(from: Date()))")
                .font(.pixel(13))

            Text("TOTAL XP:\n\(course.xp)")
                .font(.pixel(24, weight: .bold))
                .foregroundStyle(TappyColors.yellow)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(TappyColors.paper)
        .overlay(Rectangle().stroke(accent, lineWidth: 6))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Certificate of completion for \(course.name)")
    }

    private var accent: Color {
        switch course.avatar {
        case .guitar: TappyColors.orange
        case .books: TappyColors.red
        default: Color(red: 0.28, green: 0.56, blue: 0.75)
        }
    }
}

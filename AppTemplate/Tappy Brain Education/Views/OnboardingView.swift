import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(icon: "bird", color: TappyColors.yellow, title: "Every Lesson Is A Wing Flap", text: "Turn your learning journey into an arcade survival challenge."),
        OnboardingSlide(icon: "bolt.fill", color: TappyColors.red, title: "Miss A Day = Lose Your Streak", text: "Stay consistent and keep your XP alive."),
        OnboardingSlide(icon: "arrow.up.right", color: TappyColors.green, title: "Watch Your Knowledge Grow", text: "Earn achievements, complete courses, and beat your best score."),
        OnboardingSlide(icon: "book.fill", color: TappyColors.orange, title: "TAP TO BEGIN", text: "Your learning streak starts today.")
    ]

    var body: some View {
        VStack(spacing: 26) {
            TabView(selection: $page) {
                ForEach(slides.indices, id: \.self) { index in
                    OnboardingSlideView(slide: slides[index])
                        .tag(index)
                        .padding(.horizontal, 28)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 18) {
                PixelButton(title: page == slides.count - 1 ? "PLAY NOW" : "START", color: TappyColors.yellow) {
                    if page == slides.count - 1 {
                        onFinish()
                    } else {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            page += 1
                        }
                    }
                }

                Button(action: onFinish) {
                    Text("SKIP")
                        .font(.pixel(18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Skip onboarding")

                HStack(spacing: 10) {
                    ForEach(slides.indices, id: \.self) { index in
                        Rectangle()
                            .fill(index == page ? TappyColors.yellow : Color(uiColor: .systemBackground))
                            .frame(width: 14, height: 14)
                            .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 34)
        }
        .tappyBackground()
    }
}

private struct OnboardingSlide: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let text: String
}

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide

    var body: some View {
        VStack(spacing: 36) {
            Spacer()

            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: 96, height: 64)
                    .offset(x: -82, y: -38)

                ZStack {
                    slide.color
                    Image(systemName: slide.icon)
                        .font(.system(size: 70, weight: .black))
                        .foregroundStyle(TappyColors.ink)
                }
                .frame(width: 154, height: 154)
                .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 6))
                .background(TappyColors.ink.offset(x: 8, y: 8))

                Rectangle()
                    .fill(TappyColors.green)
                    .frame(width: 64, height: 64)
                    .offset(x: 38, y: -22)
            }

            Text(slide.title)
                .font(.pixel(34, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.52)
                .fixedSize(horizontal: false, vertical: true)

            Text(slide.text)
                .font(.pixel(17))
                .foregroundStyle(TappyColors.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

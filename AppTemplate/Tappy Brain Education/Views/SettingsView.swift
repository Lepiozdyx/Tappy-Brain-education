import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [AppRoute]
    @State private var settings = AppSettings()

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(title: "SETTINGS", showBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(spacing: 24) {
                    toggleCard(title: "AUDIO", subtitle: "Sound effects and music", icon: "speaker.wave.2", color: TappyColors.orange, isOn: $settings.audioEnabled)
                    toggleCard(title: "NOTIFICATIONS", subtitle: "Daily reminders visual only", icon: "bell", color: TappyColors.yellow, isOn: $settings.notificationsEnabled)
                    reminderCard
                    exportCard
                    aboutCard
                }
                .padding(24)
            }
        }
        .tappyBackground()
        .onAppear {
            settings = store.state.settings
        }
        .onChange(of: settings) { _, newValue in
            store.updateSettings(newValue)
        }
    }

    private func toggleCard(title: String, subtitle: String, icon: String, color: Color, isOn: Binding<Bool>) -> some View {
        PixelCard {
            HStack(spacing: 16) {
                PixelIconTile(color: color, systemName: icon)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.pixel(20, weight: .bold))
                    Text(subtitle)
                        .font(.pixel(13))
                        .foregroundStyle(TappyColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                PixelToggle(title: title, isOn: isOn)
            }
        }
    }

    private var reminderCard: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    PixelIconTile(color: TappyColors.green, systemName: "clock")
                    VStack(alignment: .leading, spacing: 5) {
                        Text("REMINDER TIME")
                            .font(.pixel(20, weight: .bold))
                        Text("When to show daily reminder time")
                            .font(.pixel(13))
                            .foregroundStyle(TappyColors.muted)
                    }
                }

                PixelTimeControl(
                    hour: $settings.reminderHour,
                    minute: $settings.reminderMinute
                )
            }
        }
    }

    private var exportCard: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    PixelIconTile(color: TappyColors.yellow, systemName: "square.and.arrow.up")
                    VStack(alignment: .leading, spacing: 5) {
                        Text("EXPORT CERTIFICATE")
                            .font(.pixel(20, weight: .bold))
                        Text("Share your achievements")
                            .font(.pixel(13))
                            .foregroundStyle(TappyColors.muted)
                    }
                }
                PixelButton(title: "VIEW DIPLOMAS", color: TappyColors.green, foreground: .white) {
                    dismiss()
                }
            }
        }
    }

    private var aboutCard: some View {
        PixelCard {
            VStack(spacing: 14) {
                SafeAssetImage(name: "app_logo", mode: .contain)
                    .frame(width: 86, height: 86)
                Text("TAPPY BRAIN")
                    .font(.pixel(28, weight: .bold))
                    .foregroundStyle(TappyColors.yellow)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Text("Version 1.0.0")
                    .font(.pixel(13))
                    .foregroundStyle(TappyColors.muted)
                Text("Turn learning into an arcade adventure")
                    .font(.pixel(14))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct PixelToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(isOn ? TappyColors.green : Color(uiColor: .systemBackground))
                    .overlay {
                        Text(isOn ? "ON" : "")
                            .font(.pixel(13, weight: .bold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                    }
                Rectangle()
                    .fill(isOn ? Color(uiColor: .systemBackground) : TappyColors.red)
                    .overlay {
                        Text(isOn ? "" : "OFF")
                            .font(.pixel(11, weight: .bold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                    }
            }
            .frame(width: 76, height: 40)
            .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
            .background(TappyColors.ink.offset(x: 3, y: 4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

private struct PixelTimeControl: View {
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                timeStepper(title: "HOUR", value: formattedHour, increment: incrementHour, decrement: decrementHour)
                timeStepper(title: "MIN", value: formattedMinute, increment: incrementMinute, decrement: decrementMinute)
            }

            Text(displayTime)
                .font(.pixel(24, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color(uiColor: .secondarySystemBackground))
                .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
                .accessibilityLabel("Reminder time \(displayTime)")
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground))
        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
    }

    private func timeStepper(title: String, value: String, increment: @escaping () -> Void, decrement: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.pixel(12, weight: .bold))
                .foregroundStyle(TappyColors.muted)

            HStack(spacing: 8) {
                Button(action: decrement) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 38, height: 38)
                        .background(TappyColors.yellow)
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Decrease \(title.lowercased())")

                Text(value)
                    .font(.pixel(20, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))

                Button(action: increment) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 38, height: 38)
                        .background(TappyColors.green)
                        .foregroundStyle(.white)
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Increase \(title.lowercased())")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var formattedHour: String {
        String(format: "%02d", normalizedHour)
    }

    private var formattedMinute: String {
        String(format: "%02d", normalizedMinute)
    }

    private var displayTime: String {
        let hour12 = normalizedHour % 12 == 0 ? 12 : normalizedHour % 12
        let suffix = normalizedHour < 12 ? "AM" : "PM"
        return String(format: "%02d:%02d %@", hour12, normalizedMinute, suffix)
    }

    private var normalizedHour: Int {
        ((hour % 24) + 24) % 24
    }

    private var normalizedMinute: Int {
        ((minute % 60) + 60) % 60
    }

    private func incrementHour() {
        hour = (normalizedHour + 1) % 24
    }

    private func decrementHour() {
        hour = (normalizedHour + 23) % 24
    }

    private func incrementMinute() {
        minute = (normalizedMinute + 5) % 60
    }

    private func decrementMinute() {
        minute = (normalizedMinute + 55) % 60
    }
}

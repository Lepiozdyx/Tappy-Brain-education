import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(title: "NOTIFICATIONS", subtitle: "\(unreadCount) unread messages", showBack: true, onBack: { dismiss() })

            if store.state.notices.isEmpty {
                VStack {
                    Spacer()
                    PixelCard {
                        VStack(spacing: 14) {
                            PixelIconTile(color: TappyColors.green, systemName: "bell", size: 78)
                            Text("NO MESSAGES")
                                .font(.pixel(24, weight: .bold))
                            Text("Streak alerts and achievements will land here.")
                                .font(.pixel(14))
                                .foregroundStyle(TappyColors.muted)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(28)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 22) {
                        ForEach(store.state.notices) { notice in
                            NoticeCard(notice: notice)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .tappyBackground()
    }

    private var unreadCount: Int {
        store.state.notices.filter { !$0.isRead }.count
    }
}

private struct NoticeCard: View {
    @EnvironmentObject private var store: AppStore
    let notice: Notice

    var body: some View {
        PixelCard(borderColor: borderColor) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    PixelIconTile(color: iconColor, systemName: iconName, size: 62)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text(notice.title)
                                .font(.pixel(20, weight: .bold))
                                .lineLimit(3)
                                .minimumScaleFactor(0.5)
                            Spacer()
                            if !notice.isRead {
                                Rectangle()
                                    .fill(TappyColors.red)
                                    .frame(width: 12, height: 12)
                                    .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 2))
                            }
                        }

                        Text(notice.message)
                            .font(.pixel(14))
                            .foregroundStyle(TappyColors.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(relativeTime)
                            .font(.pixel(12))
                            .foregroundStyle(TappyColors.grey)
                    }
                }

                Rectangle()
                    .fill(Color(uiColor: .separator))
                    .frame(height: 2)

                HStack(spacing: 12) {
                    if !notice.isRead {
                        PixelButton(title: "MARK READ", systemImage: "checkmark", color: TappyColors.green, foreground: .white) {
                            store.markNoticeRead(notice)
                        }
                    }
                    PixelButton(title: "DELETE", systemImage: "trash", color: TappyColors.paper) {
                        store.deleteNotice(notice)
                    }
                }
            }
        }
    }

    private var iconName: String {
        switch notice.type {
        case .streak: "flame"
        case .achievement: "trophy"
        case .reminder: "book"
        case .danger: "exclamationmark.circle"
        case .milestone: "star"
        }
    }

    private var iconColor: Color {
        switch notice.type {
        case .streak, .reminder: TappyColors.orange
        case .achievement, .milestone: TappyColors.yellow
        case .danger: TappyColors.red
        }
    }

    private var borderColor: Color {
        notice.isRead ? TappyColors.ink : iconColor
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: notice.createdAt, relativeTo: Date())
    }
}

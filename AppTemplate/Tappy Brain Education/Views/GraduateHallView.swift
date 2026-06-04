import SwiftUI

struct GraduateHallView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var path: [AppRoute]

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(title: "GRADUATE HALL")
            ScrollView {
                VStack(spacing: 24) {
                    metricsGrid
                    weeklyXPCard
                    achievementsCard
                    diplomaWall
                }
                .padding(24)
            }
        }
        .tappyBackground()
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)], spacing: 18) {
            MetricCard(icon: "trophy", color: TappyColors.yellow, value: "\(currentScore)", title: "CURRENT\nSCORE")
            MetricCard(icon: "trophy", color: TappyColors.green, value: "\(bestScore)", title: "BEST\nSCORE")
            MetricCard(icon: "clock", color: TappyColors.orange, value: "\(hoursInFlight)", title: "Hours In Flight")
            MetricCard(icon: "book", color: TappyColors.green, value: "\(store.state.courses.filter(\.isCompleted).count)", title: "Courses\nCleared")
            MetricCard(icon: "graduationcap", color: TappyColors.yellow, value: "\(lessonsDone)", title: "Lessons Done")
            MetricCard(icon: "bitcoinsign.circle", color: TappyColors.yellow, value: "\(store.state.coins)", title: "Coins Earned")
        }
    }

    private var weeklyXPCard: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("WEEKLY XP")
                    .font(.pixel(22, weight: .bold))
                WeeklyChart(values: weeklyXP)
                    .frame(height: 210)
            }
        }
    }

    private var achievementsCard: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("ACHIEVEMENTS")
                    .font(.pixel(22, weight: .bold))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    AchievementTile(icon: "🎓", title: "MAGISTER 8-BIT", unlocked: !store.diplomas().isEmpty)
                    AchievementTile(icon: "🔥", title: "7 DAY STREAK", unlocked: bestScore >= 7)
                    AchievementTile(icon: "⚡", title: "21 DAY STREAK", unlocked: bestScore >= 21)
                    AchievementTile(icon: "💎", title: "50 DAY STREAK", unlocked: bestScore >= 50)
                    AchievementTile(icon: "👑", title: "100 DAY STREAK", unlocked: bestScore >= 100)
                    AchievementTile(icon: "⏱", title: "SPEED LEARNER", unlocked: store.state.courses.contains { $0.isCompleted && $0.completedPipes <= max($0.finishLine, 1) })
                }
            }
        }
    }

    private var diplomaWall: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("DIPLOMA WALL")
                    .font(.pixel(22, weight: .bold))

                if store.diplomas().isEmpty {
                    VStack(spacing: 14) {
                        PixelIconTile(color: TappyColors.grey, systemName: "trophy", size: 76)
                        Text("NO DIPLOMAS YET")
                            .font(.pixel(20, weight: .bold))
                        Text("Clear a course to unlock a certificate.")
                            .font(.pixel(14))
                            .foregroundStyle(TappyColors.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                } else {
                    ForEach(store.diplomas()) { diploma in
                        Button {
                            path.append(.certificate(diploma.course.id))
                        } label: {
                            DiplomaCard(course: diploma.course)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open certificate for \(diploma.course.name)")
                    }
                }
            }
        }
    }

    private var currentScore: Int {
        store.state.courses.map(\.currentStreak).max() ?? 0
    }

    private var bestScore: Int {
        store.state.courses.map(\.bestStreak).max() ?? 0
    }

    private var hoursInFlight: Int {
        store.state.studyDays.reduce(0) { total, day in
            guard let course = store.state.courses.first(where: { $0.id == day.courseID }), course.goalType == .time, day.status == .completed else {
                return total
            }
            return total + max(course.dailyTarget, 0)
        } / 60
    }

    private var lessonsDone: Int {
        store.state.studyDays.filter { $0.status == .completed }.count
    }

    private var weeklyXP: [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            return store.state.studyDays
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.xpEarned }
        }
    }
}

private struct MetricCard: View {
    let icon: String
    let color: Color
    let value: String
    let title: String

    var body: some View {
        PixelCard(padding: 12) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 33, weight: .bold))
                    .foregroundStyle(color)
                Text(value)
                    .font(.pixel(27, weight: .bold))
                    .foregroundStyle(color == TappyColors.orange ? TappyColors.ink : color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                Text(title)
                    .font(.pixel(12))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 128)
        }
    }
}

private struct WeeklyChart: View {
    let values: [Int]
    private let labels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        GeometryReader { proxy in
            let maxValue = max(values.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 9) {
                ForEach(values.indices, id: \.self) { index in
                    VStack(spacing: 6) {
                        Rectangle()
                            .fill(index % 2 == 0 ? TappyColors.yellow : TappyColors.green)
                            .frame(height: max(8, CGFloat(values[index]) / CGFloat(maxValue) * (proxy.size.height - 32)))
                            .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
                        Text(labels[index])
                            .font(.pixel(11, weight: .bold))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .accessibilityLabel("Weekly XP chart")
    }
}

private struct AchievementTile: View {
    let icon: String
    let title: String
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 31))
            Text(title)
                .font(.pixel(10, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 104)
        .background(unlocked ? TappyColors.yellow : Color(uiColor: .secondarySystemBackground))
        .foregroundStyle(unlocked ? TappyColors.ink : TappyColors.grey)
        .overlay(Rectangle().stroke(unlocked ? TappyColors.ink : TappyColors.grey, lineWidth: 4))
        .accessibilityLabel("\(title), \(unlocked ? "unlocked" : "locked")")
    }
}

private struct DiplomaCard: View {
    let course: Course

    private var accent: Color {
        switch course.avatar {
        case .guitar: TappyColors.orange
        case .books: TappyColors.red
        default: Color(red: 0.28, green: 0.56, blue: 0.75)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(course.avatar.emoji)
                .font(.system(size: 48))
            Rectangle()
                .fill(accent)
                .frame(height: 6)
                .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 2))
            Text(course.name)
                .font(.pixel(20, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.55)
            Text(course.completedAt.map { DateFormatter.shortDate.string(from: $0) } ?? "In progress")
                .font(.pixel(12))
                .foregroundStyle(TappyColors.muted)
            Text("\(course.xp) XP")
                .font(.pixel(15, weight: .bold))
                .foregroundStyle(TappyColors.yellow)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(TappyColors.paper)
        .overlay(Rectangle().stroke(accent, lineWidth: 4))
    }
}

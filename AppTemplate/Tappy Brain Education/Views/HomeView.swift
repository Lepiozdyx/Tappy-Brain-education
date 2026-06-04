import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var path: [AppRoute]
    @State private var selectedCourseID: UUID?
    @State private var ticker = Date()

    private let flightTicker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var selectedCourse: Course? {
        if let selectedCourseID,
           let course = store.state.courses.first(where: { $0.id == selectedCourseID }) {
            return course
        }
        return store.state.courses.first
    }

    var body: some View {
        VStack(spacing: 0) {
            HomeHeader(path: $path)

            if store.state.courses.isEmpty {
                EmptyCoursesView {
                    path.append(.academy(nil))
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        courseCarousel

                        if let course = selectedCourse {
                            let flightState = store.flightState(for: course, now: ticker)
                            FlightSceneView(
                                course: course,
                                phase: flightState.phase,
                                timerRemaining: flightState.timerRemaining,
                                onStart: { start(course) },
                                onTap: { complete(course) }
                            )
                        }
                    }
                    .padding(24)
                }
                .scrollIndicators(.hidden)
            }
        }
        .tappyBackground()
        .onAppear {
            selectedCourseID = store.state.selectedCourseID ?? selectedCourseID ?? store.state.courses.first?.id
            if let selectedCourseID {
                store.selectCourse(selectedCourseID)
            }
            store.refreshActiveFlights()
        }
        .onReceive(flightTicker) { date in
            ticker = date
            if let course = selectedCourse {
                let flightState = store.flightState(for: course, now: date)
                if flightState.phase == .tapReady && course.flightPhase == .timerRunning {
                    store.refreshFlight(for: course.id)
                    SoundPlayer.success(enabled: store.state.settings.audioEnabled)
                }
            }
        }
    }

    private var courseCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YOUR COURSES")
                    .font(.pixel(22, weight: .bold))
                Spacer()
                Button {
                    path.append(.academy(nil))
                } label: {
                    Label("NEW", systemImage: "plus")
                        .font(.pixel(15, weight: .bold))
                        .padding(.horizontal, 14)
                        .frame(height: 42)
                        .background(TappyColors.yellow)
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 18) {
                    ForEach(store.state.courses) { course in
                        CourseCard(course: course, isSelected: selectedCourse?.id == course.id)
                            .onTapGesture {
                                selectedCourseID = course.id
                                store.selectCourse(course.id)
                            }
                            .contextMenu {
                                Button("Edit") {
                                    path.append(.academy(course))
                                }
                                Button("Delete", role: .destructive) {
                                    store.deleteCourse(course)
                                }
                            }
                    }
                }
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func start(_ course: Course) {
        SoundPlayer.tap(enabled: store.state.settings.audioEnabled)
        store.startFlight(for: course.id)
    }

    private func complete(_ course: Course) {
        store.completeToday(for: course.id)
        SoundPlayer.success(enabled: store.state.settings.audioEnabled)
    }
}

private struct HomeHeader: View {
    @EnvironmentObject private var store: AppStore
    @Binding var path: [AppRoute]

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("TAPPY\nBRAIN")
                .font(.pixel(25, weight: .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "bitcoinsign.circle")
                Text("\(store.state.coins)")
            }
            .font(.pixel(17, weight: .bold))
            .frame(width: 92, height: 46)
            .background(TappyColors.yellow)
            .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))

            Button {
                path.append(.settings)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 21, weight: .bold))
                    .frame(width: 46, height: 46)
                    .background(Color(uiColor: .systemBackground))
                    .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")

            Button {
                path.append(.notifications)
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 21, weight: .bold))
                        .frame(width: 46, height: 46)
                        .background(Color(uiColor: .systemBackground))
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
                    if store.state.notices.contains(where: { !$0.isRead }) {
                        Circle()
                            .fill(TappyColors.red)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(TappyColors.ink, lineWidth: 2))
                            .offset(x: -5, y: 6)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(uiColor: .systemBackground))
        .overlay(alignment: .bottom) {
            Rectangle().fill(TappyColors.ink).frame(height: 4)
        }
    }
}

private struct EmptyCoursesView: View {
    let createAction: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            PixelCard {
                VStack(spacing: 18) {
                    AvatarView(avatar: .yellowBird, size: 86)
                    Text("NO COURSES.\nINSERT COIN TO START")
                        .font(.pixel(24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)
                    Text("Create your first learning flight and keep the streak alive.")
                        .font(.pixel(15))
                        .foregroundStyle(TappyColors.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 28)

            PixelButton(title: "NEW COURSE", systemImage: "plus", color: TappyColors.yellow, action: createAction)
                .padding(.horizontal, 36)
            Spacer()
        }
    }
}

private struct CourseCard: View {
    let course: Course
    let isSelected: Bool

    var body: some View {
        PixelCard(borderColor: isSelected ? TappyColors.yellow : TappyColors.ink, padding: 12) {
            HStack(spacing: 12) {
                AvatarView(avatar: course.avatar, size: 58)
                VStack(alignment: .leading, spacing: 7) {
                    Text(course.name)
                        .font(.pixel(17, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.55)
                    Text("\(Int(course.progress * 100))% Complete")
                        .font(.pixel(12))
                        .foregroundStyle(TappyColors.muted)
                    HStack(spacing: 16) {
                        metric("\(course.currentStreak)", "Streak", TappyColors.orange)
                        metric("\(course.completedPipes)", "Pipes", TappyColors.green)
                        metric("\(course.xp)", "XP", TappyColors.yellow)
                    }
                }
            }
            .frame(width: 250, alignment: .leading)
        }
    }

    private func metric(_ value: String, _ title: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.pixel(14, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.pixel(10))
        }
    }
}

private struct FlightSceneView: View {
    let course: Course
    let phase: FlightPhase
    let timerRemaining: Int
    let onStart: () -> Void
    let onTap: () -> Void

    private var buttonTitle: String {
        switch phase {
        case .ready: "STUDY"
        case .timerRunning: "RUNNING"
        case .tapReady: "TAP"
        case .completed: "CLEARED"
        }
    }

    private var buttonColor: Color {
        switch phase {
        case .ready: TappyColors.orange
        case .timerRunning: TappyColors.grey
        case .tapReady, .completed: Color(red: 0.55, green: 1.00, blue: 0.26)
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                Rectangle()
                    .stroke(TappyColors.ink, lineWidth: 4)

                VStack(spacing: 8) {
                    Text(course.goalType == .time ? "TIMER" : "TODAY")
                        .font(.pixel(25, weight: .bold))
                    Text(displayTimer)
                        .font(.pixel(28, weight: .bold))
                        .padding(.horizontal, 22)
                        .frame(height: 54)
                        .background(phase == .tapReady ? TappyColors.yellow : Color(uiColor: .systemBackground))
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 22)

                HStack(alignment: .bottom) {
                    AvatarView(avatar: course.avatar, size: 74, showsTile: false)
                        .rotationEffect(.degrees(phase == .completed ? -12 : 0))
                        .offset(y: phase == .completed ? -34 : 0)
                    Spacer()
                    PipeView(label: course.todayTask, status: phase == .completed ? .completed : .pending)
                }
                .padding(.horizontal, 34)
                .frame(maxHeight: .infinity, alignment: .bottom)

                if phase == .tapReady || phase == .completed {
                    Text("+\(max(30, course.dailyTarget)) XP")
                        .font(.pixel(24, weight: .bold))
                        .foregroundStyle(TappyColors.yellow)
                        .offset(y: -22)
                        .accessibilityLabel("XP ready")
                }
            }
            .frame(height: 360)
            .accessibilityElement(children: .combine)

            PixelButton(title: buttonTitle, systemImage: phase == .ready ? "graduationcap.fill" : nil, color: buttonColor, disabled: phase == .timerRunning || phase == .completed) {
                switch phase {
                case .ready:
                    onStart()
                case .tapReady:
                    onTap()
                case .timerRunning, .completed:
                    break
                }
            }
        }
    }

    private var displayTimer: String {
        if course.goalType != .time {
            return course.todayTask
        }
        let minutes = timerRemaining / 60
        let seconds = timerRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var state = AppState()
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let calendar = Calendar.current
    private let fileURL: URL

    init() {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folderURL = baseURL.appendingPathComponent("TappyBrainEducation", isDirectory: true)
        fileURL = folderURL.appendingPathComponent("tappy_brain_state.json")
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                state = AppState()
                try save()
                return
            }

            let data = try Data(contentsOf: fileURL)
            state = try JSONDecoder.tappy.decode(AppState.self, from: data)
            recalculateMissedDays()
            refreshActiveFlights()
            try save()
        } catch {
            errorMessage = "Saved data could not be loaded. A clean flight log is ready."
            state = AppState()
        }
    }

    func save() throws {
        let data = try JSONEncoder.tappy.encode(state)
        try data.write(to: fileURL, options: [.atomic])
    }

    func createCourse(_ course: Course) {
        var newCourse = course
        newCourse.name = course.name.trimmed
        state.courses.append(newCourse)
        addNotice(type: .reminder, title: "READY TO FLY", message: "\(newCourse.name) is waiting for the first TAP.")
        persistAfterMutation()
    }

    func updateCourse(_ course: Course) {
        guard let index = state.courses.firstIndex(where: { $0.id == course.id }) else { return }
        var updated = course
        updated.name = course.name.trimmed
        state.courses[index] = updated
        persistAfterMutation()
    }

    func deleteCourse(_ course: Course) {
        state.courses.removeAll { $0.id == course.id }
        state.studyDays.removeAll { $0.courseID == course.id }
        if state.selectedCourseID == course.id {
            state.selectedCourseID = state.courses.first?.id
        }
        persistAfterMutation()
    }

    func selectCourse(_ courseID: UUID) {
        guard state.courses.contains(where: { $0.id == courseID }) else { return }
        state.selectedCourseID = courseID
        persistAfterMutation()
    }

    func flightState(for course: Course, now: Date = Date()) -> (phase: FlightPhase, timerRemaining: Int) {
        let today = calendar.startOfDay(for: now)
        if state.studyDays.contains(where: { $0.courseID == course.id && calendar.isDate($0.date, inSameDayAs: today) && $0.status == .completed }) {
            return (.completed, 0)
        }

        let targetSeconds = max(course.dailyTarget, 1) * 60
        let phase = course.flightPhase ?? .ready
        let storedRemaining = course.flightTimerRemaining ?? targetSeconds

        guard phase == .timerRunning, let startedAt = course.flightTimerStartedAt else {
            return (phase, storedRemaining)
        }

        let elapsed = max(Int(now.timeIntervalSince(startedAt)), 0)
        let remaining = max(storedRemaining - elapsed, 0)
        return (remaining == 0 ? .tapReady : .timerRunning, remaining)
    }

    func startFlight(for courseID: UUID) {
        guard let index = state.courses.firstIndex(where: { $0.id == courseID }) else { return }
        var course = state.courses[index]

        if course.goalType == .time {
            course.flightPhase = .timerRunning
            course.flightTimerRemaining = max(course.dailyTarget, 1) * 60
            course.flightTimerStartedAt = Date()
        } else {
            course.flightPhase = .tapReady
            course.flightTimerRemaining = nil
            course.flightTimerStartedAt = nil
        }

        state.courses[index] = course
        persistAfterMutation()
    }

    func refreshFlight(for courseID: UUID) {
        guard let index = state.courses.firstIndex(where: { $0.id == courseID }) else { return }
        let course = state.courses[index]
        let stateForCourse = flightState(for: course)
        guard stateForCourse.phase != course.flightPhase || stateForCourse.timerRemaining != course.flightTimerRemaining else { return }

        var updated = course
        updated.flightPhase = stateForCourse.phase
        updated.flightTimerRemaining = stateForCourse.timerRemaining
        updated.flightTimerStartedAt = stateForCourse.phase == .timerRunning ? course.flightTimerStartedAt : nil
        state.courses[index] = updated
        persistAfterMutation()
    }

    func refreshActiveFlights() {
        var hasChanges = false

        for index in state.courses.indices {
            let course = state.courses[index]
            let stateForCourse = flightState(for: course)
            if stateForCourse.phase != course.flightPhase || stateForCourse.timerRemaining != course.flightTimerRemaining {
                state.courses[index].flightPhase = stateForCourse.phase
                state.courses[index].flightTimerRemaining = stateForCourse.timerRemaining
                state.courses[index].flightTimerStartedAt = stateForCourse.phase == .timerRunning ? course.flightTimerStartedAt : nil
                hasChanges = true
            }
        }

        if let selectedCourseID = state.selectedCourseID,
           !state.courses.contains(where: { $0.id == selectedCourseID }) {
            state.selectedCourseID = state.courses.first?.id
            hasChanges = true
        }

        if state.selectedCourseID == nil, let firstCourseID = state.courses.first?.id {
            state.selectedCourseID = firstCourseID
            hasChanges = true
        }

        if hasChanges {
            persistAfterMutation()
        }
    }

    func completeToday(for courseID: UUID) {
        guard let index = state.courses.firstIndex(where: { $0.id == courseID }) else { return }
        let today = calendar.startOfDay(for: Date())

        if state.studyDays.contains(where: { $0.courseID == courseID && calendar.isDate($0.date, inSameDayAs: today) && $0.status == .completed }) {
            return
        }

        var course = state.courses[index]
        let earnedXP = xpForCompletion(course)
        course.completedPipes = min(course.completedPipes + 1, course.finishLine)
        course.currentStreak += 1
        course.bestStreak = max(course.bestStreak, course.currentStreak)
        course.xp += earnedXP
        course.lastTappedAt = Date()
        course.flightPhase = .completed
        course.flightTimerRemaining = 0
        course.flightTimerStartedAt = nil

        if course.isCompleted && course.completedAt == nil {
            course.completedAt = Date()
            addNotice(type: .achievement, title: "COURSE CLEARED", message: "\(course.name) reached the finish line.")
        } else if course.currentStreak == 7 || course.currentStreak == 21 || course.currentStreak == 50 {
            addNotice(type: .streak, title: "\(course.currentStreak) DAY STREAK!", message: "Keep \(course.name) alive.")
        }

        state.coins += 10
        state.courses[index] = course
        upsertStudyDay(
            courseID: course.id,
            date: today,
            status: .completed,
            task: course.todayTask,
            xpEarned: earnedXP,
            streak: course.currentStreak,
            notes: ""
        )
        persistAfterMutation()
    }

    func failDay(for courseID: UUID, date: Date, notes: String) {
        guard let index = state.courses.firstIndex(where: { $0.id == courseID }) else { return }
        var course = state.courses[index]
        let day = calendar.startOfDay(for: date)
        course.currentStreak = 0
        state.courses[index] = course
        upsertStudyDay(courseID: course.id, date: day, status: .failed, task: course.todayTask, xpEarned: 0, streak: 0, notes: notes)
        addNotice(type: .danger, title: "STREAK IN DANGER", message: "\(course.name) missed a study session.")
        persistAfterMutation()
    }

    func markNoticeRead(_ notice: Notice) {
        guard let index = state.notices.firstIndex(where: { $0.id == notice.id }) else { return }
        state.notices[index].isRead = true
        persistAfterMutation()
    }

    func deleteNotice(_ notice: Notice) {
        state.notices.removeAll { $0.id == notice.id }
        persistAfterMutation()
    }

    func updateSettings(_ settings: AppSettings) {
        state.settings = settings
        persistAfterMutation()
    }

    func status(for course: Course, on date: Date) -> DayStatus {
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())

        if let record = state.studyDays.first(where: { $0.courseID == course.id && calendar.isDate($0.date, inSameDayAs: day) }) {
            return record.status
        }

        if day > today { return .future }
        if !course.activeWeekdays.contains(Weekday(rawValue: calendar.component(.weekday, from: day)) ?? .monday) {
            return .rest
        }
        if calendar.isDate(day, inSameDayAs: today) { return .pending }
        return .failed
    }

    func summaryStatus(on date: Date) -> DayStatus {
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())

        if day > today {
            return .future
        }

        let statuses = state.courses.map { status(for: $0, on: day) }
        guard !statuses.isEmpty else {
            return .future
        }

        if statuses.contains(.failed) { return .failed }
        if statuses.contains(.pending) { return .pending }
        if statuses.contains(.completed) { return .completed }
        return .rest
    }

    func studyDay(for course: Course, on date: Date) -> StudyDay? {
        state.studyDays.first { $0.courseID == course.id && calendar.isDate($0.date, inSameDayAs: date) }
    }

    func dayResults(on date: Date) -> [DayCourseResult] {
        let day = calendar.startOfDay(for: date)

        return state.courses.compactMap { course in
            let status = status(for: course, on: day)
            guard status != .future, status != .rest else { return nil }

            let record = studyDay(for: course, on: day)
            return DayCourseResult(
                id: course.id,
                courseName: course.name,
                task: record?.task ?? course.todayTask,
                status: status,
                xpEarned: record?.xpEarned ?? 0,
                streakAfterDay: record?.streakAfterDay ?? course.currentStreak,
                notes: record?.notes ?? ""
            )
        }
    }

    func diplomas() -> [Diploma] {
        state.courses
            .filter(\.isCompleted)
            .map { Diploma(id: $0.id, course: $0) }
    }

    func shareText(for course: Course) -> String {
        let date = course.completedAt.map { DateFormatter.shortDate.string(from: $0) } ?? "in progress"
        return "Certificate of Completion\nLearner completed \(course.name)\nCompleted on \(date)\nTotal XP: \(course.xp)"
    }

    private func recalculateMissedDays() {
        let today = calendar.startOfDay(for: Date())

        for index in state.courses.indices {
            let course = state.courses[index]
            guard !course.isCompleted else { continue }
            let start = calendar.startOfDay(for: course.lastTappedAt ?? course.createdAt)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: start), nextDay < today else { continue }

            var cursor = nextDay
            var missed = false
            while cursor < today {
                let weekday = Weekday(rawValue: calendar.component(.weekday, from: cursor)) ?? .monday
                let hasRecord = state.studyDays.contains { $0.courseID == course.id && calendar.isDate($0.date, inSameDayAs: cursor) }
                if course.activeWeekdays.contains(weekday) && !hasRecord {
                    upsertStudyDay(courseID: course.id, date: cursor, status: .failed, task: course.todayTask, xpEarned: 0, streak: 0, notes: "Missed study session")
                    missed = true
                }
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? today
            }

            if missed {
                state.courses[index].currentStreak = 0
                addNotice(type: .danger, title: "GAME OVER", message: "\(course.name) streak was reset after a missed day.")
            }
        }
    }

    private func upsertStudyDay(courseID: UUID, date: Date, status: DayStatus, task: String, xpEarned: Int, streak: Int, notes: String) {
        let day = calendar.startOfDay(for: date)
        if let index = state.studyDays.firstIndex(where: { $0.courseID == courseID && calendar.isDate($0.date, inSameDayAs: day) }) {
            state.studyDays[index].status = status
            state.studyDays[index].task = task
            state.studyDays[index].xpEarned = xpEarned
            state.studyDays[index].streakAfterDay = streak
            state.studyDays[index].notes = notes
        } else {
            state.studyDays.append(
                StudyDay(
                    id: UUID(),
                    courseID: courseID,
                    date: day,
                    status: status,
                    task: task,
                    xpEarned: xpEarned,
                    streakAfterDay: streak,
                    notes: notes
                )
            )
        }
    }

    private func addNotice(type: NoticeType, title: String, message: String) {
        state.notices.insert(
            Notice(id: UUID(), type: type, title: title, message: message, createdAt: Date(), isRead: false),
            at: 0
        )
    }

    private func xpForCompletion(_ course: Course) -> Int {
        switch course.goalType {
        case .time: max(30, course.dailyTarget)
        case .volume: 30 + min(course.dailyTarget * 2, 60)
        case .flex: 30
        }
    }

    private func persistAfterMutation() {
        do {
            try save()
        } catch {
            errorMessage = "Changes could not be saved. Try again after reopening the app."
        }
    }
}

private extension JSONEncoder {
    static var tappy: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var tappy: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

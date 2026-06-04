import Foundation
import SwiftUI

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case time
    case volume
    case flex

    var id: String { rawValue }

    var title: String {
        switch self {
        case .time: "TIME MODE"
        case .volume: "VOLUME MODE"
        case .flex: "FLEX MODE"
        }
    }

    var subtitle: String {
        switch self {
        case .time: "Study for X minutes daily"
        case .volume: "Complete pages, videos, or tasks"
        case .flex: "Flexible schedule with selected weekdays"
        }
    }

    var symbol: String {
        switch self {
        case .time: "clock"
        case .volume: "book"
        case .flex: "checkmark.square"
        }
    }
}

enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: "SUN"
        case .monday: "MON"
        case .tuesday: "TUE"
        case .wednesday: "WED"
        case .thursday: "THU"
        case .friday: "FRI"
        case .saturday: "SAT"
        }
    }
}

enum DayStatus: String, Codable {
    case pending
    case completed
    case failed
    case rest
    case future
}

enum FlightPhase: String, Codable {
    case ready
    case timerRunning
    case tapReady
    case completed
}

enum AvatarKind: String, Codable, CaseIterable, Identifiable {
    case yellowBird
    case books
    case guitar
    case palette
    case laptop
    case brain
    case owl
    case robot

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yellowBird: "Yellow bird"
        case .books: "Books"
        case .guitar: "Guitar"
        case .palette: "Palette"
        case .laptop: "Laptop"
        case .brain: "Brain"
        case .owl: "Owl"
        case .robot: "Robot"
        }
    }

    var emoji: String {
        switch self {
        case .yellowBird: "🐤"
        case .books: "📚"
        case .guitar: "🎸"
        case .palette: "🎨"
        case .laptop: "💻"
        case .brain: "🧠"
        case .owl: "🦉"
        case .robot: "🤖"
        }
    }

    var assetName: String? {
        switch self {
        case .yellowBird: "avatar_yellow_bird"
        default: nil
        }
    }
}

struct Course: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var avatar: AvatarKind
    var goalType: GoalType
    var dailyTarget: Int
    var targetUnit: String
    var finishLine: Int
    var activeWeekdays: Set<Weekday>
    var completedPipes: Int
    var currentStreak: Int
    var bestStreak: Int
    var xp: Int
    var createdAt: Date
    var completedAt: Date?
    var lastTappedAt: Date?
    var flightPhase: FlightPhase?
    var flightTimerRemaining: Int?
    var flightTimerStartedAt: Date?

    var progress: Double {
        guard finishLine > 0 else { return 0 }
        return min(Double(completedPipes) / Double(finishLine), 1)
    }

    var isCompleted: Bool {
        completedPipes >= finishLine
    }

    var todayTask: String {
        switch goalType {
        case .time:
            return "\(dailyTarget) MIN TIMER"
        case .volume:
            let unit = dailyTarget == 1 ? targetUnit.singularized : targetUnit
            return "\(dailyTarget) \(unit)".uppercased()
        case .flex:
            return "TAP TO BEGIN"
        }
    }
}

struct StudyDay: Identifiable, Codable, Equatable {
    var id: UUID
    var courseID: UUID
    var date: Date
    var status: DayStatus
    var task: String
    var xpEarned: Int
    var streakAfterDay: Int
    var notes: String
}

struct DayCourseResult: Identifiable, Equatable {
    let id: UUID
    let courseName: String
    let task: String
    let status: DayStatus
    let xpEarned: Int
    let streakAfterDay: Int
    let notes: String
}

enum NoticeType: String, Codable {
    case streak
    case achievement
    case reminder
    case danger
    case milestone
}

struct Notice: Identifiable, Codable, Equatable {
    var id: UUID
    var type: NoticeType
    var title: String
    var message: String
    var createdAt: Date
    var isRead: Bool
}

struct AppSettings: Codable, Equatable {
    var audioEnabled: Bool = true
    var notificationsEnabled: Bool = true
    var reminderHour: Int = 10
    var reminderMinute: Int = 0
}

struct AppState: Codable, Equatable {
    var courses: [Course] = []
    var studyDays: [StudyDay] = []
    var notices: [Notice] = []
    var settings: AppSettings = AppSettings()
    var coins: Int = 250
    var selectedCourseID: UUID?

    enum CodingKeys: String, CodingKey {
        case courses
        case studyDays
        case notices
        case settings
        case coins
        case selectedCourseID
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        courses = try container.decodeIfPresent([Course].self, forKey: .courses) ?? []
        studyDays = try container.decodeIfPresent([StudyDay].self, forKey: .studyDays) ?? []
        notices = try container.decodeIfPresent([Notice].self, forKey: .notices) ?? []
        settings = try container.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
        coins = try container.decodeIfPresent(Int.self, forKey: .coins) ?? 250
        selectedCourseID = try container.decodeIfPresent(UUID.self, forKey: .selectedCourseID)
    }
}

struct Diploma: Identifiable, Equatable {
    let id: UUID
    let course: Course
}

extension Course {
    static func emptyDraft() -> Course {
        Course(
            id: UUID(),
            name: "",
            avatar: .yellowBird,
            goalType: .time,
            dailyTarget: 25,
            targetUnit: "minutes",
            finishLine: 40,
            activeWeekdays: Set(Weekday.allCases),
            completedPipes: 0,
            currentStreak: 0,
            bestStreak: 0,
            xp: 0,
            createdAt: Date(),
            completedAt: nil,
            lastTappedAt: nil,
            flightPhase: nil,
            flightTimerRemaining: nil,
            flightTimerStartedAt: nil
        )
    }
}

extension String {
    var singularized: String {
        if hasSuffix("s") {
            return String(dropLast())
        }
        return self
    }
}

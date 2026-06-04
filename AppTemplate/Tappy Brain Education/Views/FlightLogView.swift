import SwiftUI

struct FlightLogView: View {
    @EnvironmentObject private var store: AppStore
    @State private var displayedMonth = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate: Date?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HeaderBar(title: "FLIGHT LOG")

                if store.state.courses.isEmpty {
                    EmptyLogView()
                } else {
                    ScrollView {
                        VStack(spacing: 22) {
                            monthPicker
                            CalendarGridView(month: displayedMonth, selectedDate: $selectedDate)
                        }
                        .padding(24)
                    }
                }
            }
            .tappyBackground()

            if let selectedDate {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        closeDayDetails()
                    }

                DayDetailView(date: selectedDate, onClose: closeDayDetails)
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 32)
                    .transition(.scale(scale: 0.94).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.22, dampingFraction: 0.9), value: selectedDate)
        .onAppear {
            displayedMonth = Calendar.current.startOfDay(for: Date())
        }
    }

    private func closeDayDetails() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
            selectedDate = nil
        }
    }

    private var monthPicker: some View {
        PixelCard {
            HStack {
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 54, height: 54)
                        .background(TappyColors.yellow)
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous month")

                Spacer()
                Text(monthTitle)
                    .font(.pixel(24, weight: .bold))
                    .multilineTextAlignment(.center)
                Spacer()

                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 54, height: 54)
                        .background(TappyColors.yellow)
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next month")
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM\nyyyy"
        return formatter.string(from: displayedMonth).uppercased()
    }
}

private struct EmptyLogView: View {
    var body: some View {
        VStack {
            Spacer()
            PixelCard {
                VStack(spacing: 14) {
                    PixelIconTile(color: TappyColors.grey, systemName: "calendar", size: 72)
                    Text("NO FLIGHTS YET")
                        .font(.pixel(24, weight: .bold))
                    Text("Create a course to fill the route map.")
                        .font(.pixel(15))
                        .foregroundStyle(TappyColors.muted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(28)
            Spacer()
        }
    }
}

private struct CalendarGridView: View {
    @EnvironmentObject private var store: AppStore
    let month: Date
    @Binding var selectedDate: Date?

    private let calendar = Calendar.current

    var body: some View {
        PixelCard {
            VStack(spacing: 18) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 7), spacing: 9) {
                    ForEach(Weekday.allCases) { day in
                        Text(day.shortName)
                            .font(.pixel(11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(TappyColors.ink)
                    }

                    ForEach(daysForGrid, id: \.self) { date in
                        if let date {
                            DayCell(date: date, status: store.summaryStatus(on: date), isToday: calendar.isDateInToday(date))
                                .onTapGesture {
                                    selectedDate = date
                                }
                        } else {
                            Color.clear.frame(height: 44)
                        }
                    }
                }

                Rectangle()
                    .fill(TappyColors.ink)
                    .frame(height: 4)

                legend
            }
        }
    }

    private var daysForGrid: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let daysRange = calendar.range(of: .day, in: .month, for: month)
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: interval.start)
        var result: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in daysRange {
            var components = calendar.dateComponents([.year, .month], from: month)
            components.day = day
            result.append(calendar.date(from: components))
        }

        while result.count % 7 != 0 {
            result.append(nil)
        }

        return result
    }

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            legendItem(TappyColors.green, "Completed")
            legendItem(TappyColors.red, "Failed")
            legendItem(TappyColors.yellow, "Today")
            legendItem(TappyColors.grey, "Rest")
            legendItem(Color(uiColor: .secondarySystemBackground), "Future")
        }
    }

    private func legendItem(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
            Text(text)
                .font(.pixel(12))
            Spacer()
        }
    }
}

private struct DayCell: View {
    let date: Date
    let status: DayStatus
    let isToday: Bool

    private var calendar: Calendar { .current }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.pixel(17, weight: .bold))
            Text(symbol)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundStyle(textColor)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(background)
        .overlay(Rectangle().stroke(borderColor, lineWidth: isToday ? 4 : 2))
        .accessibilityLabel("Day \(calendar.component(.day, from: date)), \(accessibilityStatus)")
    }

    private var background: Color {
        switch status {
        case .completed: TappyColors.green
        case .failed: TappyColors.red
        case .pending: TappyColors.yellow
        case .rest: TappyColors.grey
        case .future: Color(uiColor: .secondarySystemBackground)
        }
    }

    private var borderColor: Color {
        isToday ? TappyColors.yellow : TappyColors.ink.opacity(status == .future ? 0.25 : 1)
    }

    private var textColor: Color {
        status == .future ? TappyColors.grey : .white
    }

    private var symbol: String {
        switch status {
        case .completed: "✓"
        case .failed: "×"
        case .pending: "★"
        case .rest: "−"
        case .future: ""
        }
    }

    private var accessibilityStatus: String {
        switch status {
        case .completed: "completed"
        case .failed: "failed"
        case .pending: "today"
        case .rest: "rest day"
        case .future: "future"
        }
    }
}

private struct DayDetailView: View {
    @EnvironmentObject private var store: AppStore
    let date: Date
    let onClose: () -> Void

    private var status: DayStatus {
        store.summaryStatus(on: date)
    }

    private var results: [DayCourseResult] {
        store.dayResults(on: date)
    }

    private var totalXP: Int {
        results.reduce(0) { $0 + $1.xpEarned }
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("DAY \(Calendar.current.component(.day, from: date))")
                    .font(.pixel(25, weight: .bold))
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(TappyColors.red)
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close day details")
            }

            Rectangle()
                .fill(color)
                .frame(height: 8)
                .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 2))

            PixelCard(shadowColor: .clear, padding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.pixel(12))
                        .foregroundStyle(TappyColors.muted)
                    if results.isEmpty {
                        Text(emptySummaryText)
                            .font(.pixel(18, weight: .bold))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(results) { result in
                                DayResultRow(result: result)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !results.isEmpty {
                HStack(spacing: 14) {
                    stat("+\(totalXP)", "XP Earned", TappyColors.yellow)
                    stat("\(results.count)", "Tasks", TappyColors.orange)
                }
            }

            if status == .completed {
                PixelButton(title: "COMPLETED", systemImage: "checkmark", color: TappyColors.green, foreground: .white, disabled: true) {}
            } else if status == .failed {
                PixelButton(title: "FAILED", systemImage: "xmark", color: TappyColors.red, foreground: .white, disabled: true) {}
            } else if status == .pending {
                Text("Complete today's tasks from the Flight screen.")
                    .font(.pixel(14))
                    .foregroundStyle(TappyColors.muted)
                    .multilineTextAlignment(.center)
            } else if status == .rest {
                Text("Rest day. No active course tasks.")
                    .font(.pixel(14))
                    .foregroundStyle(TappyColors.muted)
            } else {
                Text("Future route. Come back later.")
                    .font(.pixel(14))
                    .foregroundStyle(TappyColors.muted)
            }
        }
        .padding(28)
        .background(TappyColors.paper)
        .overlay(
            Rectangle()
                .stroke(TappyColors.ink, lineWidth: 4)
        )
        .background(
            TappyColors.ink
                .offset(x: 8, y: 8)
        )
    }

    private var emptySummaryText: String {
        switch status {
        case .pending:
            "TAP TO BEGIN"
        case .rest:
            "REST DAY"
        case .future:
            "LOCKED ROUTE"
        case .completed:
            "ALL TASKS CLEAR"
        case .failed:
            "NO RESULT"
        }
    }

    private var color: Color {
        switch status {
        case .completed: TappyColors.green
        case .failed: TappyColors.red
        case .pending: TappyColors.yellow
        case .rest, .future: TappyColors.grey
        }
    }

    private func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.pixel(24, weight: .bold))
            Text(label)
                .font(.pixel(11))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(color)
        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 4))
    }
}

private struct DayResultRow: View {
    let result: DayCourseResult

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 2))
                Text(result.courseName.uppercased())
                    .font(.pixel(14, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(result.task)
                .font(.pixel(18, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)

            if result.xpEarned > 0 || result.streakAfterDay > 0 {
                Text("+\(result.xpEarned) XP · \(result.streakAfterDay) STREAK")
                    .font(.pixel(12))
                    .foregroundStyle(TappyColors.muted)
            }

            if !result.notes.isEmpty {
                Text(result.notes)
                    .font(.pixel(12))
                    .foregroundStyle(TappyColors.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var color: Color {
        switch result.status {
        case .completed: TappyColors.green
        case .failed: TappyColors.red
        case .pending: TappyColors.yellow
        case .rest, .future: TappyColors.grey
        }
    }
}

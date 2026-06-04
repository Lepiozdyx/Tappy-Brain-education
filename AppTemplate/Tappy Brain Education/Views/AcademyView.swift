import SwiftUI

struct AcademyView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Course
    @State private var dailyTargetText: String
    @State private var finishLineText: String
    @State private var showDeleteConfirm = false
    @State private var validationMessage: String?
    @FocusState private var focusedField: AcademyFocusField?

    private let isEditing: Bool

    init(editingCourse: Course?) {
        isEditing = editingCourse != nil
        let initialDraft = editingCourse ?? Course.emptyDraft()
        _draft = State(initialValue: initialDraft)
        _dailyTargetText = State(initialValue: "\(initialDraft.dailyTarget)")
        _finishLineText = State(initialValue: "\(initialDraft.finishLine)")
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderBar(title: "ACADEMY", showBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    nameCard
                    avatarCard
                    goalTypeSection
                    targetCard
                    scheduleCard
                    previewCard

                    if let validationMessage {
                        ValidationMessage(text: validationMessage)
                            .padding(.horizontal, 4)
                    }

                    HStack(spacing: 18) {
                        PixelButton(title: isEditing ? "SAVE" : "SAVE COURSE", systemImage: "square.and.arrow.down", color: TappyColors.yellow) {
                            save()
                        }

                        if isEditing {
                            PixelButton(title: "DELETE", systemImage: "trash", color: TappyColors.red, foreground: .white) {
                                showDeleteConfirm = true
                            }
                        }
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .tappyBackground()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .alert("Delete Course?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                store.deleteCourse(draft)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The course and its flight log will be removed.")
        }
    }

    private var nameCard: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("COURSE NAME")
                    .font(.pixel(20, weight: .bold))
                TextField("Enter course name...", text: $draft.name)
                    .font(.pixel(18))
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
                    .focused($focusedField, equals: .name)
            }
        }
    }

    private var avatarCard: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("SELECT AVATAR")
                    .font(.pixel(20, weight: .bold))
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(64), spacing: 12), count: 3), alignment: .leading, spacing: 12) {
                    ForEach(AvatarKind.allCases) { avatar in
                        Button {
                            draft.avatar = avatar
                        } label: {
                            AvatarView(avatar: avatar, size: 60)
                                .background(draft.avatar == avatar ? TappyColors.yellow : Color.clear)
                                .overlay(Rectangle().stroke(draft.avatar == avatar ? TappyColors.yellow : TappyColors.ink, lineWidth: draft.avatar == avatar ? 6 : 4))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Select \(avatar.title)")
                    }
                }
            }
        }
    }

    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("GOAL TYPE")
                .font(.pixel(19, weight: .bold))
            ForEach(GoalType.allCases) { goal in
                Button {
                    draft.goalType = goal
                    if goal == .time {
                        draft.targetUnit = "minutes"
                    } else if goal == .volume && draft.targetUnit == "minutes" {
                        draft.targetUnit = "pages"
                    }
                } label: {
                    PixelCard(borderColor: draft.goalType == goal ? TappyColors.yellow : TappyColors.ink) {
                        HStack(alignment: .top, spacing: 16) {
                            PixelIconTile(color: goal == .time ? TappyColors.orange : goal == .volume ? TappyColors.green : TappyColors.yellow, systemName: goal.symbol)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(goal.title)
                                    .font(.pixel(20, weight: .bold))
                                Text(goal.subtitle)
                                    .font(.pixel(14))
                                    .foregroundStyle(TappyColors.muted)
                            }
                            Spacer()
                            if draft.goalType == goal {
                                Image(systemName: "checkmark.square.fill")
                                    .foregroundStyle(TappyColors.green)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var targetCard: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(draft.goalType == .time ? "MINUTES PER DAY" : "DAILY TARGET")
                    .font(.pixel(20, weight: .bold))
                TextField("25", text: $dailyTargetText)
                    .font(.pixel(18))
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
                    .focused($focusedField, equals: .dailyTarget)
                    .accessibilityLabel(draft.goalType == .time ? "Minutes per day" : "Daily target")

                if draft.goalType != .time {
                    TextField("Unit, for example pages", text: $draft.targetUnit)
                        .font(.pixel(17))
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
                        .focused($focusedField, equals: .targetUnit)
                }

                Text("FINISH LINE")
                    .font(.pixel(20, weight: .bold))
                    .padding(.top, 8)
                TextField("100", text: $finishLineText)
                    .font(.pixel(18))
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
                    .focused($focusedField, equals: .finishLine)
                    .accessibilityLabel("Finish line")
            }
        }
    }

    private var scheduleCard: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("ACTIVE DAYS")
                    .font(.pixel(20, weight: .bold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    ForEach(Weekday.allCases) { day in
                        Button {
                            if draft.activeWeekdays.contains(day) {
                                draft.activeWeekdays.remove(day)
                            } else {
                                draft.activeWeekdays.insert(day)
                            }
                        } label: {
                            Text(day.shortName)
                                .font(.pixel(13, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(draft.activeWeekdays.contains(day) ? TappyColors.green : TappyColors.grey)
                                .foregroundStyle(.white)
                                .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(day.shortName) active")
                    }
                }
            }
        }
    }

    private var previewCard: some View {
        PixelCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("COURSE PREVIEW")
                    .font(.pixel(20, weight: .bold))
                CoursePreview(course: draft)
            }
        }
    }

    private func save() {
        validationMessage = nil
        let name = draft.name.trimmed
        guard !name.isEmpty else {
            validationMessage = "Course name is required."
            return
        }
        guard !draft.activeWeekdays.isEmpty else {
            validationMessage = "Select at least one active day."
            return
        }
        guard let dailyTarget = Int(dailyTargetText.trimmed), (1...999).contains(dailyTarget) else {
            validationMessage = "Daily target must be a number from 1 to 999."
            return
        }
        guard let finishLine = Int(finishLineText.trimmed), (1...500).contains(finishLine) else {
            validationMessage = "Finish line must be a number from 1 to 500."
            return
        }
        guard draft.goalType == .time || !draft.targetUnit.trimmed.isEmpty else {
            validationMessage = "Daily target unit is required."
            return
        }

        draft.name = name
        draft.dailyTarget = dailyTarget
        draft.finishLine = finishLine
        draft.targetUnit = draft.goalType == .time ? "minutes" : draft.targetUnit.trimmed
        if isEditing {
            store.updateCourse(draft)
        } else {
            store.createCourse(draft)
        }
        dismiss()
    }
}

private enum AcademyFocusField: Hashable {
    case name
    case dailyTarget
    case targetUnit
    case finishLine
}

private struct CoursePreview: View {
    let course: Course

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(avatar: course.avatar, size: 70)
            VStack(alignment: .leading, spacing: 8) {
                Text(course.name.trimmed.isEmpty ? "New Course" : course.name)
                    .font(.pixel(20, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
                HStack(spacing: 20) {
                    previewMetric("\(course.currentStreak)", "Streak", TappyColors.orange)
                    previewMetric("\(course.finishLine)", "Pipes", TappyColors.green)
                    previewMetric("\(Int(course.progress * 100))%", "Complete", TappyColors.yellow)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .overlay(Rectangle().stroke(TappyColors.ink, lineWidth: 3))
    }

    private func previewMetric(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.pixel(15, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.pixel(10))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
    }
}

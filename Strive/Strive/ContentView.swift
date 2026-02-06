import SwiftUI
import Charts
import Combine

struct ContentView: View {
    @EnvironmentObject var store: WorkoutStore

    var body: some View {
        TabView {
            StartWorkoutView()
                .tabItem {
                    Label("Workout", systemImage: "bolt.fill")
                }

            ExercisesView()
                .tabItem {
                    Label("Exercises", systemImage: "figure.strengthtraining.traditional")
                }

            ProgressViewScreen()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutStore())
}

struct StartWorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var showExercisePicker = false
    @State private var expandedWorkouts: Set<UUID> = []

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(spacing: 18) {
                    HeaderCard
                    if let workout = store.activeWorkout {
                        SessionSummaryCard(workout: workout)
                        RestTimerCard

                        ForEach(workout.exercises) { workoutExercise in
                            WorkoutExerciseCard(
                                workoutExercise: workoutExercise,
                                addSet: { weight, reps in
                                    store.addSet(to: workoutExercise.id, weight: weight, reps: reps)
                                }
                            )
                        }

                        Button {
                            showExercisePicker = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus.circle")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(NeonButtonStyle())
                        .padding(.top, 4)

                        Button(role: .destructive) {
                            store.endWorkout()
                        } label: {
                            Label("Finish Workout", systemImage: "flag.checkered")
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(OutlineButtonStyle(tint: .red))
                        .tint(.red)
                        .padding(.top, 8)
                    } else {
                        HeroCard
                            .padding(.top, -6)
                        if !store.history.isEmpty {
                            RecentWorkoutsCard(
                                workouts: store.history,
                                expanded: $expandedWorkouts
                            )
                            .padding(.top, 12)
                        }
                    }
                }
                .sheet(isPresented: $showExercisePicker) {
                    ExercisePickerSheet { exercise in
                        store.addExerciseToWorkout(exercise)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }

    private var HeaderCard: some View {
        NeonCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("STRIVE")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                        Text("Personal workout tracker")
                            .font(.footnote)
                            .foregroundStyle(AppTheme.faint)
                    }
                    Spacer()
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                        .shadow(color: AppTheme.glow, radius: 16, x: 0, y: 0)
                }

                if store.activeWorkout != nil {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(AppTheme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Session Live")
                                .font(.subheadline).fontWeight(.semibold)
                            Text("Keep adding exercises and sets.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.faint)
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(height: 200)
    }

    private var RestTimerCard: some View {
        NeonCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Rest Timer")
                        .font(.headline)
                    Spacer()
                    Text(Date(), style: .time)
                        .font(.caption)
                        .foregroundStyle(AppTheme.faint)
                }
                RestTimerView()
            }
        }
    }

    private var HeroCard: some View {
        NeonCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ready to lift?")
                    .font(.title2).fontWeight(.bold)
                Text("Start a workout to stack exercises, track sets in seconds, and use rest timers.")
                    .foregroundStyle(AppTheme.faint)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                Divider()
                Button {
                    store.startWorkout()
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(NeonButtonStyle())
            }
        }
        .frame(height: 180)
    }
}

struct WorkoutExerciseCard: View {
    let workoutExercise: WorkoutExercise
    let addSet: (Double, Int) -> Void

    @State private var showAddForm = false
    @State private var weightSelection: Double
    @State private var repsSelection: Int

    init(workoutExercise: WorkoutExercise, addSet: @escaping (Double, Int) -> Void) {
        self.workoutExercise = workoutExercise
        self.addSet = addSet
        let initialWeight = (workoutExercise.exercise.latestSet?.weight ?? 20) * 2
        let roundedWeight = (initialWeight.rounded() / 2)
        let initialReps = workoutExercise.exercise.latestSet?.reps ?? 8
        _weightSelection = State(initialValue: min(max(roundedWeight, 0), 250))
        _repsSelection = State(initialValue: min(max(initialReps, 1), 30))
    }

    var body: some View {
        NeonCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workoutExercise.exercise.name)
                            .font(.headline)
                        Text(workoutExercise.exercise.muscleGroup.rawValue)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Add")
                            .font(.caption)
                            .foregroundStyle(AppTheme.faint)
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showAddForm.toggle()
                            }
                        } label: {
                            Image(systemName: showAddForm ? "xmark.circle.fill" : "plus.circle.fill")
                                .foregroundStyle(AppTheme.secondary)
                                .font(.title3)
                        }
                    }
                }

                if showAddForm {
                    AddSetInline(
                        weightSelection: $weightSelection,
                        repsSelection: $repsSelection,
                        onSave: {
                            addSet(weightSelection, repsSelection)
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                showAddForm = false
                            }
                        }
                    )
                }

                if workoutExercise.sets.isEmpty {
                    Text("No sets yet. Add your first one.")
                        .foregroundStyle(AppTheme.faint)
                        .font(.callout)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(workoutExercise.sets) { set in
                            HStack {
                                Text(String(format: "%.1f kg", set.weight))
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(set.reps) reps")
                                    .foregroundStyle(AppTheme.faint)
                            }
                            .padding(10)
                            .background(AppTheme.card.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }

                Button(showAddForm ? "Save Set" : "Add Set") {
                    if showAddForm {
                        addSet(weightSelection, repsSelection)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showAddForm = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            showAddForm = true
                        }
                    }
                }
                .buttonStyle(NeonButtonStyle())
            }
        }
    }
}

struct AddSetInline: View {
    @Binding var weightSelection: Double
    @Binding var repsSelection: Int
    var onSave: () -> Void

    private let weightOptions: [Double] = Array(stride(from: 0.0, through: 250.0, by: 0.5))
    private let repsOptions: [Int] = Array(1...30)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Log set")
                .font(.subheadline).fontWeight(.semibold)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundStyle(AppTheme.faint)
                    Picker("Weight", selection: $weightSelection) {
                        ForEach(weightOptions, id: \.self) { value in
                            Text(String(format: "%.1f kg", value))
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundStyle(AppTheme.faint)
                    Picker("Reps", selection: $repsSelection) {
                        ForEach(repsOptions, id: \.self) { value in
                            Text("\(value)")
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                }
            }
            Button("Log Set") {
                onSave()
            }
            .buttonStyle(NeonButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.card.opacity(0.95))
                .shadow(color: AppTheme.glow, radius: 10)
        )
    }
}

struct ExercisesView: View {
    @EnvironmentObject var store: WorkoutStore

    private var groupedExercises: [(MuscleGroup, [Exercise])] {
        MuscleGroup.allCases
            .map { group in (group, store.exercises.filter { $0.muscleGroup == group }) }
            .filter { !$0.1.isEmpty }
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Exercises")
                        .font(.largeTitle).fontWeight(.black)
                        .padding(.horizontal, 16)
                    Text("Everything you have logged, sorted by muscle group.")
                        .font(.callout)
                        .foregroundStyle(AppTheme.faint)
                        .padding(.horizontal, 16)

                    ForEach(groupedExercises, id: \.0) { group, exercises in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.rawValue)
                                .font(.headline)
                                .padding(.top, 8)
                                .padding(.leading, 16)
                            LazyVStack(spacing: 10) {
                                ForEach(exercises) { exercise in
                                    ExerciseRow(exercise: exercise)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        NeonCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                    Text(exercise.muscleGroup.rawValue)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                    if let latest = exercise.latestSet {
                        Text("Last: \(String(format: "%.1f", latest.weight)) kg × \(latest.reps)")
                            .font(.caption)
                            .foregroundStyle(AppTheme.faint)
                    } else {
                        Text("No history yet.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.faint)
                    }
                }
            }
        }
    }
}

struct ProgressViewScreen: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var selectedExerciseID: Exercise.ID?

    private var selectedExercise: Exercise? {
        if let id = selectedExerciseID {
            return store.exercises.first { $0.id == id }
        }
        return store.exercises.first
    }

    var body: some View {
        NeonBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Progress")
                            .font(.largeTitle).fontWeight(.black)
                        Spacer()
                        Menu {
                            ForEach(store.exercises) { exercise in
                                Button(exercise.name) {
                                    selectedExerciseID = exercise.id
                                }
                            }
                        } label: {
                            Label(selectedExercise?.name ?? "Pick exercise", systemImage: "line.3.horizontal.decrease")
                        }
                        .tint(AppTheme.secondary)
                    }
                    .padding(.horizontal, 16)
                    Text("Track weight across time for each movement.")
                        .font(.callout)
                        .foregroundStyle(AppTheme.faint)
                        .padding(.horizontal, 16)

                    if let exercise = selectedExercise, !exercise.history.isEmpty {
                        ProgressChart(exercise: exercise)
                        ProgressStats(exercise: exercise)
                    } else {
                        NeonCard {
                            VStack(spacing: 8) {
                                Text("No data yet")
                                    .font(.headline)
                                Text("Add sets in a workout to unlock progress.")
                                    .foregroundStyle(AppTheme.faint)
                                    .font(.callout)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SessionSummaryCard: View {
    let workout: ActiveWorkout

    private var exerciseCount: Int {
        workout.exercises.count
    }

    private var setCount: Int {
        workout.exercises.flatMap { $0.sets }.count
    }

    private var elapsed: String {
        let seconds = Int(Date().timeIntervalSince(workout.startedAt))
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02dm %02ds", minutes, secs)
    }

    var body: some View {
        NeonCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Session Overview")
                        .font(.headline)
                    Spacer()
                    Label(elapsed, systemImage: "stopwatch")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                HStack(spacing: 12) {
                    StatTile(title: "Exercises", value: "\(exerciseCount)")
                    StatTile(title: "Sets", value: "\(setCount)")
                    StatTile(title: "Started", value: workout.startedAt.formatted(date: .omitted, time: .shortened))
                }
            }
        }
    }
}

struct RecentWorkoutsCard: View {
    let workouts: [LoggedWorkout]
    @Binding var expanded: Set<UUID>

    private var sortedWorkouts: [LoggedWorkout] {
        workouts.sorted { $0.startedAt > $1.startedAt }
    }

    var body: some View {
        NeonCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Workouts")
                    .font(.headline)

                ForEach(Array(sortedWorkouts.prefix(5))) { workout in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workout.startedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.subheadline).fontWeight(.semibold)
                                Text(durationString(workout.duration))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.faint)
                            }
                            Spacer()
                            Text("\(workout.exercises.count) exercises")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondary)
                            Button {
                                toggle(workout.id)
                            } label: {
                                Image(systemName: expanded.contains(workout.id) ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                    .foregroundStyle(AppTheme.secondary)
                            }
                        }

                        if expanded.contains(workout.id) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(workout.exercises) { wExercise in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(wExercise.exercise.name)
                                            .font(.subheadline).fontWeight(.semibold)
                                        ForEach(wExercise.sets) { set in
                                            Text("\(set.reps) reps @ \(String(format: "%.1f kg", set.weight))")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.faint)
                                        }
                                    }
                                    .padding(10)
                                    .background(AppTheme.card.opacity(0.55))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if expanded.contains(id) {
            expanded.remove(id)
        } else {
            expanded.insert(id)
        }
    }

    private func durationString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        let seconds = Int(interval) % 60
        return String(format: "%dm %02ds", minutes, seconds)
    }
}

struct ProgressChart: View {
    let exercise: Exercise

    var body: some View {
        NeonCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(exercise.name) Weight")
                    .font(.headline)
                Chart {
                    ForEach(exercise.history.sorted { $0.date < $1.date }) { set in
                        LineMark(
                            x: .value("Date", set.date),
                            y: .value("Weight", set.weight)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppTheme.accent)
                        PointMark(
                            x: .value("Date", set.date),
                            y: .value("Weight", set.weight)
                        )
                        .foregroundStyle(AppTheme.secondary)
                    }
                }
                .chartYAxisLabel("kg")
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 220)
            }
        }
    }
}

struct ProgressStats: View {
    let exercise: Exercise

    var body: some View {
        let history = exercise.history.sorted { $0.date < $1.date }
        let latest = history.last
        let best = history.max(by: { $0.weight < $1.weight })

        HStack(spacing: 12) {
            StatTile(title: "Best", value: best.map { String(format: "%.1f kg", $0.weight) } ?? "--")
            StatTile(title: "Latest", value: latest.map { String(format: "%.1f kg x %d", $0.weight, $0.reps) } ?? "--")
            StatTile(title: "Sessions", value: "\(history.count)")
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        NeonCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.caption2)
                    .foregroundStyle(AppTheme.faint)
                Text(value)
                    .font(.headline)
            }
        }
    }
}

struct ExercisePickerSheet: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    var onSelect: (Exercise) -> Void

    @State private var newName: String = ""
    @State private var selectedGroup: MuscleGroup = .chest

    private var groupedExercises: [(MuscleGroup, [Exercise])] {
        MuscleGroup.allCases
            .map { group in (group, store.exercises.filter { $0.muscleGroup == group }) }
            .filter { !$0.1.isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExercises, id: \.0) { group, exercises in
                    Section(group.rawValue) {
                        ForEach(exercises) { exercise in
                            Button {
                                onSelect(exercise)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                    Spacer()
                                    Text(exercise.latestSet?.weight ?? 0, format: .number.precision(.fractionLength(0...1)))
                                        .foregroundStyle(AppTheme.faint)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                Section("Create New") {
                    TextField("Exercise name", text: $newName)
                    Picker("Muscle group", selection: $selectedGroup) {
                        ForEach(MuscleGroup.allCases) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    Button {
                        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let created = store.addNewExercise(name: newName, muscleGroup: selectedGroup)
                        onSelect(created)
                        newName = ""
                        dismiss()
                    } label: {
                        Label("Save & Add", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct RestTimerView: View {
    @State private var seconds: Int = 90
    @State private var isRunning: Bool = false
    @State private var selectedPreset: Int = 90
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let presets: [Int] = [60, 90, 120]

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text(timeString)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.card.opacity(0.8))
                            .shadow(color: AppTheme.glow, radius: isRunning ? 14 : 0)
                    )
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: seconds)

                HStack(spacing: 10) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                selectedPreset = preset
                                seconds = preset
                                isRunning = false
                            }
                        } label: {
                            Text(presetString(preset))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selectedPreset == preset ? AppTheme.secondary.opacity(0.9) : AppTheme.card.opacity(0.7))
                                )
                                .foregroundStyle(selectedPreset == preset ? .black : AppTheme.faint)
                        }
                        .buttonStyle(PressableEffect())
                    }
                }
            }

            HStack(spacing: 12) {
                Button(isRunning ? "Pause" : "Start") {
                    isRunning.toggle()
                }
                .buttonStyle(NeonButtonStyle())

                Button("Reset") {
                    seconds = selectedPreset
                    isRunning = false
                }
                .buttonStyle(OutlineButtonStyle(tint: AppTheme.secondary))
            }
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if seconds > 0 {
                seconds -= 1
            } else {
                isRunning = false
            }
        }
    }

    private var timeString: String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func presetString(_ preset: Int) -> String {
        let minutes = preset / 60
        let secs = preset % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct NeonBackground<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            content()
                .padding(.horizontal, 0)
                .padding(.bottom, 16)
        }
    }
}

struct NeonCard<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card.opacity(0.9))
                .shadow(color: AppTheme.glow, radius: 14, x: 0, y: 0)
        )
        .padding(.horizontal, 14)
    }
}

struct NeonButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [AppTheme.secondary, AppTheme.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    var tint: Color = AppTheme.secondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(tint.opacity(configuration.isPressed ? 0.7 : 0.9), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.card.opacity(0.7))
                    )
            )
            .foregroundStyle(tint)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct PressableEffect: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

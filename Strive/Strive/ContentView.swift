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
                VStack(spacing: 0) {
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
                                .dynamicTypeSize(.xLarge)
                                .frame(maxWidth: .infinity)
                                .frame(idealHeight: 30)
                        }
                        .buttonStyle(.glassProminent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .buttonBorderShape(.roundedRectangle(radius: 12))
                        
                        
                        Button(role: .destructive) {
                            store.endWorkout()
                        } label: {
                            
                            Label("Finish Workout", systemImage: "flag.checkered")
                                .fontWeight(.semibold)
                                .dynamicTypeSize(.xLarge)
                                .frame(maxWidth: .infinity)
                                .frame(idealHeight: 30)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(AppTheme.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .buttonBorderShape(.roundedRectangle(radius: 12))
                        
                        
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
        Card {
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
                        .glassEffect(.clear.interactive())
                }
                if store.activeWorkout != nil {
                    Divider()
                    HStack(spacing: 12) {
                        Image(systemName: "ellipses.bubble")
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
        .padding(.vertical)
    }

    private var RestTimerCard: some View {
        Card {
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
        Card {
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
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: 8))
            }
        }
        .frame(height: 180)
    }
}

struct WorkoutExerciseCard: View {
    let workoutExercise: WorkoutExercise
    let addSet: (Double, Int) -> Void
    @EnvironmentObject private var store: WorkoutStore

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
        Card {
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
                    HStack(spacing: 0) {

                        Button {
                            withAnimation{
                                store.removeExerciseFromActive(id: workoutExercise.id)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.red)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showAddForm.toggle()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(showAddForm ? Color.red: AppTheme.accent)
                                .font(.title2)
                                .rotationEffect(.degrees(showAddForm ? 45 : 0))
                                .animation(Animation.easeInOut(duration: 0.3), value: showAddForm)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .dynamicTypeSize(.large)
                        
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
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(String(format: "%.1f kg", set.weight))
                                        .fontWeight(.semibold)
                                    Text("\(set.reps) reps")
                                        .foregroundStyle(AppTheme.faint)
                                }
                                Spacer()
                                Button {
                                    store.deleteSet(workoutExerciseID: workoutExercise.id, setID: set.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(AppTheme.secondary)
                                }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.circle)
                            }
                            .padding(10)
                            .background(AppTheme.card.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
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
            Button {
                onSave()
            } label: {
                Label("Log set", systemImage: "plus.circle.dashed")
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.roundedRectangle(radius: 9))
            .tint(AppTheme.accent)
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercises")
                        .font(.largeTitle).fontWeight(.black)
                        .fontDesign(.rounded)
                        .padding(.horizontal, 16)
                    Text("Sorted by muscle group.")
                        .font(.callout)
                        .foregroundStyle(AppTheme.faint)
                        .padding(.horizontal, 16)

                    Divider()
                    
                    ForEach(groupedExercises, id: \.0) { group, exercises in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.rawValue)
                                .font(.headline)
                                .padding(.top, 8)
                                .padding(.leading, 16)
                            LazyVStack(spacing: 10) {
                                ForEach(exercises) { exercise in
                                    ExerciseRow(exercise: exercise) {
                                        store.deleteExercise(exercise.id)
                                    }
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
    var onDelete: (() -> Void)?

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                    Text(exercise.muscleGroup.rawValue)
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
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
                Spacer()
                if let onDelete {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.red)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
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
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Progress")
                            .font(.largeTitle).fontWeight(.black)
                            .fontDesign(.rounded)
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
                        .tint(AppTheme.accent)
                    }
                    .padding(.horizontal, 16)
                    Text("Track weight across time for each movement.")
                        .font(.callout)
                        .foregroundStyle(AppTheme.faint)
                        .padding(.horizontal, 16)
                    Divider()
                    if let exercise = selectedExercise, !exercise.history.isEmpty {
                        ProgressChart(exercise: exercise)
                        ProgressStats(exercise: exercise)
                    } else {
                        Card {
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
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Session Overview")
                        .font(.headline)
                    Spacer()
                    Label(elapsed, systemImage: "stopwatch")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                HStack(spacing: 15) {
                    StatTile(title: "Count", value: "\(exerciseCount)")
                        .frame(maxWidth: .infinity)
                    StatTile(title: "Sets", value: "\(setCount)")
                        .frame(maxWidth: .infinity)
                    StatTile(title: "Start", value: workout.startedAt.formatted(date: .omitted, time: .shortened))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct RecentWorkoutsCard: View {
    let workouts: [LoggedWorkout]
    @Binding var expanded: Set<UUID>
    @EnvironmentObject private var store: WorkoutStore

    private var sortedWorkouts: [LoggedWorkout] {
        workouts.sorted { $0.startedAt > $1.startedAt }
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Workouts")
                    .font(.headline)

                ForEach(Array(sortedWorkouts.prefix(5))) { workout in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: -2) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workout.startedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.subheadline).fontWeight(.semibold)
                                Text(workout.exercises.count == 1 ? "1 Exercise" : "\(workout.exercises.count) Exercises")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondary)
                                .padding(.trailing, 5)
                                Text(durationString(workout.duration))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.faint)
                                
                            }
                            
                        Spacer()
                            
                            
                        Button {
                            store.deleteLoggedWorkout(id: workout.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                            
                        Button {
                            toggle(workout.id)
                        } label: {
                            Image(systemName: "chevron.down.circle.fill")
                                .rotationEffect(.degrees(expanded.contains(workout.id) ? 180 : 0))
                                .foregroundStyle(AppTheme.secondary)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        }

                        if expanded.contains(workout.id) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(workout.exercises) { wExercise in
                            VStack(alignment: .leading, spacing: -2) {
                                HStack {
                                    Text(wExercise.exercise.name)
                                        .font(.subheadline).fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.accent)
                                    Spacer()
                                    Button {
                                        store.deleteExerciseFromLogged(workoutID: workout.id, exerciseID: wExercise.id)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.glass)
                                    .buttonBorderShape(.circle)
                                }
                                ForEach(wExercise.sets) { set in
                                    Text("\(set.reps) reps @ \(String(format: "%.1f kg", set.weight))")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.faint)
                                        .padding(.vertical, 1)
                                }
                            }
                            .padding(10)
                            .background(AppTheme.card.opacity(0.55))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(radius: 2)
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
        let sorted = exercise.history.sorted { $0.date < $1.date }
        let volumeValues = sorted.map { $0.weight * Double($0.reps) }
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(exercise.name) Progress")
                    .font(.headline)
                HStack(spacing: 12) {
                    Label("Weight", systemImage: "line.diagonal.arrow")
                        .foregroundStyle(AppTheme.accent)
                        .font(.caption)
                    Label("Volume", systemImage: "chart.bar.xaxis")
                        .foregroundStyle(AppTheme.secondary)
                        .font(.caption)
                }
                ZStack {
                    Chart {
                        ForEach(sorted) { set in
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
                            .foregroundStyle(AppTheme.accent)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }

                    Chart {
                        ForEach(Array(zip(sorted, volumeValues)), id: \.0.id) { item in
                            let set = item.0
                            let volume = item.1
                            LineMark(
                                x: .value("Date", set.date),
                                y: .value("Volume", volume)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(AppTheme.secondary)
                            PointMark(
                                x: .value("Date", set.date),
                                y: .value("Volume", volume)
                            )
                            .foregroundStyle(AppTheme.secondary)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartXAxis(.hidden)
                }
                .frame(height: 240)
            }
        }
    }
}

struct ProgressStats: View {
    let exercise: Exercise

    var body: some View {
        let history = exercise.history.sorted { $0.date < $1.date }
        let best = history.max(by: { $0.weight < $1.weight })

        HStack() {
            StatTile(title: "Best", value: best.map { String(format: "%.1f kg", $0.weight) } ?? "--")
            StatTile(title: "Sessions", value: "\(history.count)")
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        Button {
        } label: {
            VStack(alignment: .center, spacing: 6) {
                Text(title.uppercased())
                    .font(.caption2)
                    .foregroundStyle(AppTheme.faint)
                Text(value)
                    .font(.headline)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.roundedRectangle(radius: 17))
        
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
                                    Text("kg")
                                        .foregroundStyle(AppTheme.faint)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                Section("Create New") {
                    TextField(text: $newName) {
                        Text("Exercise name")
                            .font(.none)
                            .fontWeight(.none)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.secondary)
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
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .navigationTitle("Add Exercise")
            }
        }
    }

struct RestTimerView: View {
    @State private var seconds: Int = 60
    @State private var isRunning: Bool = false
    @State private var selectedPreset: Int = 60
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let presets: [Int] = [30, 60, 90]

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Button {
                    
                } label: {
                    Text(timeString)
                        .frame(maxWidth: .infinity)
                        .font(.title)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.primary)
                        .padding(.vertical, 8)
                    
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.roundedRectangle(radius: 10))
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
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, selectedPreset == preset ? 8 : 10)
                                .foregroundStyle(selectedPreset == preset ? AppTheme.accent : AppTheme.faint)
                                .font(selectedPreset == preset ? .system(.title3) : .system(.caption))
                        }
                        .buttonStyle(.glass)

                        
                        .buttonBorderShape(selectedPreset == preset ? .roundedRectangle(radius: 20) : .capsule)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    isRunning.toggle()
                } label: {
                    Label(isRunning ? "Pause" : "Start" , systemImage: isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius : 10))
                .tint(isRunning ? AppTheme.secondary : AppTheme.accent)

                Button {
                    seconds = selectedPreset
                    isRunning = false
                } label: {
                    Label("Reset", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color.red)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.roundedRectangle(radius : 10))
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
    @Environment(\.colorScheme) private var colorScheme
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack {
            AppTheme.background(for: colorScheme)
                .ignoresSafeArea()
            content()
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
    }
}

struct Card<Content: View>: View {
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
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.2),
                        radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

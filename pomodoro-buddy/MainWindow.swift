import SwiftUI

struct MainWindow: View {
    @State private var selectedTab: MainWindowTab = .statistics
    @EnvironmentObject var dataManager: SessionDataManager
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(MainWindowTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.title, systemImage: tab.systemImage)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 250)
        } detail: {
            // Main content area
            Group {
                switch selectedTab {
                case .statistics:
                    StatisticsView(dataManager: dataManager)
                case .preferences:
                    PreferencesView(dataManager: dataManager)
                case .history:
                    HistoryView(dataManager: dataManager)
                case .shortcuts:
                    KeyboardShortcutsView(dataManager: dataManager)
                }
            }
            .navigationTitle(selectedTab.title)
            .navigationSplitViewColumnWidth(min: 400, ideal: 500, max: 600)
        }
        .frame(minWidth: 650, minHeight: 500)
    }
}

enum MainWindowTab: String, CaseIterable {
    case statistics = "Statistics"
    case preferences = "Preferences" 
    case history = "History"
    case shortcuts = "Shortcuts"
    
    var title: String {
        return self.rawValue
    }
    
    var systemImage: String {
        switch self {
        case .statistics:
            return "chart.bar.fill"
        case .preferences:
            return "gearshape.fill"
        case .history:
            return "calendar"
        case .shortcuts:
            return "keyboard.fill"
        }
    }
}


struct StatisticsView: View {
    @ObservedObject var dataManager: SessionDataManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Today's Stats
                GroupBox("Today") {
                    VStack(alignment: .leading, spacing: 12) {
                        let todaysStats = dataManager.getTodaysStats()
                        let goalProgress = dataManager.getDailyGoalProgress()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Completed Pomodoros")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(todaysStats.completedPomodoros)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Focus Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(dataManager.formatDuration(todaysStats.totalFocusTime))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        ProgressView(value: goalProgress.progress) {
                            Text("Daily Goal Progress (\(goalProgress.completed)/\(goalProgress.goal))")
                                .font(.caption)
                        }
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    }
                    .padding()
                }
                
                // Weekly Stats
                GroupBox("This Week") {
                    VStack(alignment: .leading, spacing: 12) {
                        let weeklyStats = dataManager.getWeeklyStats()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Pomodoros")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(weeklyStats.totalPomodoros)")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Average/Day")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f", weeklyStats.averagePerDay))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if weeklyStats.streak > 0 {
                            Text("\u{1F525} \(weeklyStats.streak) day streak")  // 🔥 fire
                                .font(.subheadline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(8)
                        } else {
                            Text("Start your streak today!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct PreferencesView: View {
    @ObservedObject var dataManager: SessionDataManager
    @State private var workDuration: Double = 25
    @State private var shortBreakDuration: Double = 5
    @State private var longBreakDuration: Double = 15
    @State private var longBreakInterval: Double = 4
    @State private var soundEnabled: Bool = true
    @State private var notificationsEnabled: Bool = true
    @State private var dailyGoal: Double = 8
    @State private var fullPomodoroMode: Bool = false
    
    var body: some View {
        Form {
            Section("Timer Mode") {
                Toggle("Full Pomodoro Timer", isOn: $fullPomodoroMode)
                Text(fullPomodoroMode ? 
                     "Automatic work-break cycles with short and long breaks" : 
                     "Simple work timer only")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Timer Settings") {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Work Duration: \(Int(workDuration)) minutes")
                            .font(.headline)
                        Slider(value: $workDuration, in: 10...90, step: 5)
                    }
                    
                    if fullPomodoroMode {
                        VStack(alignment: .leading) {
                            Text("Short Break: \(Int(shortBreakDuration)) minutes")
                                .font(.headline)
                            Slider(value: $shortBreakDuration, in: 1...15, step: 1)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Long Break: \(Int(longBreakDuration)) minutes")
                                .font(.headline)
                            Slider(value: $longBreakDuration, in: 10...45, step: 5)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Long Break Every: \(Int(longBreakInterval)) pomodoros")
                                .font(.headline)
                            Slider(value: $longBreakInterval, in: 2...8, step: 1)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Daily Goal: \(Int(dailyGoal)) pomodoros")
                            .font(.headline)
                        Slider(value: $dailyGoal, in: 1...20, step: 1)
                    }
                }
            }
            
            Section("Notifications") {
                Toggle("Enable Sound", isOn: $soundEnabled)
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            // Load current settings
            workDuration = Double(dataManager.settings.workDuration)
            shortBreakDuration = Double(dataManager.settings.shortBreakDuration)
            longBreakDuration = Double(dataManager.settings.longBreakDuration)
            longBreakInterval = Double(dataManager.settings.longBreakInterval)
            soundEnabled = dataManager.settings.soundEnabled
            notificationsEnabled = dataManager.settings.notificationsEnabled
            dailyGoal = Double(dataManager.settings.dailyGoal)
            fullPomodoroMode = dataManager.settings.fullPomodoroMode
        }
        .onChange(of: workDuration) { saveSettings() }
        .onChange(of: shortBreakDuration) { saveSettings() }
        .onChange(of: longBreakDuration) { saveSettings() }
        .onChange(of: longBreakInterval) { saveSettings() }
        .onChange(of: soundEnabled) { saveSettings() }
        .onChange(of: notificationsEnabled) { saveSettings() }
        .onChange(of: dailyGoal) { saveSettings() }
        .onChange(of: fullPomodoroMode) { saveSettings() }
    }
    
    private func saveSettings() {
        let newSettings = UserSettings(
            workDuration: Int(workDuration),
            shortBreakDuration: Int(shortBreakDuration),
            longBreakDuration: Int(longBreakDuration),
            longBreakInterval: Int(longBreakInterval),
            soundEnabled: soundEnabled,
            notificationsEnabled: notificationsEnabled,
            dailyGoal: Int(dailyGoal),
            fullPomodoroMode: fullPomodoroMode
        )
        dataManager.updateSettings(newSettings)
    }
}

struct HistoryView: View {
    @ObservedObject var dataManager: SessionDataManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Session History")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom)
            
            let sessionHistory = dataManager.getSessionHistory()
            
            if sessionHistory.isEmpty {
                VStack {
                    Spacer()
                    Text("No sessions yet")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Complete your first pomodoro to see your history here!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(sessionHistory, id: \.date) { dayData in
                        let workSessions = dayData.sessions.filter { $0.sessionType == SessionType.work }
                        let totalTime = workSessions.reduce(0) { $0 + $1.duration }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text(dayData.date, style: .date)
                                    .font(.headline)
                                Text("\(workSessions.count) pomodoros completed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(dataManager.formatDuration(totalTime))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(InsetListStyle())
            }
        }
        .padding()
    }
}

struct KeyboardShortcutsView: View {
    @ObservedObject var dataManager: SessionDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Configure global keyboard shortcuts to control Pomodoro Buddy from anywhere on your system.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                // Start/Pause shortcut
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start/Pause Timer")
                            .font(.headline)
                        Text("Global shortcut for start/pause timer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("⌘⇧P")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                        .font(.system(size: 13, design: .monospaced))
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                // Reset shortcut
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reset Timer")
                            .font(.headline)
                        Text("Global shortcut for reset timer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("⌘⇧R")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                        .font(.system(size: 13, design: .monospaced))
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                // Statistics shortcut
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Show Statistics")
                            .font(.headline)
                        Text("Global shortcut for show statistics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("⌘⇧S")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                        .font(.system(size: 13, design: .monospaced))
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Shortcuts work globally when the app is running")
                    Text("• Use ⌘ (Command) key combinations for system-wide access")
                    Text("• These shortcuts work even when the app is minimized")
                    Text("• Avoid common shortcuts like ⌘C, ⌘V to prevent conflicts")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
}


#Preview {
    MainWindow()
        .frame(width: 650, height: 500)
}
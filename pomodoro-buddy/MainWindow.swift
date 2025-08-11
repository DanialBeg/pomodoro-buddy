import SwiftUI
import AppKit

struct MainWindow: View {
    @State private var selectedTab: MainWindowTab = .statistics
    @EnvironmentObject var dataManager: SessionDataManager
    
    var body: some View {
        HStack(spacing: 0) {
            // Modern Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // Sidebar Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pomodoro Buddy")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("Focus & Productivity")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Navigation Items
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(MainWindowTab.allCases, id: \.self) { tab in
                        HStack(spacing: 12) {
                            // Icon with background circle
                            ZStack {
                                Circle()
                                    .fill(selectedTab == tab ? Color.accentColor : Color.gray.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: tab.systemImage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedTab == tab ? .white : .primary)
                            }
                            
                            Text(tab.title)
                                .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedTab == tab ? .primary : .secondary)
                            
                            Spacer()
                            
                            // Selection indicator
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.accentColor)
                                    .frame(width: 3, height: 16)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTab == tab ? Color.accentColor.opacity(0.08) : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTab = tab
                        }
                        .padding(.horizontal, 8)
                    }
                }
                
                Spacer()
                
                // Footer
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Stay Focused")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Build better habits")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("🍅")
                            .font(.title3)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .frame(minWidth: 220, idealWidth: 240, maxWidth: 260)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(.controlBackgroundColor).opacity(0.5))
            )
            
            Divider()
            
            // Main content area
            VStack {
                HStack {
                    Text(selectedTab.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding()
                
                destinationView(for: selectedTab)
            }
            .frame(minWidth: 400, idealWidth: 500, maxWidth: 600)
        }
        .frame(minWidth: 650, minHeight: 500)
    }
    
    @ViewBuilder
    private func destinationView(for tab: MainWindowTab) -> some View {
        switch tab {
        case .statistics:
            StatisticsView(dataManager: dataManager)
        case .goals:
            GoalsView(dataManager: dataManager)
        case .preferences:
            PreferencesView(dataManager: dataManager)
        case .history:
            HistoryView(dataManager: dataManager)
        case .shortcuts:
            KeyboardShortcutsView(dataManager: dataManager)
        }
    }
}

enum MainWindowTab: String, CaseIterable {
    case statistics = "Statistics"
    case goals = "Goals"
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
        case .goals:
            return "target"
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today")
                        .font(.headline)
                        .padding(.bottom, 4)
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
                        .progressViewStyle(LinearProgressViewStyle())
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Weekly Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Session Breakdown")
                        .font(.headline)
                        .padding(.bottom, 4)
                    VStack(alignment: .leading, spacing: 16) {
                        let weeklyBreakdown = dataManager.getWeeklySessionBreakdown()
                        let weeklyStats = dataManager.getWeeklyStats()
                        
                        // Summary row
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total This Week")
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
                        .padding(.bottom, 8)
                        
                        // Weekly grid
                        VStack(spacing: 8) {
                            ForEach(weeklyBreakdown, id: \.date) { dayData in
                                WeeklyDayRow(dayData: dayData, dataManager: dataManager)
                            }
                        }
                        
                        if weeklyStats.streak > 0 {
                            HStack {
                                Spacer()
                                Text("\u{1F525} \(weeklyStats.streak) day streak")  // 🔥 fire
                                    .font(.subheadline)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(8)
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Legend
                VStack(alignment: .leading, spacing: 12) {
                    Text("Legend")
                        .font(.headline)
                        .padding(.bottom, 4)
                    HStack(spacing: 20) {
                        // Work session
                        HStack(spacing: 4) {
                            Text("\u{1F345}")  // 🍅
                                .font(.system(size: 14))
                            Text("Work Sessions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Short break
                        HStack(spacing: 4) {
                            Text("\u{2615}")  // ☕
                                .font(.system(size: 14))
                            Text("Short Breaks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Long break
                        HStack(spacing: 4) {
                            Text("\u{1F31F}")  // 🌟
                                .font(.system(size: 14))
                            Text("Long Breaks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}


struct WeeklyDayRow: View {
    let dayData: SessionDataManager.DailySessionBreakdown
    let dataManager: SessionDataManager
    
    var body: some View {
        HStack {
            // Day name
            VStack(alignment: .leading) {
                Text(dayData.dayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(dayData.isToday ? .accentColor : .primary)
                if dayData.isToday {
                    Text("Today")
                        .font(.system(size: 9))
                        .foregroundColor(.accentColor)
                        .padding(.top, -2)
                }
            }
            .frame(width: 45, alignment: .leading)
            
            Spacer()
            
            // Session indicators
            HStack(spacing: 4) {
                // Work sessions (tomatoes)
                if dayData.workSessions > 0 {
                    HStack(spacing: 2) {
                        Text("\u{1F345}")  // 🍅
                            .font(.system(size: 12))
                        Text("\(dayData.workSessions)")
                            .font(.system(size: 11, weight: .medium))
                    }
                } else {
                    HStack(spacing: 2) {
                        Text("\u{1F345}")  // 🍅
                            .font(.system(size: 12))
                            .opacity(0.3)
                        Text("0")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("•")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                
                // Short breaks
                if dayData.shortBreaks > 0 {
                    HStack(spacing: 2) {
                        Text("\u{2615}")  // ☕
                            .font(.system(size: 12))
                        Text("\(dayData.shortBreaks)")
                            .font(.system(size: 11, weight: .medium))
                    }
                } else {
                    HStack(spacing: 2) {
                        Text("\u{2615}")  // ☕
                            .font(.system(size: 12))
                            .opacity(0.3)
                        Text("0")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("•")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                
                // Long breaks
                if dayData.longBreaks > 0 {
                    HStack(spacing: 2) {
                        Text("\u{1F31F}")  // 🌟
                            .font(.system(size: 12))
                        Text("\(dayData.longBreaks)")
                            .font(.system(size: 11, weight: .medium))
                    }
                } else {
                    HStack(spacing: 2) {
                        Text("\u{1F31F}")  // 🌟
                            .font(.system(size: 12))
                            .opacity(0.3)
                        Text("0")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Total focus time
            VStack(alignment: .trailing) {
                Text(dataManager.formatDuration(dayData.totalFocusTime))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(dayData.totalFocusTime > 0 ? .primary : .secondary)
            }
            .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(dayData.isToday ? Color.accentColor.opacity(0.1) : Color.clear)
        )
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


struct GoalsView: View {
    @ObservedObject var dataManager: SessionDataManager
    @State private var showingGoalEditor = false
    @State private var newGoalText = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Current Goal Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Goal")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Target")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                let dailyGoal = dataManager.getDailyGoal()
                                Text("\(dailyGoal > 0 ? dailyGoal : 8)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.accentColor)
                                Text("🍅 per day")
                                    .font(.title2)
                            }
                        }
                        
                        Spacer()
                        
                        Button("Edit Goal") {
                            let currentGoal = dataManager.getDailyGoal()
                            newGoalText = currentGoal > 0 ? String(currentGoal) : "8"
                            showingGoalEditor = true
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Today's Progress
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Progress")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    let goalProgress = dataManager.getDailyGoalProgress()
                    let todaysStats = dataManager.getTodaysStats()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Completed: \(goalProgress.completed) / \(goalProgress.goal)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(goalProgress.progress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                        }
                        
                        ProgressView(value: goalProgress.progress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Focus Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(dataManager.formatDuration(todaysStats.totalFocusTime))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            if goalProgress.completed >= goalProgress.goal {
                                Text("🎉 Goal Achieved!")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            } else {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Remaining")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(goalProgress.goal - goalProgress.completed) sessions")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Tips Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goal Setting Tips")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("💡")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start Small")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Begin with 4-6 pomodoros daily")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("📅")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Be Consistent")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Daily practice beats long sessions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("💪")
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Gradual Increase")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Add 1-2 sessions weekly as you improve")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingGoalEditor) {
            VStack(spacing: 24) {
                Text("Set Daily Goal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Text("How many pomodoros do you want to complete each day?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(spacing: 12) {
                        Text("Select your daily goal:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                if let currentGoal = Int(newGoalText), currentGoal > 1 {
                                    newGoalText = String(currentGoal - 1)
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Text("-")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Circle())
                            .disabled(Int(newGoalText) == nil || Int(newGoalText)! <= 1)
                            
                            Text(newGoalText)
                                .font(.title)
                                .fontWeight(.semibold)
                                .frame(minWidth: 80)
                                .foregroundColor(.accentColor)
                            
                            Button(action: {
                                if let currentGoal = Int(newGoalText), currentGoal < 20 {
                                    newGoalText = String(currentGoal + 1)
                                } else if Int(newGoalText) == nil {
                                    newGoalText = "8"
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Text("+")
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Circle())
                            .disabled(Int(newGoalText) != nil && Int(newGoalText)! >= 20)
                        }
                        
                        Text("pomodoros per day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        showingGoalEditor = false
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                    
                    Button("Save") {
                        if let goalValue = Int(newGoalText), goalValue > 0 {
                            dataManager.updateDailyGoal(goalValue)
                            showingGoalEditor = false
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(Int(newGoalText) == nil || Int(newGoalText)! <= 0)
                }
                
                Spacer()
            }
            .padding(24)
            .frame(width: 450, height: 300)
        }
    }
}


#Preview {
    MainWindow()
        .frame(width: 650, height: 500)
}
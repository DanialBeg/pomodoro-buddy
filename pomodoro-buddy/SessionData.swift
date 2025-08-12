import Foundation

extension Notification.Name {
    static let pomodoroSettingsChanged = Notification.Name("pomodoroSettingsChanged")
}

// MARK: - Session Types
enum SessionType: String, Codable, CaseIterable {
    case work = "work"
    case shortBreak = "shortBreak"
    case longBreak = "longBreak"
    
    var displayName: String {
        switch self {
        case .work: return "Work"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
    
    var emoji: String {
        switch self {
        case .work: return "\u{1F345}"        // 🍅 tomato
        case .shortBreak: return "\u{2615}"   // ☕ coffee
        case .longBreak: return "\u{1F31F}"   // 🌟 star
        }
    }
}

// MARK: - Data Models
struct PomodoroSession: Codable, Identifiable {
    var id = UUID()
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval // in seconds
    let sessionType: SessionType
    let isCompleted: Bool
}

// MARK: - Keyboard Shortcuts
struct KeyboardShortcut: Codable, Identifiable {
    var id = UUID()
    let action: ShortcutAction
    var modifiers: [String]
    var key: String
    var isEnabled: Bool
    
    init(action: ShortcutAction, modifiers: [String] = ["cmd", "shift"], key: String, isEnabled: Bool = true) {
        self.action = action
        self.modifiers = modifiers
        self.key = key
        self.isEnabled = isEnabled
    }
    
    enum ShortcutAction: String, Codable, CaseIterable {
        case startPause = "startPause"
        case reset = "reset"
        case showStatistics = "showStatistics"
        
        var displayName: String {
            switch self {
            case .startPause: return "Start/Pause Timer"
            case .reset: return "Reset Timer"
            case .showStatistics: return "Show Statistics"
            }
        }
        
        var defaultKey: String {
            switch self {
            case .startPause: return "P"
            case .reset: return "R"
            case .showStatistics: return "S"
            }
        }
    }
    
    var displayString: String {
        var result = ""
        if modifiers.contains("cmd") { result += "⌘" }
        if modifiers.contains("shift") { result += "⇧" }
        if modifiers.contains("option") { result += "⌥" }
        if modifiers.contains("control") { result += "⌃" }
        result += key.uppercased()
        return result
    }
}

struct UserSettings: Codable {
    var workDuration: Int = 25 // minutes
    var shortBreakDuration: Int = 5 // minutes
    var longBreakDuration: Int = 15 // minutes
    var longBreakInterval: Int = 4 // every N pomodoros
    var soundEnabled: Bool = true
    var notificationsEnabled: Bool = true
    var dailyGoal: Int = 8 // pomodoros per day
    var fullPomodoroMode: Bool = false // false = work timer only, true = full cycle
    var keyboardShortcuts: [KeyboardShortcut]
    
    init() {
        // Initialize with default shortcuts
        self.keyboardShortcuts = KeyboardShortcut.ShortcutAction.allCases.map { action in
            KeyboardShortcut(action: action, key: action.defaultKey)
        }
    }
    
    init(workDuration: Int, shortBreakDuration: Int, longBreakDuration: Int, 
         longBreakInterval: Int, soundEnabled: Bool, notificationsEnabled: Bool,
         dailyGoal: Int, fullPomodoroMode: Bool) {
        self.workDuration = workDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.longBreakInterval = longBreakInterval
        self.soundEnabled = soundEnabled
        self.notificationsEnabled = notificationsEnabled
        self.dailyGoal = dailyGoal
        self.fullPomodoroMode = fullPomodoroMode
        // Initialize with default shortcuts
        self.keyboardShortcuts = KeyboardShortcut.ShortcutAction.allCases.map { action in
            KeyboardShortcut(action: action, key: action.defaultKey)
        }
    }
}

// MARK: - Data Manager
class SessionDataManager: ObservableObject {
    @Published var sessions: [PomodoroSession] = []
    @Published var settings: UserSettings = UserSettings()
    
    private let sessionsKey = "PomodoroSessions"
    private let settingsKey = "PomodoroSettings"
    
    init() {
        loadData()
    }
    
    // MARK: - Session Management
    func addSession(_ session: PomodoroSession) {
        sessions.append(session)
        saveData()
    }
    
    func saveCurrentSession(startTime: Date, duration: TimeInterval, sessionType: SessionType, isCompleted: Bool) {
        let session = PomodoroSession(
            startTime: startTime,
            endTime: Date(),
            duration: duration,
            sessionType: sessionType,
            isCompleted: isCompleted
        )
        addSession(session)
    }
    
    // MARK: - Goal Management
    func updateDailyGoal(_ newGoal: Int) {
        settings.dailyGoal = max(1, newGoal) // Ensure minimum of 1
        saveData()
        NotificationCenter.default.post(name: .pomodoroSettingsChanged, object: nil)
    }
    
    func getDailyGoal() -> Int {
        return settings.dailyGoal
    }
    
    // MARK: - Statistics
    func getTodaysStats() -> (completedPomodoros: Int, totalFocusTime: TimeInterval) {
        let today = Calendar.current.startOfDay(for: Date())
        let todaysSessions = sessions.filter { session in
            Calendar.current.isDate(session.startTime, inSameDayAs: today) &&
            session.sessionType == SessionType.work &&
            session.isCompleted
        }
        
        let completedPomodoros = todaysSessions.count
        let totalFocusTime = todaysSessions.reduce(0) { $0 + $1.duration }
        
        return (completedPomodoros, totalFocusTime)
    }
    
    func getWeeklyStats() -> (totalPomodoros: Int, averagePerDay: Double, streak: Int) {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        
        let weeklySessions = sessions.filter { session in
            session.startTime >= weekAgo &&
            session.sessionType == SessionType.work &&
            session.isCompleted
        }
        
        let totalPomodoros = weeklySessions.count
        let averagePerDay = Double(totalPomodoros) / 7.0
        let streak = calculateStreak()
        
        return (totalPomodoros, averagePerDay, streak)
    }
    
    struct DailySessionBreakdown {
        let date: Date
        let dayName: String
        let workSessions: Int
        let shortBreaks: Int
        let longBreaks: Int
        let totalFocusTime: TimeInterval
        let isToday: Bool
    }
    
    func getWeeklySessionBreakdown() -> [DailySessionBreakdown] {
        let calendar = Calendar.current
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)
        
        var weekDays: [DailySessionBreakdown] = []
        
        // Get the last 7 days (including today)
        for i in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: -i, to: todayStart) else { continue }
            
            let daySessions = sessions.filter { session in
                calendar.isDate(session.startTime, inSameDayAs: dayDate) && session.isCompleted
            }
            
            let workSessions = daySessions.filter { $0.sessionType == .work }
            let shortBreaks = daySessions.filter { $0.sessionType == .shortBreak }
            let longBreaks = daySessions.filter { $0.sessionType == .longBreak }
            let totalFocusTime = workSessions.reduce(0) { $0 + $1.duration }
            
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"
            let dayName = dayFormatter.string(from: dayDate)
            
            let breakdown = DailySessionBreakdown(
                date: dayDate,
                dayName: dayName,
                workSessions: workSessions.count,
                shortBreaks: shortBreaks.count,
                longBreaks: longBreaks.count,
                totalFocusTime: totalFocusTime,
                isToday: calendar.isDate(dayDate, inSameDayAs: today)
            )
            
            weekDays.append(breakdown)
        }
        
        // Return in chronological order (oldest first)
        return weekDays.reversed()
    }
    
    func getSessionHistory() -> [(date: Date, sessions: [PomodoroSession])] {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let groupedSessions = Dictionary(grouping: sessions.filter { session in
            session.isCompleted && session.startTime >= oneWeekAgo
        }) { session in
            calendar.startOfDay(for: session.startTime)
        }
        
        return groupedSessions.map { (date: $0.key, sessions: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        while true {
            let daysSessions = sessions.filter { session in
                calendar.isDate(session.startTime, inSameDayAs: currentDate) &&
                session.sessionType == SessionType.work &&
                session.isCompleted
            }
            
            if daysSessions.isEmpty {
                break
            }
            
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }
        
        return streak
    }
    
    func getDailyGoalProgress() -> (completed: Int, goal: Int, progress: Double) {
        let todaysStats = getTodaysStats()
        let progress = min(1.0, Double(todaysStats.completedPomodoros) / Double(settings.dailyGoal))
        return (todaysStats.completedPomodoros, settings.dailyGoal, progress)
    }
    
    // MARK: - Settings Management
    func updateSettings(_ newSettings: UserSettings) {
        settings = newSettings
        saveData()
        
        // Notify that settings changed
        NotificationCenter.default.post(name: .pomodoroSettingsChanged, object: newSettings)
    }
    
    // MARK: - Keyboard Shortcuts Management
    func updateKeyboardShortcut(_ shortcut: KeyboardShortcut) {
        if let index = settings.keyboardShortcuts.firstIndex(where: { $0.action == shortcut.action }) {
            settings.keyboardShortcuts[index] = shortcut
            saveData()
            
            // Notify that shortcuts changed
            NotificationCenter.default.post(name: .pomodoroSettingsChanged, object: settings)
        }
    }
    
    func getKeyboardShortcut(for action: KeyboardShortcut.ShortcutAction) -> KeyboardShortcut? {
        return settings.keyboardShortcuts.first { $0.action == action }
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        // Load sessions
        if let sessionsData = UserDefaults.standard.data(forKey: sessionsKey),
           let decodedSessions = try? JSONDecoder().decode([PomodoroSession].self, from: sessionsData) {
            sessions = decodedSessions
        }
        
        // Load settings
        if let settingsData = UserDefaults.standard.data(forKey: settingsKey),
           let decodedSettings = try? JSONDecoder().decode(UserSettings.self, from: settingsData) {
            settings = decodedSettings
            
            // Migration: Add default keyboard shortcuts if they don't exist
            if settings.keyboardShortcuts.isEmpty {
                settings.keyboardShortcuts = KeyboardShortcut.ShortcutAction.allCases.map { action in
                    KeyboardShortcut(action: action, key: action.defaultKey)
                }
                saveData() // Save the migrated settings
            }
        }
    }
    
    private func saveData() {
        // Save sessions
        if let encodedSessions = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encodedSessions, forKey: sessionsKey)
        }
        
        // Save settings
        if let encodedSettings = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encodedSettings, forKey: settingsKey)
        }
    }
    
    // MARK: - Utility
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

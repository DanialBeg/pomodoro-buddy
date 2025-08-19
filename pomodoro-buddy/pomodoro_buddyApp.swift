//
//  pomodoro_buddyApp.swift
//  pomodoro-buddy
//
//  Created by Danial Beg on 7/5/25.
//

import SwiftUI
import AppKit
import UserNotifications
import ServiceManagement

@main
struct pomodoro_buddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @StateObject private var sharedDataManager = SessionDataManager()
    
    var body: some Scene {
        Settings {
            PreferencesView(dataManager: AppDelegate.sharedDataManager ?? sharedDataManager)
                .frame(minWidth: 500, minHeight: 400)
                .onAppear {
                    // Ensure we use the same data manager instance
                    if AppDelegate.sharedDataManager == nil {
                        AppDelegate.sharedDataManager = sharedDataManager
                    } else {
                        // Sync our local data manager with the shared one
                        sharedDataManager.settings = AppDelegate.sharedDataManager!.settings
                        sharedDataManager.sessions = AppDelegate.sharedDataManager!.sessions
                    }
                }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var sharedDataManager: SessionDataManager?
    
    var statusItem: NSStatusItem?
    var pomodoroTimer: PomodoroTimer?
    var mainWindow: NSWindow?
    var dataManager: SessionDataManager? {
        return AppDelegate.sharedDataManager
    }
    var sessionStartTime: Date?
    var keyboardShortcutManager: KeyboardShortcutManager?
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        // Set up app delegate to handle window closing properly
        NSApp.delegate = self
        
        // Initialize shared data manager if not already done
        if AppDelegate.sharedDataManager == nil {
            AppDelegate.sharedDataManager = SessionDataManager()
        }
        
        setupMenuBar()
        setupNotifications()
        setupLaunchAtLogin()
        
        pomodoroTimer = PomodoroTimer()
        pomodoroTimer?.delegate = self
        
        // Apply saved settings to timer
        if let settings = dataManager?.settings {
            pomodoroTimer?.configureTimer(settings: settings)
        }
        
        // Set up keyboard shortcuts
        keyboardShortcutManager = KeyboardShortcutManager()
        keyboardShortcutManager?.delegate = self
        
        // Register initial keyboard shortcuts
        if let settings = dataManager?.settings {
            let shortcuts = settings.keyboardShortcuts.map { shortcut in
                (action: shortcut.action.rawValue, modifiers: shortcut.modifiers, key: shortcut.key, isEnabled: shortcut.isEnabled)
            }
            keyboardShortcutManager?.registerHotKeys(shortcuts: shortcuts)
        }
        
        // Listen for settings changes
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(settingsDidChange(_:)), 
            name: .pomodoroSettingsChanged, 
            object: nil
        )
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanup()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Never quit when last window closes - this is a menu bar app
        NSApp.setActivationPolicy(.accessory) // Ensure we stay in accessory mode
        return false
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Only allow termination if explicitly requested (via Quit menu)
        return .terminateNow
    }
    
    private func setupLaunchAtLogin() {
        // Launch at login is now controlled by user preference only
        // No automatic enabling without user consent
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "🍅"  // 🍅 tomato
            button.action = #selector(toggleMenu)
            button.target = self
        }
        
        updateMenuBarTitle()
        setupMenu()
    }
    
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            _ = error
        }
    }
    
    private func updateMenuBarTitle() {
        guard let button = statusItem?.button else { return }
        
        if let timer = pomodoroTimer {
            if timer.isRunning || timer.isPaused {
                let minutes = timer.timeRemaining / 60
                let seconds = timer.timeRemaining % 60
                let timeString = String(format: "%02d:%02d", minutes, seconds)
                
                // In full Pomodoro mode, show session type and progress
                guard let settings = dataManager?.settings else {
                    button.title = timeString
                    button.needsDisplay = true
                    return
                }
                
                if settings.fullPomodoroMode {
                    let sessionInfo = timer.getCurrentSessionInfo()
                    let emoji = sessionInfo.type.emoji
                    button.title = "\(emoji) \(timeString)"
                } else {
                    button.title = timeString
                }
                
                button.needsDisplay = true
            } else {
                // Show current session type when not running
                guard let settings = dataManager?.settings, settings.fullPomodoroMode else {
                    button.title = "🍅"  // 🍅 tomato
                    return
                }
                
                let sessionInfo = pomodoroTimer?.getCurrentSessionInfo()
                button.title = sessionInfo?.type.emoji ?? "🍅"  // 🍅 tomato
            }
        }
    }
    
    @objc private func toggleMenu() {
        statusItem?.button?.performClick(nil)
    }
    
    private func setupMenu() {
        // Clean up existing menu to prevent memory leaks
        statusItem?.menu?.removeAllItems()
        
        let menu = NSMenu()
        
        // Show current session info and daily progress
        if let settings = dataManager?.settings, let timer = pomodoroTimer {
            if settings.fullPomodoroMode {
                let sessionInfo = timer.getCurrentSessionInfo()
                let sessionTitle = "\(sessionInfo.type.emoji) \(sessionInfo.type.displayName)"
                menu.addItem(NSMenuItem(title: sessionTitle, action: nil, keyEquivalent: ""))
            }
            
            // Always show daily progress (only calculated when menu is opened)
            if let dailyProgress = dataManager?.getDailyGoalProgress() {
                let progressTitle = "Daily Progress: \(dailyProgress.completed)/\(dailyProgress.goal)"
                menu.addItem(NSMenuItem(title: progressTitle, action: nil, keyEquivalent: ""))
            }
            menu.addItem(NSMenuItem.separator())
        }
        
        // Dynamic start/pause button
        let startPauseTitle = pomodoroTimer?.isRunning == true ? "Pause Timer" : "Start Timer"
        menu.addItem(NSMenuItem(title: startPauseTitle, action: #selector(toggleStartPause), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Reset Timer", action: #selector(resetTimer), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        
        // Statistics window
        menu.addItem(NSMenuItem(title: "Statistics", action: #selector(showStatistics), keyEquivalent: ""))
        
        // Create slider for custom time
        let sliderItem = createCustomTimeSliderItem()
        menu.addItem(sliderItem)
        menu.addItem(NSMenuItem.separator())
        
        // Create custom view for Launch at Login to prevent menu auto-close
        let launchAtLoginItem = createLaunchAtLoginItem()
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func createCustomTimeSliderItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        menuItem.title = ""
        
        // Create container view with more height for tick marks
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 100))
        
        // Create label
        let label = NSTextField(labelWithString: "Timer Duration")
        label.frame = NSRect(x: 10, y: 70, width: 230, height: 20)
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        containerView.addSubview(label)
        
        // Create time display
        let currentMinutes = (pomodoroTimer?.totalTime ?? 1500) / 60
        let timeLabel = NSTextField(labelWithString: "\(currentMinutes) minutes")
        timeLabel.frame = NSRect(x: 10, y: 50, width: 230, height: 20)
        timeLabel.alignment = .center
        timeLabel.font = NSFont.systemFont(ofSize: 11)
        timeLabel.textColor = .secondaryLabelColor
        containerView.addSubview(timeLabel)
        
        // Create slider
        let slider = NSSlider(frame: NSRect(x: 15, y: 30, width: 220, height: 20))
        slider.minValue = 0
        slider.maxValue = 7 // 8 positions (0-7) for uniform spacing
        
        // Find the closest snap point and set slider to its uniform position
        let snapPoints = [10, 15, 20, 25, 30, 45, 50, 60]
        let closestIndex = snapPoints.enumerated().min { abs($0.1 - currentMinutes) < abs($1.1 - currentMinutes) }?.0 ?? 2
        slider.doubleValue = Double(closestIndex)
        
        slider.target = self
        slider.action = #selector(sliderValueChanged(_:))
        slider.numberOfTickMarks = 0 // We'll draw custom tick marks
        
        containerView.addSubview(slider)
        
        // Add tick marks and labels for common intervals
        addTickMarks(to: containerView, sliderFrame: slider.frame)
        
        // Store references for updates
        slider.identifier = NSUserInterfaceItemIdentifier("timeSlider")
        timeLabel.identifier = NSUserInterfaceItemIdentifier("timeLabel")
        
        menuItem.view = containerView
        return menuItem
    }
    
    private func createLaunchAtLoginItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        menuItem.title = ""
        
        // Create container view
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 30))
        
        // Create checkbox button
        let checkbox = NSButton(frame: NSRect(x: 15, y: 5, width: 220, height: 20))
        checkbox.setButtonType(.switch)
        checkbox.title = "Launch at Login"
        checkbox.state = isLaunchAtLoginEnabled() ? .on : .off
        checkbox.target = self
        checkbox.action = #selector(launchAtLoginCheckboxToggled(_:))
        
        containerView.addSubview(checkbox)
        menuItem.view = containerView
        
        return menuItem
    }
    
    @objc private func launchAtLoginCheckboxToggled(_ sender: NSButton) {
        if sender.state == .on {
            enableLaunchAtLogin()
        } else {
            disableLaunchAtLogin()
        }
        
        // Update checkbox state to reflect actual system state
        sender.state = isLaunchAtLoginEnabled() ? .on : .off
    }
    
    private func addTickMarks(to containerView: NSView, sliderFrame: NSRect) {
        let snapPoints = [10, 15, 20, 25, 30, 45, 50, 60]
        let sliderStart = sliderFrame.minX
        let sliderWidth = sliderFrame.width
        
        // Calculate uniform spacing between tick marks
        let numberOfIntervals = snapPoints.count - 1
        let intervalWidth = sliderWidth / Double(numberOfIntervals)
        
        for (index, snapPoint) in snapPoints.enumerated() {
            // Calculate uniform position along slider
            let xPosition = sliderStart + (Double(index) * intervalWidth)
            
            // Create tick mark line
            let tickMark = NSView(frame: NSRect(x: xPosition - 0.5, y: sliderFrame.minY - 8, width: 1, height: 6))
            tickMark.wantsLayer = true
            tickMark.layer?.backgroundColor = NSColor.tertiaryLabelColor.cgColor
            containerView.addSubview(tickMark)
            
            // Create number label
            let numberLabel = NSTextField(labelWithString: "\(snapPoint)")
            numberLabel.frame = NSRect(x: xPosition - 10, y: sliderFrame.minY - 20, width: 20, height: 12)
            numberLabel.alignment = .center
            numberLabel.font = NSFont.systemFont(ofSize: 9)
            numberLabel.textColor = .tertiaryLabelColor
            numberLabel.backgroundColor = .clear
            numberLabel.isBordered = false
            numberLabel.isEditable = false
            numberLabel.isSelectable = false
            containerView.addSubview(numberLabel)
        }
    }
    
    
    @objc private func toggleStartPause() {
        guard let timer = pomodoroTimer else { return }
        
        if timer.isRunning {
            pomodoroTimer?.pause()
        } else {
            // Track session start time
            sessionStartTime = Date()
            pomodoroTimer?.start()
        }
        
        // Update menu to reflect new state
        setupMenu()
    }
    
    @objc private func resetTimer() {
        pomodoroTimer?.reset()
        sessionStartTime = nil
        setupMenu() // Update menu to show "Start Timer"
    }
    
    @objc private func sliderValueChanged(_ sender: NSSlider) {
        let sliderValue = sender.doubleValue
        
        // Define time choices with uniform spacing
        let snapPoints = [10, 15, 20, 25, 30, 45, 50, 60]
        let sliderMin = sender.minValue
        let sliderMax = sender.maxValue
        let sliderRange = sliderMax - sliderMin
        
        // Calculate which segment the slider is in (uniform spacing)
        let segmentSize = sliderRange / Double(snapPoints.count - 1)
        let segmentIndex = Int(round((sliderValue - sliderMin) / segmentSize))
        let clampedIndex = max(0, min(segmentIndex, snapPoints.count - 1))
        
        let snappedValue = snapPoints[clampedIndex]
        
        // Calculate the position for this snap point in uniform spacing
        let uniformPosition = sliderMin + (Double(clampedIndex) * segmentSize)
        
        // Update slider to uniform position
        sender.doubleValue = uniformPosition
        
        // Update timer
        pomodoroTimer?.setCustomTime(minutes: snappedValue)
        
        // Update time label
        updateTimeLabel(minutes: snappedValue)
    }
    
    private func updateTimeLabel(minutes: Int) {
        guard let menu = statusItem?.menu else { return }
        
        // Find the slider menu item and update its time label
        for item in menu.items {
            if let containerView = item.view {
                for subview in containerView.subviews {
                    if let label = subview as? NSTextField,
                       label.identifier?.rawValue == "timeLabel" {
                        label.stringValue = "\(minutes) minutes"
                        break
                    }
                }
            }
        }
    }
    
    
    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // For macOS 11.0-12.x, we'll maintain state locally since SMAppService isn't available
            // and the deprecated SMCopyAllJobDictionaries produces warnings
            return UserDefaults.standard.bool(forKey: "LaunchAtLogin")
        }
    }
    
    func enableLaunchAtLogin() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
            } catch {
                print("Failed to enable launch at login: \(error)")
            }
        } else {
            // For macOS 11.0-12.x, use the legacy SMLoginItemSetEnabled API
            let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, true)
            // Store the state locally for UI consistency
            UserDefaults.standard.set(success, forKey: "LaunchAtLogin")
        }
    }
    
    func disableLaunchAtLogin() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                print("Failed to disable launch at login: \(error)")
            }
        } else {
            // For macOS 11.0-12.x, use the legacy SMLoginItemSetEnabled API
            let success = SMLoginItemSetEnabled(bundleIdentifier as CFString, false)
            // Store the state locally for UI consistency
            UserDefaults.standard.set(!success, forKey: "LaunchAtLogin")
        }
    }
    
    @objc private func showStatistics() {
        DispatchQueue.main.async { [weak self] in
            if self?.mainWindow == nil {
                self?.createMainWindow()
            }
            
            self?.mainWindow?.makeKeyAndOrderFront(nil)
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func createMainWindow() {
        guard let dataManager = dataManager else { return }
        let contentView = MainWindow().environmentObject(dataManager)
        
        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        mainWindow?.title = "Pomodoro Buddy"
        mainWindow?.contentView = NSHostingView(rootView: contentView)
        mainWindow?.center()
        mainWindow?.setFrameAutosaveName("MainWindow")
        
        // Prevent the window from quitting the app when closed
        mainWindow?.isReleasedWhenClosed = false
        
        // Handle window closing
        mainWindow?.delegate = self
        
    }
    
    @objc private func settingsDidChange(_ notification: Notification) {
        guard let settings = notification.object as? UserSettings else { return }
        
        // Reconfigure timer with new settings
        pomodoroTimer?.configureTimer(settings: settings)
        
        // Update keyboard shortcuts
        let shortcuts = settings.keyboardShortcuts.map { shortcut in
            (action: shortcut.action.rawValue, modifiers: shortcut.modifiers, key: shortcut.key, isEnabled: shortcut.isEnabled)
        }
        keyboardShortcutManager?.registerHotKeys(shortcuts: shortcuts)
        
        // Force immediate update of menu bar title and menu
        updateMenuBarTitle()
        setupMenu()
        
        // Force display refresh
        statusItem?.button?.needsDisplay = true
    }
    
    @objc private func quit() {
        cleanup()
        NSApplication.shared.terminate(nil)
    }
    
    private func cleanup() {
        pomodoroTimer?.stop()
        pomodoroTimer = nil
        
        // Clean up keyboard shortcuts
        keyboardShortcutManager = nil
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Close main window first
        mainWindow?.close()
        mainWindow = nil
        
        if let statusItem = statusItem {
            statusItem.menu?.removeAllItems()
            statusItem.menu = nil
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }
}


extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window == mainWindow else { return }
        
        
        // Clean up the window reference and switch back to accessory mode
        DispatchQueue.main.async { [weak self] in
            self?.mainWindow = nil
            NSApp.setActivationPolicy(.accessory)
        }
    }
}


extension AppDelegate: PomodoroTimerDelegate {
    func timerDidUpdate() {
        // Update immediately without dispatch queue to avoid delays during menu interaction
        if Thread.isMainThread {
            self.updateMenuBarTitle()
        } else {
            DispatchQueue.main.sync {
                self.updateMenuBarTitle()
            }
        }
    }
    
    func sessionTypeDidChange(_ sessionType: SessionType) {
        DispatchQueue.main.async {
            self.updateMenuBarTitle()
            self.setupMenu() // Refresh menu for new session type
        }
    }
    
    func timerDidComplete() {
        DispatchQueue.main.async {
            self.updateMenuBarTitle()
            self.showCompletionNotification()
            // Refresh menu to show updated daily progress
            self.setupMenu()
        }
    }
    
    func sessionDidComplete(sessionType: SessionType) {
        DispatchQueue.main.async {
            self.saveCompletedSession(sessionType: sessionType)
            // Refresh menu after saving session to update daily progress
            self.setupMenu()
        }
    }
    
    private func saveCompletedSession(sessionType: SessionType) {
        guard let startTime = sessionStartTime,
              let dataManager = dataManager else { return }
        
        // Calculate actual duration based on when the session started
        let actualDuration = Date().timeIntervalSince(startTime)
        
        // Save the completed session with the actual time spent
        dataManager.saveCurrentSession(
            startTime: startTime,
            duration: actualDuration,
            sessionType: sessionType,
            isCompleted: true
        )
        
        sessionStartTime = nil
    }
    
    private func showCompletionNotification() {
        guard let settings = dataManager?.settings else { return }
        
        // Play sound regardless of notification settings
        if settings.soundEnabled {
            // Try a pleasant notification sound, fall back to beep
            if let sound = NSSound(named: "Ping") {
                sound.play()
            } else {
                NSSound.beep()
            }
        }
        
        // Only show notification if enabled in settings
        guard settings.notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        
        // Customize notification based on session type and mode
        if settings.fullPomodoroMode, let timer = pomodoroTimer {
            let sessionInfo = timer.getCurrentSessionInfo()
            
            switch sessionInfo.type {
            case .work:
                content.title = "\u{1F345} Work Session Complete!"  // 🍅 tomato
                if sessionInfo.position >= sessionInfo.totalInCycle {
                    let breakDuration = settings.longBreakDuration
                    if settings.autoStartBreaks {
                        content.body = "Great work! Starting \(breakDuration)-minute long break automatically. Time to recharge!"
                    } else {
                        content.body = "Great work! Take a \(breakDuration)-minute long break to recharge. You've earned it!"
                    }
                } else {
                    let breakDuration = settings.shortBreakDuration
                    if settings.autoStartBreaks {
                        content.body = "Nice work! Starting \(breakDuration)-minute break automatically. Relax and come back refreshed!"
                    } else {
                        content.body = "Nice work! Take a \(breakDuration)-minute break and come back refreshed."
                    }
                }
                
            case .shortBreak:
                content.title = "\u{2615} Break Complete!"  // ☕ coffee
                let workDuration = settings.workDuration
                if settings.autoStartBreaks {
                    content.body = "Break's over! Starting \(workDuration)-minute work session \(sessionInfo.position)/\(sessionInfo.totalInCycle). Let's focus!"
                } else {
                    content.body = "Break's over! Ready for \(workDuration)-minute work session \(sessionInfo.position)/\(sessionInfo.totalInCycle)?"
                }
                
            case .longBreak:
                content.title = "\u{1F31F} Long Break Complete!"  // 🌟 star
                let workDuration = settings.workDuration
                if settings.autoStartBreaks {
                    content.body = "Excellent! You've completed a full cycle. Starting new \(workDuration)-minute work session. Fresh start!"
                } else {
                    content.body = "Excellent! You've completed a full Pomodoro cycle. Ready for a new \(workDuration)-minute work session?"
                }
            }
        } else {
            // Simple work timer mode
            content.title = "\u{1F345} Timer Complete!"  // 🍅 tomato
            content.body = "Time's up! Take a well-deserved break and start a new session when ready."
        }
        
        // Only add sound if enabled in settings
        if settings.soundEnabled {
            content.sound = .default
        }
        
        let request = UNNotificationRequest(identifier: "pomodoro-complete", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("Failed to show notification: \(error)")
            }
        }
        
    }
}

extension AppDelegate: KeyboardShortcutManagerDelegate {
    func keyboardShortcutTriggered(action: String) {
        switch action {
        case "startPause":
            toggleStartPause()
        case "reset":
            resetTimer()
        case "showStatistics":
            showStatistics()
        default:
            break
        }
    }
}


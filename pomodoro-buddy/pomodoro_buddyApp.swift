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
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var pomodoroTimer: PomodoroTimer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        setupMenuBar()
        setupNotifications()
        setupLaunchAtLogin()
        
        pomodoroTimer = PomodoroTimer()
        pomodoroTimer?.delegate = self
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cleanup()
    }
    
    private func setupLaunchAtLogin() {
        // Enable launch at login by default if not already configured
        if !isLaunchAtLoginEnabled() {
            enableLaunchAtLogin()
        }
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.title = "🍅"
            button.action = #selector(toggleMenu)
            button.target = self
        }
        
        updateMenuBarTitle()
        setupMenu()
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func updateMenuBarTitle() {
        guard let button = statusItem?.button else { return }
        
        if let timer = pomodoroTimer {
            if timer.isRunning || timer.isPaused {
                let minutes = timer.timeRemaining / 60
                let seconds = timer.timeRemaining % 60
                let timeString = String(format: "%02d:%02d", minutes, seconds)
                
                // Update immediately on main thread, even during menu display
                button.title = timeString
                button.needsDisplay = true
            } else {
                button.title = "🍅"
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
        
        // Dynamic start/pause button
        let startPauseTitle = pomodoroTimer?.isRunning == true ? "Pause Timer" : "Start Timer"
        menu.addItem(NSMenuItem(title: startPauseTitle, action: #selector(toggleStartPause), keyEquivalent: "s"))
        menu.addItem(NSMenuItem(title: "Reset Timer", action: #selector(resetTimer), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        
        // Create slider for custom time
        let sliderItem = createCustomTimeSliderItem()
        menu.addItem(sliderItem)
        menu.addItem(NSMenuItem.separator())
        
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "l")
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
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
        slider.minValue = 1
        slider.maxValue = 60
        slider.doubleValue = Double(min(currentMinutes, 60))
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
    
    private func addTickMarks(to containerView: NSView, sliderFrame: NSRect) {
        let snapPoints = [5, 10, 15, 25, 45, 60]
        let sliderStart = sliderFrame.minX
        let sliderWidth = sliderFrame.width
        let sliderMinValue = 1.0
        let sliderMaxValue = 60.0
        
        for snapPoint in snapPoints {
            // Calculate position along slider
            let percentage = (Double(snapPoint) - sliderMinValue) / (sliderMaxValue - sliderMinValue)
            let xPosition = sliderStart + (percentage * sliderWidth)
            
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
        
        // Add min/max labels
        let minLabel = NSTextField(labelWithString: "1")
        minLabel.frame = NSRect(x: sliderStart - 8, y: sliderFrame.minY - 20, width: 16, height: 12)
        minLabel.alignment = .center
        minLabel.font = NSFont.systemFont(ofSize: 9)
        minLabel.textColor = .tertiaryLabelColor
        minLabel.backgroundColor = .clear
        minLabel.isBordered = false
        minLabel.isEditable = false
        minLabel.isSelectable = false
        containerView.addSubview(minLabel)
        
        let maxLabel = NSTextField(labelWithString: "60")
        maxLabel.frame = NSRect(x: sliderStart + sliderWidth - 10, y: sliderFrame.minY - 20, width: 20, height: 12)
        maxLabel.alignment = .center
        maxLabel.font = NSFont.systemFont(ofSize: 9)
        maxLabel.textColor = .tertiaryLabelColor
        maxLabel.backgroundColor = .clear
        maxLabel.isBordered = false
        maxLabel.isEditable = false
        maxLabel.isSelectable = false
        containerView.addSubview(maxLabel)
    }
    
    
    @objc private func toggleStartPause() {
        guard let timer = pomodoroTimer else { return }
        
        if timer.isRunning {
            pomodoroTimer?.pause()
        } else {
            pomodoroTimer?.start()
        }
        
        // Update menu to reflect new state
        setupMenu()
    }
    
    @objc private func resetTimer() {
        pomodoroTimer?.reset()
        setupMenu() // Update menu to show "Start Timer"
    }
    
    @objc private func sliderValueChanged(_ sender: NSSlider) {
        let rawValue = Int(sender.doubleValue)
        
        // Define snap points for common Pomodoro intervals
        let snapPoints = [5, 10, 15, 25, 45, 60]
        let snapThreshold = 2 // Snap within 2 minutes
        
        var snappedValue = rawValue
        
        // Check if close to any snap point
        for snapPoint in snapPoints {
            if abs(rawValue - snapPoint) <= snapThreshold {
                snappedValue = snapPoint
                break
            }
        }
        
        // Update slider to snapped value if different
        if snappedValue != rawValue {
            sender.doubleValue = Double(snappedValue)
        }
        
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
    
    @objc private func toggleLaunchAtLogin() {
        if isLaunchAtLoginEnabled() {
            disableLaunchAtLogin()
        } else {
            enableLaunchAtLogin()
        }
        setupMenu() // Refresh menu to update checkmark
    }
    
    private func isLaunchAtLoginEnabled() -> Bool {
        guard Bundle.main.bundleIdentifier != nil else { return false }
        return SMAppService.mainApp.status == .enabled
    }
    
    private func enableLaunchAtLogin() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("Failed to enable launch at login: \(error)")
        }
    }
    
    private func disableLaunchAtLogin() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("Failed to disable launch at login: \(error)")
        }
    }
    
    @objc private func quit() {
        cleanup()
        NSApplication.shared.terminate(nil)
    }
    
    private func cleanup() {
        pomodoroTimer?.stop()
        pomodoroTimer = nil
        
        if let statusItem = statusItem {
            statusItem.menu?.removeAllItems()
            statusItem.menu = nil
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
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
    
    func timerDidComplete() {
        DispatchQueue.main.async {
            self.updateMenuBarTitle()
            self.showCompletionNotification()
        }
    }
    
    private func showCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🍅 Pomodoro Timer"
        content.body = "Time's up! Take a break."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "pomodoro-complete", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}
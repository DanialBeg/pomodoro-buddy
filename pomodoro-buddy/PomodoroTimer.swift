//
//  PomodoroTimer.swift
//  pomodoro-buddy
//
//  Created by Danial Beg on 7/5/25.
//

import Foundation
import AppKit

protocol PomodoroTimerDelegate: AnyObject {
    func timerDidUpdate()
    func timerDidComplete()
    func sessionTypeDidChange(_ sessionType: SessionType)
    func sessionDidComplete(sessionType: SessionType)
}

class PomodoroTimer: ObservableObject {
    weak var delegate: PomodoroTimerDelegate?
    
    private var timer: Timer?
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var pauseStartTime: Date?
    private(set) var totalTime: Int = 25 * 60 // 25 minutes in seconds
    private(set) var timeRemaining: Int = 25 * 60
    private(set) var isRunning: Bool = false
    private(set) var isPaused: Bool = false
    private var isObservingWorkspace: Bool = false
    
    // Full Pomodoro cycle properties
    private(set) var currentSessionType: SessionType = .work
    private(set) var workSessionsCompleted: Int = 0
    private(set) var cyclePosition: Int = 1 // 1-4 for work sessions
    private var fullPomodoroMode: Bool = false
    private var settings: UserSettings?
    private var isCompleting: Bool = false
    
    func start() {
        guard !isRunning else { return }
        
        // Ensure any existing timer is invalidated first
        timer?.invalidate()
        timer = nil
        
        isRunning = true
        isPaused = false
        
        if startTime == nil {
            // First time starting - set initial start time based on current timeRemaining
            let elapsedTime = TimeInterval(totalTime - timeRemaining)
            startTime = Date().addingTimeInterval(-elapsedTime)
            pausedDuration = 0
        }
        
        // Register for sleep/wake notifications (only if not already observing)
        if !isObservingWorkspace {
            NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: #selector(systemWillSleep),
                name: NSWorkspace.willSleepNotification,
                object: nil
            )
            
            NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: #selector(systemDidWake),
                name: NSWorkspace.didWakeNotification,
                object: nil
            )
            
            isObservingWorkspace = true
        }
        
        // Create timer with weak self to avoid retain cycle
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        
        // Add timer to main run loop with .common mode to continue during menu interactions
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        
        // Notify delegate that timer has started (on main thread)
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.timerDidUpdate()
        }
    }
    
    func pause() {
        guard isRunning else { return }
        
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = true
        
        // Remove sleep/wake observers
        if isObservingWorkspace {
            NSWorkspace.shared.notificationCenter.removeObserver(self)
            isObservingWorkspace = false
        }
        
        delegate?.timerDidUpdate()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        startTime = nil
        pausedDuration = 0
        pauseStartTime = nil
        
        // Remove sleep/wake observers
        if isObservingWorkspace {
            NSWorkspace.shared.notificationCenter.removeObserver(self)
            isObservingWorkspace = false
        }
        
        delegate?.timerDidUpdate()
    }
    
    func reset() {
        stop()
        timeRemaining = totalTime
        startTime = nil
        pausedDuration = 0
        pauseStartTime = nil
        isPaused = false
        delegate?.timerDidUpdate()
    }
    
    func setCustomTime(minutes: Int) {
        let seconds = minutes * 60
        totalTime = seconds
        
        // Only reset timeRemaining if not currently running or paused
        if !isRunning && !isPaused {
            timeRemaining = seconds
        }
        
        delegate?.timerDidUpdate()
    }
    
    func configureTimer(settings: UserSettings) {
        self.settings = settings
        self.fullPomodoroMode = settings.fullPomodoroMode
        
        // Set timer duration based on current session type
        updateTimerForCurrentSession()
    }
    
    private func updateTimerForCurrentSession() {
        guard let settings = settings else { return }
        
        let duration: Int
        switch currentSessionType {
        case .work:
            duration = settings.workDuration * 60
        case .shortBreak:
            duration = settings.shortBreakDuration * 60
        case .longBreak:
            duration = settings.longBreakDuration * 60
        }
        
        totalTime = duration
        // Always reset timeRemaining when changing session types to ensure fresh start
        timeRemaining = duration
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.timerDidUpdate()
            self.delegate?.sessionTypeDidChange(self.currentSessionType)
        }
    }
    
    func getCurrentSessionInfo() -> (type: SessionType, position: Int, totalInCycle: Int) {
        return (currentSessionType, cyclePosition, settings?.longBreakInterval ?? 4)
    }
    
    private func tick() {
        guard let startTime = startTime, 
              isRunning,
              timer != nil else { return }
        
        let elapsed = Date().timeIntervalSince(startTime) - pausedDuration
        timeRemaining = max(0, totalTime - Int(elapsed))
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.timerDidUpdate()
        }
        
        if timeRemaining <= 0 {
            complete()
        }
    }
    
    @objc private func systemWillSleep() {
        // Store current state when going to sleep
        if isRunning {
            pauseStartTime = Date()
        }
    }
    
    @objc private func systemDidWake() {
        // Adjust for sleep time when waking up
        if isRunning, let pauseStart = pauseStartTime {
            let sleepDuration = Date().timeIntervalSince(pauseStart)
            startTime = startTime?.addingTimeInterval(sleepDuration)
            pauseStartTime = nil
        }
    }
    
    private func complete() {
        // Prevent multiple simultaneous completions
        guard !isCompleting else { return }
        isCompleting = true
        
        if fullPomodoroMode {
            handleFullPomodoroCompletion()
        } else {
            // Simple work timer mode - just stop
            let completedSessionType = currentSessionType
            stop()
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.timerDidComplete()
                // Only save work sessions for statistics - breaks are not tracked
                if completedSessionType == .work {
                    self?.delegate?.sessionDidComplete(sessionType: completedSessionType)
                }
                self?.isCompleting = false
            }
        }
    }
    
    private func handleFullPomodoroCompletion() {
        guard let settings = settings else {
            stop()
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.timerDidComplete()
                self?.isCompleting = false
            }
            return
        }
        
        let previousSessionType = currentSessionType
        
        switch currentSessionType {
        case .work:
            workSessionsCompleted += 1
            cyclePosition += 1
            
            // Determine next session type
            if cyclePosition > settings.longBreakInterval {
                // Time for long break
                currentSessionType = .longBreak
                cyclePosition = 1 // Reset for next cycle
            } else {
                // Time for short break
                currentSessionType = .shortBreak
            }
            
        case .shortBreak, .longBreak:
            // Break completed, back to work
            currentSessionType = .work
        }
        
        // Update timer for new session type
        updateTimerForCurrentSession()
        
        // Always stop the current timer first
        stop()
        
        // Check if we should auto-start (only for breaks after work sessions)
        let shouldAutoStart = settings.autoStartBreaks && 
                              previousSessionType == .work && 
                              (currentSessionType == .shortBreak || currentSessionType == .longBreak)
        
        if shouldAutoStart {
            // Add delay to ensure proper state transition and completion handling
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                // Only auto-start if we're still in a valid state
                guard !self.isRunning && !self.isPaused && !self.isCompleting else { return }
                self.start()
            }
        }
        
        // Notify completion with the session type that just completed (on main thread)
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.timerDidComplete()
            // Only save work sessions for statistics - breaks are not tracked
            if previousSessionType == .work {
                self?.delegate?.sessionDidComplete(sessionType: previousSessionType)
            }
            self?.isCompleting = false
        }
    }
    
    deinit {
        // Immediately invalidate timer to prevent further callbacks
        timer?.invalidate()
        timer = nil
        
        // Clean up workspace notifications
        if isObservingWorkspace {
            NSWorkspace.shared.notificationCenter.removeObserver(self)
            isObservingWorkspace = false
        }
    }
}
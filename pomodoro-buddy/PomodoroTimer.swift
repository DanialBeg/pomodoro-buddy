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
    
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        isPaused = false
        
        if startTime == nil {
            // First time starting - set initial start time based on current timeRemaining
            let elapsedTime = TimeInterval(totalTime - timeRemaining)
            startTime = Date().addingTimeInterval(-elapsedTime)
            pausedDuration = 0
        }
        
        // Register for sleep/wake notifications
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
        
        // Create timer on background queue to avoid blocking UI
        let timer = Timer(timeInterval: 0.1, repeats: true) { _ in
            self.tick()
        }
        
        // Add timer to main run loop with .common mode to continue during menu interactions
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    
    func pause() {
        guard isRunning else { return }
        
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = true
        
        // Remove sleep/wake observers
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        
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
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        
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
    
    private func tick() {
        guard let startTime = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime) - pausedDuration
        timeRemaining = max(0, totalTime - Int(elapsed))
        
        delegate?.timerDidUpdate()
        
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
        stop()
        delegate?.timerDidComplete()
    }
}
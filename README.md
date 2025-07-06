# 🍅 Pomodoro Buddy

A simple and elegant macOS menu bar Pomodoro timer application.

## Features

- 🍅 **Menu Bar Integration**: Lives discreetly in your macOS menu bar
- ⏱️ **Smart Timer Controls**: Start, pause, and reset with proper state management
- 🎛️ **Custom Time Slider**: 1-60 minute range with snap points for common intervals (5, 10, 15, 25, 45, 60 mins)
- 📱 **Real-time Display**: Shows countdown in menu bar when running or paused
- 🔔 **Desktop Notifications**: Get notified when your Pomodoro session completes
- 🚀 **Launch at Login**: Automatically starts with your Mac (enabled by default)
- 💤 **Sleep Handling**: Maintains accurate timing across system sleep/wake cycles
- ⌨️ **Keyboard Shortcuts**: Quick access to all functions

## Installation

### Option 1: Download Pre-built App (Coming Soon)
A compiled `.app` file will be available for download from the Releases section.

### Option 2: Build from Source
1. Clone this repository
2. Open `pomodoro-buddy.xcodeproj` in Xcode
3. Build and run (⌘R)

## Usage

- Click the 🍅 icon in the menu bar to access controls
- **Keyboard Shortcuts**:
  - `⌘S`: Start/Pause timer
  - `⌘R`: Reset timer
  - `⌘C`: Set custom time (via slider)
  - `⌘L`: Toggle launch at login
  - `⌘Q`: Quit app

## How It Works

- **Start**: Begins countdown from selected time
- **Pause**: Preserves current time and displays it in menu bar
- **Resume**: Continues from where you paused
- **Reset**: Stops timer and resets to selected duration

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later (for building from source)

## Contributing

Feel free to submit issues and enhancement requests!
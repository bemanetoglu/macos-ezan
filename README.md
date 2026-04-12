# EzanVakti 🕌

A native macOS menu bar application that displays daily Islamic prayer times with countdown to the next prayer.

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- 🕐 **Real-time Countdown**: Displays countdown to the next prayer time in the menu bar
- 📍 **Location Support**: Manual location selection (Country → City → District) or automatic location detection
- 🔔 **Notifications**: Optional notifications before each prayer time
- 🎨 **Display Modes**: Choose between prayer name + time, countdown timer, or icon-only
- ⚡ **Auto Launch**: Option to launch automatically at system startup
- 🌍 **Multi-country Support**: Supports prayer times for multiple countries worldwide
- 📱 **Menu Bar Integration**: Lightweight menu bar app with popover interface

## Prayer Times

The application displays the following daily prayer times:

- **İmsak** - Pre-dawn prayer
- **Güneş** - Sunrise
- **Öğle** - Midday prayer
- **İkindi** - Afternoon prayer
- **Akşam** - Sunset/Maghrib prayer
- **Yatsı** - Night prayer

## 🌍 Multi-Language Support

The application supports **Turkish** and **English** languages. The app automatically uses your macOS system language:

- **Türkçe** (varsayılan)
- **English**

To change the language:
1. Open **System Settings** → **General** → **Language & Region**
2. Add your preferred language or change system language
3. Restart the app

### Adding a New Language

1. Create a new folder: `Resources/Localization/xx.lproj/` (where `xx` is the language code)
2. Copy and translate `Localizable.strings` into that folder
3. Add the language code to `CFBundleLocalizations` in `build.sh`

---

## API

Prayer times data is provided by the [EzanVakti API](https://github.com/furkantektas/EzanVaktiAPI) project, hosted at `https://ezanvakti.emushaf.net`. We gratefully acknowledge the Furkan Tektaş and the Emushaf team for maintaining this essential service.

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon (ARM64) or Intel (x86_64) processor
- Internet connection for fetching prayer times
- Location access (optional, for automatic location detection)

## Installation

### Option 1: Build from Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/burhanemanetoglu/macos-ezan.git
   cd macos-ezan
   ```

2. **Build the application:**
   ```bash
   chmod +x build.sh
   ./build.sh
   ```

3. **Run the application:**
   ```bash
   open EzanVakti.app
   ```

### Option 2: Download Pre-built

Download the latest release from the [Releases](https://github.com/burhanemanetoglu/macos-ezan/releases) page.

## Usage

### First Launch

1. On first launch, you'll be prompted to select your location:
   - **Country** → **City** → **District**
2. Alternatively, click **"Auto Find Location"** to automatically detect your location using GPS

### Menu Bar Display

The app runs in the macOS menu bar and shows:
- A moon icon (🌙) followed by
- The next prayer name and countdown time (based on your display style preference)

### Settings

Click on the menu bar icon to open the settings panel where you can:

- **Change Location**: Select a different country, city, or district
- **Auto Find Location**: Automatically detect your current location
- **Display Style**: Choose how prayer times appear in the menu bar:
  - *Vakit Adı ve Saati* - Prayer name and time (e.g., "Öğle 13:13")
  - *Vakte Kalan Süre* - Countdown timer (e.g., "Öğle 02:45:30")
  - *Sadece İkon* - Icon only
- **Notifications**: Enable/disable prayer time notifications
- **Launch at Login**: Enable/disable automatic startup with macOS

## Project Structure

```
Sources/EzanVakti/
├── EzanVaktiApp.swift          # Main app entry point
├── Models/
│   ├── EmushafModels.swift     # Data models for API responses
│   └── PrayerTimes.swift       # Prayer time structures
├── Services/
│   ├── APIService.swift        # API client for EzanVakti
│   ├── LocationManager.swift   # Core Location integration
│   └── NotificationManager.swift # Notification scheduling
├── ViewModels/
│   └── AppViewModel.swift      # Main application state management
└── Views/
    └── MainView.swift          # User interface components
```

## Build Script

The `build.sh` script compiles the Swift source files and creates a proper macOS app bundle:

```bash
#!/bin/bash
./build.sh
```

This will:
1. Create the `.app` bundle structure
2. Compile all Swift files with optimizations
3. Copy the app icon to Resources
4. Generate the `Info.plist` configuration

## Configuration

### Info.plist Keys

- `CFBundleIconFile`: App icon file reference
- `LSUIElement`: Runs as a menu bar app (hidden from Dock)
- `NSLocationWhenInUseUsageDescription`: Location permission description

### UserDefaults

The app stores user preferences in `UserDefaults`:
- `ulkeID`, `sehirID`, `ilceID`: Selected location IDs
- `widgetStyle`: Display style preference
- `enableNotifications`: Notification toggle
- `isOnboardingCompleted`: First-run completion status

## Notifications

When enabled, the app schedules notifications for each upcoming prayer time. Notifications are:
- Scheduled daily based on prayer times
- Automatically refreshed when prayer times are updated
- Cleared when notifications are disabled

## Location Services

The app uses Core Location for automatic location detection:
1. Requests location permission from the user
2. Reverse geocodes coordinates to city/district names
3. Matches against the EzanVakti API database
4. Falls back to manual selection if auto-detection fails

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

- **[EzanVakti API](https://github.com/furkantektas/EzanVaktiAPI)** - Prayer times data API by Furkan Tektaş and the Emushaf team
- **[Diyanet](https://www.diyanet.gov.tr)** - Official prayer times source for Turkey

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Burhan Emanoğlu**  
- GitHub: [@burhanemanetoglu](https://github.com/burhanemanetoglu)

## Screenshots

### Menu Bar Display
The app shows the next prayer name and countdown in your macOS menu bar.

### Settings Panel
Select your location and customize display preferences in the popover interface.

---

**Made with ❤️ for the Muslim community**

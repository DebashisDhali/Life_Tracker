<div align="center">

# 🌟 Life Tracker

### *Your all-in-one personal growth & finance companion*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-orange?style=for-the-badge)](pubspec.yaml)

<br/>

> **Track your habits. Manage your money. Grow every day.** 🚀

</div>

---

## 📲 Download & Install

<div align="center">

### ⬇️ [Download Latest APK — LifeTracker v1.0.0](https://github.com/DebashisDhali/Life_Tracker/raw/main/releases/LifeTracker-v1.0.0.apk)

[![Download APK](https://img.shields.io/badge/Download-APK%20v1.0.0-brightgreen?style=for-the-badge&logo=android&logoColor=white)](https://github.com/DebashisDhali/Life_Tracker/raw/main/releases/LifeTracker-v1.0.0.apk)

</div>

### 📋 Installation Steps (Android)

> ⚠️ **Note:** This is not from the Play Store, so you need to allow installation from unknown sources.

1. **Download** the APK file from the link above
2. Open your phone's **Settings → Security**
3. Enable **"Install from Unknown Sources"** (or "Allow from this source")
4. Open the downloaded **`LifeTracker-v1.0.0.apk`** file
5. Tap **Install** and wait for it to finish
6. Open **Life Tracker** and sign in with Google 🎉

> ✅ **Requirements:** Android 5.0 (Lollipop) or higher | ~25 MB storage

---

## 📱 About Life Tracker

**Life Tracker** is a beautifully designed Flutter application that helps you take control of every aspect of your life — from building powerful daily habits to managing your personal finances. With cloud sync, smart reminders, achievement badges, and insightful visualizations, Life Tracker becomes your daily personal coach.

Whether you're trying to build a workout routine, track your savings, or maintain a growth streak — Life Tracker keeps you accountable and motivated!

---

## ✨ Key Features

### 🎯 Habit & Goal Tracking
- **Daily Habit Sections** — Organize your habits into custom sections (e.g., Morning Routine, Health, Work)
- **Subtask Management** — Break down habits into smaller, achievable subtasks with timers
- **Bundled Goals** — Create week-long or multi-day challenge goals
- **Growth Percentage** — See your daily completion % at a glance

### 💰 Money Management
- **Income & Expense Ledger** — Track every transaction with categories
- **Financial Targets** — Set monthly savings goals and monitor progress
- **Money Overview** — Visual summary of your financial health with charts
- **Multi-source Tracking** — Log money from different sources

### 📊 Analytics & Insights
- **Day Stack** — Visual representation of your daily progress over time
- **Streak Tracking** — Tracks consecutive days where your growth ≥ previous day
- **Weekly Charts** — Beautiful bar charts showing your weekly performance
- **Achievement History** — Detailed view of past accomplishments

### 🏆 Gamification & Motivation
- **Badge System** — Earn badges for hitting milestones and maintaining streaks
- **Celebration Animations** — Confetti and celebration overlays on achievements
- **Achievement Details Screen** — View earned trophies and progress

### 🔔 Smart Reminders
- **Custom Notification Scheduling** — Set reminders for specific habits
- **Timezone-aware** — Notifications fire at the correct local time
- **Daily Reminder Setup** — Dedicated screen for managing all reminders

### ☁️ Cloud Sync & Authentication
- **Firebase Authentication** — Secure login with Google Sign-In
- **Cloud Firestore** — All your data synced across devices in real-time
- **Pull-to-Refresh** — Manual sync trigger for instant data refresh
- **Offline Support** — App works offline with local Hive database

### 🎨 Beautiful UI/UX
- **Light & Dark Mode** — Toggle between themes from the profile screen
- **Onboarding Flow** — Smooth introduction slides for new users
- **No Internet State** — Graceful UI for offline scenarios
- **Responsive Design** — Optimized for all Android screen sizes

---

## 🏗️ Project Architecture

```
life_tracker/
├── lib/
│   ├── main.dart                    # App entry point & initialization
│   ├── models/                      # Data models
│   │   ├── habit_section.dart       # Habit section & subtask models
│   │   └── money_entry.dart         # Money transaction model
│   ├── providers/                   # State management (Provider)
│   │   ├── life_provider.dart       # Core business logic & data
│   │   ├── theme_provider.dart      # Light/Dark theme management
│   │   └── ...
│   ├── screens/                     # App screens
│   │   ├── home_screen.dart         # Main dashboard
│   │   ├── money_screen.dart        # Finance tracking screen
│   │   ├── profile_screen.dart      # User profile & settings
│   │   ├── auth_screen.dart         # Login / Sign-up screen
│   │   ├── manage_habits_screen.dart# Habit management
│   │   ├── bundled_goals_screen.dart# Multi-day challenges
│   │   ├── onboarding_screen.dart   # First-launch intro
│   │   ├── reminder_setup_screen.dart # Notification settings
│   │   └── achievement_details_screen.dart
│   ├── widgets/                     # Reusable UI components
│   │   ├── section_card.dart        # Habit section card widget
│   │   ├── subtask_tile.dart        # Individual subtask tile
│   │   ├── habit_tile.dart          # Habit item widget
│   │   ├── weekly_chart.dart        # Weekly progress bar chart
│   │   ├── badges_widget.dart       # Achievement badges display
│   │   ├── navigation_drawer.dart   # Side navigation menu
│   │   ├── add_money_entry_dialog.dart # Add transaction dialog
│   │   ├── finance_settings_dialog.dart # Financial goals config
│   │   ├── celebration_overlay.dart # Confetti animation overlay
│   │   ├── timer_dialog.dart        # Habit timer dialog
│   │   ├── no_internet_widget.dart  # Offline state UI
│   │   ├── premium_alert.dart       # Premium feature prompt
│   │   └── money_ledger_section.dart
│   ├── services/                    # External services integration
│   │   ├── notification_service.dart# Local notifications
│   │   └── firebase_service.dart    # Firestore CRUD operations
│   └── utils/                       # Utilities & constants
│       ├── constants.dart           # App-wide constants & theme
│       └── ...
├── android/                         # Android platform files
├── ios/                             # iOS platform files
├── assets/                          # Images, icons, sounds
├── pubspec.yaml                     # Dependencies & config
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x or higher)
- [Dart SDK](https://dart.dev/get-dart) (v3.x or higher)
- [Android Studio](https://developer.android.com/studio) / [VS Code](https://code.visualstudio.com/)
- A Firebase project with Authentication & Firestore enabled

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/DebashisDhali/Life_Tracker.git
cd Life_Tracker
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Firebase Setup**
- Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
- Enable **Google Sign-In** in Authentication
- Enable **Cloud Firestore**
- Download `google-services.json` and place it in `android/app/`

**4. Run the app**
```bash
flutter run
```

**5. Build APK (Release)**
```bash
flutter build apk --release
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.1.5 | State management |
| `hive` + `hive_flutter` | ^2.2.3 | Local database |
| `firebase_core` | ^4.4.0 | Firebase initialization |
| `firebase_auth` | ^6.1.4 | User authentication |
| `cloud_firestore` | ^6.1.2 | Cloud data storage |
| `google_sign_in` | 6.2.1 | Google authentication |
| `flutter_local_notifications` | ^20.1.0 | Local push notifications |
| `timezone` | ^0.10.1 | Timezone handling |
| `confetti` | ^0.8.0 | Celebration animations |
| `lottie` | ^3.3.1 | Lottie animations |
| `percent_indicator` | ^4.2.5 | Circular/linear progress |
| `audioplayers` | ^6.1.1 | Sound effects |
| `intro_slider` | ^4.2.5 | Onboarding screens |
| `shared_preferences` | ^2.3.5 | Lightweight local storage |
| `intl` | ^0.20.2 | Date formatting |
| `path_provider` | ^2.1.5 | Device path access |

---

## 📸 Screenshots

| Home Screen | Money Screen | Profile Screen |
|:-----------:|:------------:|:--------------:|
| Daily habits & growth percentage | Income/expense tracker | Settings & achievements |

| Onboarding | Achievements | Dark Mode |
|:----------:|:------------:|:---------:|
| Smooth intro flow | Badge collection | Full dark theme |

---

## 🗺️ Roadmap

- [x] Daily habit tracking with sections
- [x] Money income/expense management
- [x] Firebase cloud sync
- [x] Google Sign-In authentication
- [x] Push notifications & reminders
- [x] Achievement badges & gamification
- [x] Light & Dark mode
- [x] Pull-to-refresh sync
- [x] Bundled/multi-day challenge goals
- [ ] Widget support (Android home screen widget)
- [ ] iOS support (full testing)
- [ ] Data export (CSV/PDF)
- [ ] AI-powered habit suggestions
- [ ] Social sharing of achievements

---

## 🤝 Contributing

Contributions are welcome! If you have ideas, feature requests, or bug reports:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 👨‍💻 Author

**Debashis Dhali**

[![GitHub](https://img.shields.io/badge/GitHub-DebashisDhali-181717?style=for-the-badge&logo=github)](https://github.com/DebashisDhali)

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ using Flutter

*If you find this project helpful, please give it a ⭐ star!*

</div>
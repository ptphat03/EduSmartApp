# EduSmartApp

EduSmartApp is a smart learning application built with **Flutter**, designed to help users manage and participate in educational activities anytime, anywhere. The app aims to support students, learners, and teachers with a friendly, modern, and easy-to-use interface.  

---

## ✨ Features
- 👩‍🏫 Manage courses and lessons.
- 📅 Learning schedule with reminders.
- 🔔 Notification system to never miss a lesson.
- ☁️ Data synchronization (can be integrated with Firebase or a custom API backend).

---

## 🛠️ Technologies Used
- [Flutter](https://flutter.dev/) (Dart)
- Kotlin (native Android integration)
- Common Flutter packages:
  - `provider` / `bloc` – state management
  - `http` – API calls
  - `shared_preferences` – local storage
  - `firebase_auth`, `cloud_firestore` – authentication and data storage

---

## 📂 Project Structure
```
EduSmartApp/
├── android/              # Android configuration (Gradle, manifest…)
├── lib/                  # Main Flutter source code
│   ├── main.dart         # App entry point
│   ├── models/           # Data models
│   ├── pages/            # Screens / UI
│   ├── services/         # Business logic, API integration
│   └── widgets/          # Reusable UI components
├── test/                 # Unit & widget tests
├── pubspec.yaml          # Dependency configuration
└── README.md             # Project documentation
```

---

## ⚡ Installation & Run
1. Clone the repository:
   ```bash
   git clone https://github.com/ptphat03/EduSmartApp.git
   cd EduSmartApp
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```
   > Can be run on **Android Emulator**, **iOS Simulator**, or a physical device.

---

## 📧 Contact
- Author: **[ptphat03](https://github.com/ptphat03)**

---

✨ *EduSmartApp – Smart learning in your hands!* ✨

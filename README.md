# EduSmartApp

EduSmartApp là ứng dụng học tập thông minh được phát triển bằng **Flutter**, giúp người dùng quản lý và tham gia các hoạt động học tập mọi lúc, mọi nơi. Ứng dụng hướng tới việc hỗ trợ học sinh, sinh viên và giáo viên với giao diện thân thiện, hiện đại và dễ sử dụng.  

---

## Tính năng chính
- 👩‍🏫 Quản lý khóa học và bài học.
- 📅 Lịch học và thông báo nhắc nhở.
- 📝 Làm bài tập/trắc nghiệm và lưu kết quả.
- 🔔 Hệ thống thông báo giúp không bỏ lỡ lịch học.
- ☁️ Đồng bộ dữ liệu (có thể tích hợp với Firebase hoặc API backend).

---

## 🛠️ Công nghệ sử dụng
- [Flutter](https://flutter.dev/) (Dart)
- Kotlin (native Android integration)
- Các thư viện phổ biến trong Flutter:
  - `provider` / `bloc` – quản lý trạng thái
  - `http` hoặc `dio` – kết nối API
  - `shared_preferences` – lưu trữ cục bộ
  - `firebase_auth`, `cloud_firestore` – xác thực và lưu trữ dữ liệu

---

## 📂 Cấu trúc dự án
```
EduSmartApp/
├── android/              # Cấu hình Android (Gradle, manifest…)
├── lib/                  # Code chính Flutter
│   ├── main.dart         # Điểm khởi đầu ứng dụng
│   ├── models/           # Định nghĩa dữ liệu
│   ├── pages/            # Các màn hình (UI)
│   ├── services/         # Xử lý logic, API
│   └── widgets/          # Thành phần giao diện tái sử dụng
├── test/                 # Unit & widget tests
├── pubspec.yaml          # Khai báo dependencies
└── README.md             # Tài liệu dự án
```

---

## ⚡ Cài đặt & chạy ứng dụng
1. Clone repo:
   ```bash
   git clone https://github.com/ptphat03/EduSmartApp.git
   cd EduSmartApp
   ```
2. Cài dependencies:
   ```bash
   flutter pub get
   ```
3. Chạy ứng dụng:
   ```bash
   flutter run
   ```
   > Có thể chạy trên **Android Emulator**, **iOS Simulator** hoặc thiết bị thật.

---

## 📧 Liên hệ
- Tác giả: **[ptphat03](https://github.com/ptphat03)**

---

✨ *EduSmartApp – Học tập thông minh trong tầm tay bạn!* ✨

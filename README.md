# FLIX – Ứng dụng Tra cứu Phim

Ứng dụng Flutter tra cứu phim với giao diện dark theme hiện đại, bao gồm 17 màn hình: Splash, Onboarding, Login/Register, Home, Search, Movie Detail, Trailer, Review, Favorites, History, Profile, Settings.

## Yêu cầu

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

## Cài đặt & Chạy

```bash
# Cài đặt dependencies
flutter pub get

# Chạy trên trình duyệt
flutter run -d chrome

# Chạy trên thiết bị Android/iOS
flutter run
```

## Cấu trúc Project

```
lib/
├── main.dart              # Entry point
├── models/                # Data models (Movie)
├── data/                  # Mock data
├── theme/                 # App theme, colors, styles
├── widgets/               # Reusable widgets
├── routes/                # Route declarations
└── screens/               # 17 screen files
```

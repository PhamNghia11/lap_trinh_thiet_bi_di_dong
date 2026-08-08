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
flutter run --dart-define=FLIX_API_URL=http://10.0.2.2:3000/api/v1
```

`10.0.2.2` dùng cho Android Emulator. Khi chạy trên điện thoại thật, thay bằng
IP LAN của máy đang chạy NestJS, ví dụ `http://192.168.1.10:3000/api/v1`.

Ứng dụng hiện kết nối API thật cho đăng ký/đăng nhập, khôi phục phiên, phim
TMDB, tìm kiếm, chi tiết, trailer YouTube, yêu thích, lịch sử, đánh giá và hồ sơ.

## Cấu trúc Project

```

## Backend

Backend NestJS nằm trong thư mục `backend/`, sử dụng Prisma và PostgreSQL trên
Supabase. Xem `backend/README.md` để cấu hình database, TMDB và chạy API.
lib/
├── main.dart              # Entry point
├── models/                # Data models (Movie)
├── core/                  # API client và phiên đăng nhập
├── data/                  # Repository API và dữ liệu fallback
├── theme/                 # App theme, colors, styles
├── widgets/               # Reusable widgets
├── routes/                # Route declarations
└── screens/               # 17 screen files
```

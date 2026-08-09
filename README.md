# FLIX – Ứng dụng Tra cứu Phim

Ứng dụng Flutter tra cứu phim với giao diện dark theme hiện đại, bao gồm 17 màn hình: Splash, Onboarding, Login/Register, Home, Search, Movie Detail, Trailer, Review, Favorites, History, Profile, Settings.

## Yêu cầu

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

## Cài đặt lần đầu

Từ thư mục gốc của project, cài dependencies cho Flutter và backend:

```powershell
flutter pub get
cd backend
npm install
Copy-Item .env.example .env
npm run db:generate
npm run db:deploy
cd ..
```

Sau khi tạo `backend/.env`, điền đúng `DATABASE_URL`, `JWT_SECRET` và
`TMDB_API_KEY` trước khi chạy backend. Không commit file `.env`.

## Chạy project trên Chrome

Mở hai cửa sổ PowerShell tại thư mục gốc của project.

Terminal 1 - chạy NestJS API:

```powershell
cd backend
npm run start:dev
```

Terminal 2 - chạy Flutter Web ở debug mode và trỏ tới API local:

```powershell
flutter run -d web-server --web-port=8765 --web-server-debug-protocol=sse --web-server-debug-backend-protocol=sse --web-server-debug-injected-client-protocol=sse --dart-define=FLIX_API_URL=http://localhost:3000/api/v1
```

Sau đó tự mở Chrome bình thường và truy cập `http://localhost:8765`. Cách này vừa
cho phép đăng nhập Google bằng profile Chrome thật, vừa hỗ trợ nhấn `r` trong
terminal để hot reload. Không cần dừng và chạy lại Flutter sau mỗi lần sửa UI.

Ba tham số debug `=sse` tránh lỗi DWDS/WebSocketProxyService như `_JsonMap is not
a subtype of List<Object?>` hoặc hot restart chỉ nhận `1/2 responses`. Khi sửa UI,
nhấn `r` thường để hot reload. Tránh `R` hoa khi đang ở màn có iframe trailer vì
đó là hot restart toàn ứng dụng. Dòng `DDC is about to load...` chỉ là log đang
biên dịch; lần chạy debug đầu tiên có thể mất thêm thời gian.

Có thể kiểm tra backend tại `http://localhost:3000/api/v1/health`. Nếu quên
`--dart-define` khi chạy Chrome, ứng dụng sẽ dùng địa chỉ mặc định dành cho
Android Emulator và các thao tác như đăng nhập có thể bị timeout.

Nếu vừa thêm hoặc cập nhật Flutter plugin như `image_picker`, hot reload không
đăng ký lại plugin. Khi gặp `MissingPluginException`, dừng hẳn Flutter rồi chạy:

```powershell
flutter clean
flutter pub get
flutter run -d web-server --web-port=8765 --web-server-debug-protocol=sse --web-server-debug-backend-protocol=sse --web-server-debug-injected-client-protocol=sse --dart-define=FLIX_API_URL=http://localhost:3000/api/v1
```

Chỉ dùng release mode để kiểm tra bản cuối trước khi deploy. Release mode không có
hot reload, nên mỗi lần thay đổi code phải dừng và chạy lại:

```powershell
flutter run -d web-server --release --web-port=8765 --dart-define=FLIX_API_URL=http://localhost:3000/api/v1
```

## Chạy trên Android

Android Emulator dùng địa chỉ `10.0.2.2` để truy cập máy đang chạy backend:

```powershell
flutter run --dart-define=FLIX_API_URL=http://10.0.2.2:3000/api/v1
```

Khi chạy trên điện thoại thật, thay `10.0.2.2` bằng IP LAN của máy đang chạy
NestJS, ví dụ `http://192.168.1.10:3000/api/v1`.

## Đăng nhập Google và Facebook trên Web

Social login dùng OAuth callback qua backend. Trong `backend/.env`, cấu hình:

```env
PUBLIC_API_URL="http://localhost:3000"
OAUTH_RETURN_URL="http://localhost:8765/#/auth/callback"
GOOGLE_CLIENT_ID="..."
GOOGLE_CLIENT_SECRET="..."
FACEBOOK_APP_ID="..."
FACEBOOK_APP_SECRET="..."
FACEBOOK_GRAPH_VERSION="..."
```

Khai báo callback Google tại Google Cloud Console:

- Google: `http://localhost:3000/api/v1/auth/oauth/google/callback`

Với Facebook Login ở Development mode, Meta tự động cho phép redirect
`http://localhost`, vì vậy không thêm callback localhost vào ô `Valid OAuth
Redirect URIs`. Backend vẫn sử dụng callback
`http://localhost:3000/api/v1/auth/oauth/facebook/callback`. Khi phát hành,
thay `PUBLIC_API_URL` bằng domain HTTPS thật và thêm callback HTTPS đó vào Meta.

Port `8765` trong lệnh Flutter phải khớp `OAUTH_RETURN_URL`. Sau khi thay đổi
schema hoặc kéo migration mới, chạy `npm run db:generate` và
`npm run db:deploy` trong thư mục `backend`.

### Test Google OAuth trên Chrome local

Chrome do `flutter run -d chrome` mở có thể dùng profile debug/automation tạm
thời. Google đôi khi chặn profile này với thông báo `Couldn't sign you in` hoặc
`This browser or app may not be secure`. Đây không phải lỗi Client ID hay
callback.

Khi test đăng nhập Google, chạy Flutter dưới dạng web server:

```powershell
flutter run -d web-server --web-port=8765 --web-server-debug-protocol=sse --web-server-debug-backend-protocol=sse --web-server-debug-injected-client-protocol=sse --dart-define=FLIX_API_URL=http://localhost:3000/api/v1
```

Sau đó tự mở Chrome bình thường bằng profile cá nhân và truy cập:

```text
http://localhost:8765/#/login
```

Đóng cửa sổ Chrome debug cũ để tránh nhầm. Tài khoản đăng nhập phải nằm trong
`Google Auth Platform > Audience > Test users` khi OAuth app còn ở trạng thái
`Testing`. Không dùng `--disable-web-security` hoặc profile automation để đăng
nhập Google.

Ứng dụng hiện kết nối API thật cho đăng ký/đăng nhập, khôi phục phiên, phim
TMDB, tìm kiếm, chi tiết, trailer YouTube, yêu thích, lịch sử, đánh giá và hồ sơ.

Trang chi tiết hiển thị dữ liệu mở rộng từ TMDB gồm tên gốc, tagline, chứng nhận
độ tuổi, trạng thái phát hành, kinh phí/doanh thu, biên kịch, nhà sản xuất, hãng
phim, nền tảng xem, từ khóa và liên kết IMDb/TMDB. Nếu TMDB không có metadata
trailer tiếng Việt, backend tự dùng trailer tiếng Anh làm phương án dự phòng.
Trailer phát ngay trong ứng dụng; khi bật `Cài đặt > Tự động phát Trailer`, video
tự chạy ở chế độ tắt tiếng để Chrome không chặn autoplay. Người dùng có thể bật
âm thanh trong trình phát hoặc mở video trên YouTube.

Ảnh đại diện từ Google/Facebook được đồng bộ vào hồ sơ sau lần đăng nhập đầu
tiên. Người dùng có thể bấm nút bút chì ở avatar hoặc nút ảnh bìa để chọn ảnh,
crop/chỉnh khung, xem trước rồi mới xác nhận. Khi người dùng đã tự đổi avatar,
các lần OAuth sau sẽ không ghi đè ảnh đó.

## State và cache

- App khôi phục màn hình gần nhất sau khi reload, gồm cả phim/thể loại đang mở.
- Từ khóa tìm kiếm, bộ lọc, grid/list, vị trí cuộn, lựa chọn yêu thích và draft
  đánh giá được lưu cục bộ. Mật khẩu và dữ liệu OAuth tạm thời không được lưu.
- Dữ liệu phim công khai được cache 10 phút; chi tiết phim được cache 30 phút.
  Nếu cache hết hạn mà mạng lỗi, app dùng bản cache gần nhất.
- Mục `Cài đặt > Xóa bộ nhớ đệm` hiển thị dung lượng cache API thực tế và xóa
  cả cache API lẫn image cache đang giữ trong Flutter.
- Tùy chọn phát trailer, tải qua Wi-Fi, chất lượng video, thông báo, giao diện
  Cinematic Noir và đánh giá ứng dụng đều được lưu sau khi reload.

## Backend

Backend NestJS nằm trong thư mục `backend/`, sử dụng Prisma và PostgreSQL trên
Supabase. Xem `backend/README.md` để cấu hình database, TMDB và chạy API.

## Cấu trúc Project

```
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

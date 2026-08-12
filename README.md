# FLIX – Ứng dụng Tra cứu Phim

Ứng dụng Flutter đa nền tảng để khám phá và quản lý phim, sử dụng TMDB cho dữ
liệu công khai, NestJS/Prisma/PostgreSQL cho tài khoản và dữ liệu người dùng.
Frontend Web được phát hành bằng Firebase Hosting, backend chạy trên Render.

- Frontend production: <https://flix-da-movie-m-app.web.app>
- Backend production: <https://lap-trinh-thiet-bi-di-dong.onrender.com>
- Health check: <https://lap-trinh-thiet-bi-di-dong.onrender.com/api/v1/health>

## Yêu cầu

- Flutter 3.44.6 (stable)
- Dart 3.12.2
- Node.js 22
- PostgreSQL (project hiện dùng Supabase)

## Cài đặt lần đầu

Từ thư mục gốc của project, cài dependencies cho Flutter và backend:

```powershell
flutter pub get
cd backend
npm ci
Copy-Item .env.example .env
npm run db:generate
npm run db:deploy
cd ..
```

Sau khi tạo `backend/.env`, điền đúng `DATABASE_URL`, `JWT_SECRET`,
`TMDB_API_KEY` và các biến OAuth/Brevo cần sử dụng trước khi chạy backend.
Không commit file `.env`.

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

## Khôi phục mật khẩu qua Brevo

Backend gửi mã khôi phục sáu chữ số qua Brevo Transactional Email API bằng
HTTPS, không sử dụng SMTP. Trong `backend/.env`, cấu hình:

```env
BREVO_API_KEY="..."
BREVO_SENDER_EMAIL="email-da-xac-minh@example.com"
BREVO_SENDER_NAME="FLIX"
```

`BREVO_SENDER_EMAIL` phải ở trạng thái active trong Brevo. Khi chạy trên
Render, thêm ba biến trên vào Environment của backend service. Nếu bật giới
hạn Authorized IPs cho API key, cần bảo đảm outbound IP của Render được cho
phép; Render Free không đảm bảo một outbound IP cố định.

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
Supabase. Backend cung cấp authentication, OAuth, khôi phục mật khẩu, TMDB
proxy/cache, yêu thích, lịch sử xem, đánh giá và hồ sơ người dùng. Xem
`backend/README.md` để biết chi tiết cấu hình và API.

## Kiểm tra chất lượng

Flutter:

```powershell
flutter analyze
flutter test
flutter build web --release --dart-define=FLIX_API_URL=https://lap-trinh-thiet-bi-di-dong.onrender.com/api/v1
```

Backend:

```powershell
cd backend
npm run db:validate
npm run db:generate
npx eslint "{src,test}/**/*.ts"
npx jest --runInBand
npm run build
```

## CI/CD và triển khai

Workflow `.github/workflows/ci-cd.yml` chạy phân tích, kiểm thử và build cho
Flutter lẫn backend trên pull request và các branch chính.

- Push branch phát triển: chỉ chạy CI.
- Push hoặc merge vào `main`: CI xanh rồi deploy backend Render, kiểm tra health
  và cuối cùng deploy artifact Web lên Firebase Hosting.
- Có thể chạy thủ công bằng `workflow_dispatch` và bật tùy chọn `deploy`.

Chi tiết GitHub Environment, secrets, cấu hình Render và rollback nằm tại
[`docs/CI_CD.md`](docs/CI_CD.md).

## Cấu trúc Project

```text
.
├── .github/
│   └── workflows/ci-cd.yml       # CI Flutter/backend và CD Render/Firebase
├── backend/
│   ├── prisma/
│   │   ├── migrations/           # Lịch sử migration PostgreSQL
│   │   └── schema.prisma         # User, OAuth, phim, lịch sử và đánh giá
│   ├── src/
│   │   ├── auth/                 # JWT, OAuth, đổi/quên mật khẩu và Brevo
│   │   ├── common/               # Response, lỗi và runtime configuration
│   │   ├── health/               # Health check backend/database
│   │   ├── prisma/               # Prisma service
│   │   ├── tmdb/                 # TMDB proxy, cache và metadata phim
│   │   └── user-data/            # Hồ sơ, yêu thích, lịch sử và đánh giá
│   ├── test/                      # NestJS end-to-end tests
│   ├── .env.example              # Danh sách biến môi trường mẫu
│   └── package.json
├── docs/
│   └── CI_CD.md                  # Secrets, phát hành và rollback
├── lib/
│   ├── core/                     # API client, session, preferences, UI state
│   ├── data/                     # TMDB/user repositories và fallback data
│   ├── models/                   # Movie và bộ lọc
│   ├── routes/                   # Route declarations
│   ├── screens/                  # Các màn hình Flutter hiện tại
│   ├── theme/                    # Theme, màu sắc và style dùng chung
│   ├── widgets/                  # Movie card, navigation, media và review
│   └── main.dart                 # Entry point
├── test/                         # Widget, navigation, state và API tests
├── web/                          # Bootstrap, manifest, favicon và PWA icons
├── .firebaserc                   # Firebase project flix-da-movie-m-app
├── firebase.json                 # Hosting build/web và SPA rewrite
├── pubspec.yaml                  # Flutter dependencies
└── README.md
```

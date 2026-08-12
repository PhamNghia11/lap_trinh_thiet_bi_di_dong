# CI/CD của FLIX

Workflow chính nằm tại `.github/workflows/ci-cd.yml`.

## Khi nào workflow chạy

- Pull request: chạy CI, không deploy.
- Push lên `X.Bach-Full-Frontend-and-Backend-v1.1`: chạy CI để kiểm tra branch phát triển.
- Push lên `main`: chạy CI, sau đó deploy Firebase Hosting và Render nếu toàn bộ kiểm tra thành công.
- Chạy thủ công trong GitHub Actions: bật `deploy` để deploy commit đang chọn sau khi CI thành công.

## Các kiểm tra CI

Flutter:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build web --release`

Backend:

- `npm ci`
- `npm run db:validate`
- `npm run db:generate`
- ESLint
- `npx jest --runInBand`
- `npm run build`

CI dùng một `DATABASE_URL` giả chỉ để Prisma kiểm tra schema và sinh client; workflow không kết nối hay thay đổi database production.

Web build đã kiểm tra được lưu thành artifact trong 7 ngày và chính artifact đó được deploy; job deploy không build lại source.

## GitHub Environment và secrets

Tạo environment tên `production` trong `Settings > Environments`. Có thể bật Required reviewers để mỗi lần deploy production cần xác nhận.

Thêm các repository/environment secrets:

| Secret | Nội dung |
| --- | --- |
| `FIREBASE_SERVICE_ACCOUNT_FLIX` | JSON service account của Firebase project `flix-da-movie-m-app` |
| `RENDER_API_KEY` | API key lấy từ Render Account Settings |
| `RENDER_SERVICE_ID` | ID service backend Render, dạng `srv-...` |

Không commit các giá trị secret vào repository.

### Tạo Firebase service account

Trong Firebase Console mở `Project settings > Service accounts > Generate new private key`, tải JSON rồi chép toàn bộ nội dung JSON vào secret `FIREBASE_SERVICE_ACCOUNT_FLIX`.

### Lấy Render API key và service ID

- API key: `Render Dashboard > Account Settings > API Keys`.
- Service ID: mở backend service; ID `srv-...` xuất hiện trong URL Dashboard hoặc phần Settings.

## Cấu hình Render một lần

Giữ service Render hiện tại và tắt `Auto-Deploy` để tránh Render deploy một lần khi push rồi GitHub Actions deploy thêm lần nữa.

Thiết lập:

```text
Root Directory: backend
Build Command: npm ci && npx prisma generate && npx prisma migrate deploy && npm run build
Start Command: npm run start:prod
Health Check Path: /api/v1/health
```

Các biến môi trường runtime (`DATABASE_URL`, `JWT_SECRET`, `TMDB_API_KEY`, OAuth, Resend...) tiếp tục được quản lý trong Render Dashboard.

## Quy trình phát hành

1. Push branch phát triển và chờ CI xanh.
2. Merge vào `main`.
3. CI chạy lại trên commit merge.
4. GitHub Actions yêu cầu Render deploy đúng commit đang chạy CI, đợi deploy `live`, rồi kiểm tra `/api/v1/health`.
5. Chỉ sau khi backend khỏe, Firebase mới nhận đúng artifact web đã qua test.

Nếu deploy thất bại, mở job tương ứng trong GitHub Actions. Source cũ trên Firebase/Render vẫn có thể rollback từ lịch sử release/deploy của từng nền tảng.

## Rollback

- Firebase: mở `Firebase Console > Hosting > Release history`, chọn bản trước và rollback.
- Render: mở `Deploys`, chọn deploy ổn định trước đó và dùng `Redeploy`.

# FLIX production runbook

## Cấu hình bắt buộc

Render phải có `NODE_ENV=production`, `DATABASE_URL`, `JWT_SECRET` tối thiểu 32 ký
tự, `TMDB_API_KEY` và `WEB_ORIGIN`. Giữ `ENABLE_SWAGGER=false`.

Observability là tùy chọn nhưng nên bật:

- Render: `SENTRY_DSN`, `SENTRY_ENVIRONMENT=production`,
  `SENTRY_TRACES_SAMPLE_RATE=0.1`.
- GitHub Actions secret: `FLIX_SENTRY_DSN` cho Flutter Web.
- Có thể giảm sample rate về `0` nếu chỉ cần error monitoring.

Không đưa `DATABASE_URL`, service-role key, OAuth secret hoặc Sentry auth token vào
Flutter. Sentry DSN phía client là định danh public, nhưng vẫn lưu trong GitHub
secret để quản lý cấu hình release tập trung.

## Theo dõi

- Readiness: `/api/v1/health/ready` kiểm tra database và trả `503` khi chưa sẵn sàng.
- Liveness: `/api/v1/health/live` chỉ xác nhận process còn chạy.
- Workflow `Production uptime` gọi backend và Firebase mỗi 15 phút. Khi lỗi, nó mở
  một issue mang label `production-incident`; khi hệ thống hồi phục, issue tự đóng.
- GitHub chỉ chạy workflow `schedule` từ default branch, vì vậy phải merge các
  workflow production vào `main` hoặc đặt `v1.2` làm default branch.
- Tìm request lỗi bằng header hoặc response field `requestId`, sau đó tra JSON log
  trên Render và event tương ứng trên Sentry.

## Xử lý sự cố

1. Xác định backend, database hay Firebase đang lỗi từ uptime run và health body.
2. Tra `requestId`, commit release và timestamp trong Render/Sentry.
3. Nếu lỗi do release mới, rollback Render và Firebase về bản ổn định gần nhất.
4. Nếu lỗi database, ngừng deploy mới, kiểm tra Supabase status, connection pool và
   migration gần nhất trước khi can thiệp dữ liệu.
5. Sau khi hồi phục, xác nhận readiness, trang Web, đăng nhập và refresh session.

## Backup và phục hồi

- Bật backup/PITR trong Supabase phù hợp với gói đang dùng và kiểm tra trạng thái
  backup định kỳ trong dashboard.
- Trước migration phá hủy dữ liệu, tạo backup thủ công và ghi lại restore point.
- Không upload database dump chưa mã hóa vào GitHub artifact.
- Mỗi quý thực hiện một lần restore rehearsal trên project/database tách biệt.

## Xoay secret

- Xoay ngay khi nghi ngờ lộ: `JWT_SECRET`, Supabase service-role key, OAuth client
  secrets, Brevo key, Render API key và Firebase service account.
- Xoay `JWT_SECRET` sẽ làm toàn bộ access token hiện tại mất hiệu lực; thu hồi hoặc
  xóa refresh sessions nếu cần buộc đăng nhập lại toàn bộ thiết bị.
- Sau khi xoay, deploy lại, kiểm tra health và đóng incident chỉ khi smoke check đạt.

## Bảo trì

- Dependabot tạo PR cập nhật npm, pub và GitHub Actions hàng tuần.
- CodeQL quét backend TypeScript khi push/PR và mỗi tuần.
- Refresh session hết hạn được backend dọn khi khởi động và theo chu kỳ 24 giờ.
- Xem lại dependency audit, Sentry issue, uptime incident và backup mỗi tuần.
